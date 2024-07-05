function Get-InstalledApplications {
    <#
        .SYNOPSIS
            Retrieves installed applications from local or remote servers and exports the data to CSV files.

        .DESCRIPTION
            This script collects information about installed applications from servers within the Active Directory domain. It retrieves data from both 32-bit and 64-bit registry keys, creates custom objects for each application, and exports the information to CSV files stored in a directory on the user's desktop or copied from remote servers.

        .PARAMETER 
            No additional parameters.

        .EXAMPLE
            Get-InstalledApplications
            Retrieves installed applications from all enabled servers in Active Directory, including the local server, and saves the data to CSV files.

        .NOTES
            The script requires the Active Directory PowerShell module and administrator privileges on remote servers to retrieve registry information.
    #>

    # Get the path to your desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Creates a folder to store the results
    $SavePath = $DesktopPath + "\Information Gathered\"
    if (-not (Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
        }

    # Get the name of the computer you are running the script on
    $ComputerName = (Get-ComputerInfo).CSName

    # Get a list of all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

    # Iterate through each server in the list
    foreach ($Server in $Servers.Name) {

        # If the server is the same as the computer you are running the script on...
        if ($Server -eq $ComputerName) {
            $AllApplications = @() # Initialize an empty array to store application data
            $Reg32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"  # 32-bit registry key path
            $Reg64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"  # 64-bit registry key path
            # Get installed application information from both 32-bit and 64-bit registry keys
            $Applications = Get-ItemProperty -Path $Reg32, $Reg64 | Select-Object DisplayName, DisplayVersion, InstallDate
        
            # Create custom objects for each application and add to the array
            foreach ($Application in $Applications) {
                $NewApplication = [PSCustomObject]@{
                    Server = $Server
                    Name = $Application.DisplayName
                    Version = $Application.DisplayVersion
                    InstalledOn = $Application.InstallDate
                    }
                $AllApplications += $NewApplication 
                }

            # Export the application information to a CSV file in the Information Gathered folder
            $AllApplications | Export-Csv -Path ($SavePath + $ComputerName + "-Applications.csv") -NoTypeInformation
        } else {
            # If the server is not the same as the computer you are running the script on...

            # Use Invoke-Command to run the script remotely on the server
            Invoke-Command -ComputerName $Server {
                $ComputerName = (Get-ComputerInfo).CSName # Get the server name
                $AllApplications = @()
                $Reg32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                $Reg64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                $Applications = Get-ItemProperty -Path $Reg32,$Reg64 | Select-Object DisplayName, DisplayVersion, InstallDate

                foreach ($Application in $Applications) {
                    $NewApplication = [PSCustomObject]@{
                        Server = $ComputerName
                        Name = $Application.DisplayName
                        Version = $Application.DisplayVersion
                        InstalledOn = $Application.InstallDate
                        }
                    $AllApplications += $NewApplication
                    }
                # Export the application information to a CSV file in the C:\Temp folder on the server
                $AllApplications | Export-Csv -Path ("C:\Temp\" + $ComputerName + "-Applications.csv") -NoTypeInformation
                }
        
            # Copy the CSV file from the server to the Information Gathered folder on your computer
            Copy-Item -Path ("\\" + $Server + "\C$\Temp\" + $Server + "-Applications.csv") -Destination ($SavePath + $Server + "-Applications.csv")
            # Remove the temporary CSV file from the server
            Remove-Item -Path ("\\" + $Server + "\C$\Temp\" + $Server + "-Applications.csv") 
            }
        }
}
