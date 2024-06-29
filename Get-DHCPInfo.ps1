<#
    Script: Get-DHCPScopeData

    Purpose:
        Gathers DHCP scope information (reservations, leases, exclusions, options) from either:
        All active servers in the domain (if -All switch is provided)
        The local server (if -All is not provided)

    Requirements:
        Requires the DHCPServer PowerShell module.
        To query all servers, it must be run from a domain-joined computer with access to Active Directory.
        To query the local server, it needs to be run on a DHCP server.

    Parameters:
        -All: Switch to indicate if all active servers should be queried.

    Creates:
        Creates a folder on your desktop to store the output CSV files.

    Notes
        Adjust the `$time` variable to modify the time frame for active servers.
        File naming conventions include the server name and scope ID for easy identification.
#>

function Get-DHCPScopeData {
    param(
        [switch]$All
    )

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment.SpecialFolder]::Desktop)

    # Create the save path for the CSV files
    $SavePath = $DesktopPath + "\Information Gathered\DHCP\"
    if (-not (Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
    }

    $Time = (Get-Date).AddDays(-(30)) # Modify to your desired timeframe

    if ($All) {
        # Get all active servers
        $Servers = Get-ADComputer -Filter {LastLogonDate -gt $Time -and Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

        foreach ($Server in $Servers) {
            try {
                $Scopes = Get-DhcpServerv4Scope -ComputerName $Server.Name
                foreach ($Scope in $Scopes) {
                    Write-Output "Processing Server: $($Server.Name), Scope: $($Scope.ScopeId)"

                    # Get and export DHCP data for each scope (with server name in file name)
                    Get-DhcpServerv4ExclusionRange -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($OutPutDirectory + "\" + "$Server" + "-" + $Scope.ScopeId + "-ExcusionRange.csv") -NoTypeInformation
                    Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($OutPutDirectory + "\" + "$Server" + "-" + $Scope.ScopeId + "-Leases.csv") -NoTypeInformation
                    Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($OutPutDirectory + "\" + "$Server" + "-" + $Scope.ScopeId + "-Reservations.csv") -NoTypeInformation
                    Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId -ComputerName $Server | Select-Object OptionId,Name,Type,@{Name=’Value’;Expression={[string]::join(“;”, ($_.Value))}}  | Export-Csv -Path ($OutPutDirectory + "\" + "$Server" + "-" + $Scope.ScopeId + "-Options.csv") -NoTypeInformation
                    Get-DhcpServerv4Scope -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($OutPutDirectory + "\" + "$Server" + "-" + $Scope.ScopeId + "-Scope.csv") -NoTypeInformation
                }
            } catch { Write-Warning "No scopes found on: $($Server.Name)" }
        }
    } else {
        # Get DHCP reservations for the local server
        $Scopes = Get-DhcpServerv4Scope

        foreach ($Scope in $Scopes) {
            Write-Output "Processing Scope: $($Scope.ScopeId)"

            # Get and export DHCP data for each scope (without server name in file name)
            Get-DhcpServerv4ExclusionRange -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + "\DHCP\" + $Scope.ScopeId + "-ExcusionRange.csv") -NoTypeInformation
            Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + "\DHCP\" + $Scope.ScopeId + "-Leases.csv") -NoTypeInformation
            Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + "\DHCP\" + $Scope.ScopeId + "-Reservations.csv") -NoTypeInformation
            Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId | Select-Object OptionId,Name,Type,@{Name=’Value’;Expression={[string]::join(“;”, ($_.Value))}}  | Export-Csv -Path ($SavePath + "\DHCP\" + $Scope.ScopeId + "-Options.csv") -NoTypeInformation
            Get-DhcpServerv4Scope -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + "\DHCP\" + $Scope.ScopeId + "-Scope.csv") -NoTypeInformation
        }
    }
}

# Call the function
Get-DHCPScopeData -All # Use -All to query all active servers, omit it to query local server only
