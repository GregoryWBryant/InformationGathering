function Get-RolesInstalled {
    <#
        .SYNOPSIS
            Retrieves the installed Windows Server roles on all enabled servers in Active Directory.

        .DESCRIPTION
            This script queries all enabled servers in Active Directory that are running a version of Windows Server.
            It checks if each server is reachable, then retrieves and records the installed roles on each server.
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER None
            This function does not take any parameters.

        .EXAMPLE
            Get-RolesInstalled
            Runs the function and exports the installed roles on all reachable servers to a CSV file.

        .NOTES
            This function assumes the script is running on a Windows environment where PowerShell can access the desktop path using .NET Framework.
    #>

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the folder to store the results
    $SavePath = $DesktopPath + "\Information Gathered\"
    if (!(Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
    }

    # Get all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *
    $RolesData = @()

    # Iterate through each server
    foreach ($Server in $Servers) {
        # Test if the server is reachable
        if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {
            Write-Output ("Checking Server: " + $Server.Name) # Informational message
            $Roles = Get-WindowsFeature -ComputerName $Server.Name | Where-Object { $_.installstate -eq "installed" -and $_.FeatureType -eq "Role" }
            foreach ($Role in $Roles) {
                $NewRole = [PSCustomObject]@{
                    Server = $Server.Name
                    Name = $Role.DisplayName
                }
                $RolesData += $NewRole
            }
        } else {
            Write-Output ("Can't reach: " + $Server.Name)  # Output message for offline servers
        }
    }

    # Export the collected role data to a CSV file
    $RolesData | Export-Csv -Path ($SavePath + "Roles.csv") -NoTypeInformation
}
