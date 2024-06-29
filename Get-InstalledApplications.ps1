<#
    Script Name: Get-ServerApplicationInventory.ps1

    Description
        Gathers information about installed applications on servers in Active Directory.
        Creates a folder named "Information Gathered" on your desktop.
        For each server:
            Queries the registry (HKLM\Software\...) for installed applications.
            Creates a CSV file on the server itself (in C:\Temp).
            Copies the CSV file to the "Information Gathered" folder on your computer.
            Removes the temporary CSV file from the server.

    Requirements
        Active Directory module for PowerShell (already included by default).
        Sufficient permissions to query Active Directory and access the remote servers.

    Usage
        Run this script from a Server that is joined to the domain and can reach all other servers.

    Note
        Make sure the "C:\Temp" folder exists on each server, or modify the path as needed.
        This script assumes that the server's C$ share (administrative share) is accessible from your computer.
#>

# Get the path to your desktop
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment.SpecialFolder]::Desktop)

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
                Server = $Server.Name
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
