function Get-DHCPScopeData {
    <#
        .SYNOPSIS
            Retrieves DHCP scope data from specified DHCP servers and exports it to CSV files.

        .DESCRIPTION
            This script collects detailed DHCP scope information, including exclusion ranges, leases, reservations, option values, and scope details from specified DHCP servers. The data is exported to CSV files stored in a directory on the user's desktop.

        .PARAMETER All
            When specified, retrieves DHCP scope data from all active servers within the specified timeframe. Otherwise, retrieves data from the local server.

        .EXAMPLE
            Get-DHCPScopeData
            Retrieves DHCP scope data from the local server and saves it to CSV files.

            Get-DHCPScopeData -All
            Retrieves DHCP scope data from all active servers within the specified timeframe and saves it to CSV files.

        .NOTES
            The script requires the DHCP Server PowerShell module.
    #>

    param(
        [switch]$All
    )

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

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
                    Get-DhcpServerv4ExclusionRange -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($SavePath + "\" + "$Server" + "-" + $Scope.ScopeId + "-ExclusionRange.csv") -NoTypeInformation
                    Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($SavePath + "\" + "$Server" + "-" + $Scope.ScopeId + "-Leases.csv") -NoTypeInformation
                    Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($SavePath + "\" + "$Server" + "-" + $Scope.ScopeId + "-Reservations.csv") -NoTypeInformation
                    Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId -ComputerName $Server | Select-Object OptionId,Name,Type,@{Name='Value';Expression={[string]::join(";", ($_.Value))}} | Export-Csv -Path ($SavePath + "\" + "$Server" + "-" + $Scope.ScopeId + "-Options.csv") -NoTypeInformation
                    Get-DhcpServerv4Scope -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($SavePath + "\" + "$Server" + "-" + $Scope.ScopeId + "-Scope.csv") -NoTypeInformation
                }
            } catch { Write-Warning "No scopes found on: $($Server.Name)" }
        }
    } else {
        # Get DHCP reservations for the local server
        $Scopes = Get-DhcpServerv4Scope

        foreach ($Scope in $Scopes) {
            Write-Output "Processing Scope: $($Scope.ScopeId)"

            # Get and export DHCP data for each scope (without server name in file name)
            Get-DhcpServerv4ExclusionRange -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + $Scope.ScopeId + "-ExclusionRange.csv") -NoTypeInformation
            Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + $Scope.ScopeId + "-Leases.csv") -NoTypeInformation
            Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + $Scope.ScopeId + "-Reservations.csv") -NoTypeInformation
            Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId | Select-Object OptionId,Name,Type,@{Name='Value';Expression={[string]::join(";", ($_.Value))}} | Export-Csv -Path ($SavePath + $Scope.ScopeId + "-Options.csv") -NoTypeInformation
            Get-DhcpServerv4Scope -ScopeId $Scope.ScopeId | Export-Csv -Path ($SavePath + $Scope.ScopeId + "-Scope.csv") -NoTypeInformation
        }
    }
}
