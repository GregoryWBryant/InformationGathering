function Get-ShareInfo {
    <#
        .SYNOPSIS
            Retrieves information about shared folders from enabled Windows Server machines in Active Directory and exports it to a CSV file.

        .DESCRIPTION
            This script connects to each enabled Windows Server in Active Directory, retrieves information about shared folders excluding built-in and printer shares, and exports the details (server name, share name, path, description) to a CSV file.

        .PARAMETER
            No additional parameters.

        .EXAMPLE
            Get-ShareInfo
            Retrieves shared folder information from all enabled Windows Server machines in Active Directory and saves it to a CSV file named "Shares.csv" in the Information Gathered folder on the desktop.

        .NOTES
            The script requires the Active Directory PowerShell module and administrator privileges to retrieve share information from remote servers.
    #>

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the folder to store the results
    $SavePath = $DesktopPath + "\Information Gathered\"
    if(!(Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
    }

    # Get all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *
    $SharesData = @() 

    # Iterate through each server
    foreach ($Server in $Servers) {
        # Test if the server is reachable
        if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {  # Using -Quiet for cleaner output
            Write-Output "Checking Server: $Server.Name" # Informational message
            # Create a CIM session to the remote server
            $Cim = New-CimSession -ComputerName $Server.Name 
            # Get shared folders, excluding built-in and printer shares
            $Shares = Get-SmbShare -CimSession $Cim | Where-Object {
                $_.ShareType -eq "Disk" -and 
                $_.Name -notmatch "^(ADMIN\$|C\$|IPC\$|PRINT\$|NETLOGON|SYSVOL)" # Exclude common system shares
                }
            # Close the CIM session
            Remove-CimSession -CimSession $Cim
            # Iterate through each shared folder
            foreach ($Share in $Shares) {
                # Create a custom object for the share data
                $NewShare = [PSCustomObject]@{
                    Server = $Server.Name
                    Share = $Share.Name
                    Path = $Share.Path
                    Description = $Share.Description
                    }
                # Add the share data to the array
                $SharesData += $NewShare 
                }
            } else {
                Write-Output "$($Server.Name) is not online"  # Output message for offline servers
                }
        }

    # Export the collected share data to a CSV file
    $SharesData | Export-Csv -Path ($SavePath + "Shares.csv") -NoTypeInformation
}
