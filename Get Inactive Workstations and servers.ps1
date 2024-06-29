<#
    Script: Active Directory Inactive Server and Workstation Report

    Purpose
        Gathers information about Inactive servers and workstations in the last 60 days.
        Creates a folder on your desktop to store the results.
        Exports the information to separate CSV files.

    Requirements:
        Active Directory PowerShell module (Import-Module ActiveDirectory)
        Sufficient permissions to query Active Directory computer objects

    Notes
        Adjust the `$time` variable to modify the time frame for inactive computers.
        Customize the `Select` statement to include other relevant properties if needed.
#>

# Get the path to the user's desktop
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment.SpecialFolder]::Desktop)

# Create the save path for the CSV files
$SavePath = $DesktopPath + "\Information Gathered\"

# Check if the folder exists, create it if not
if(!(Test-Path -Path $SavePath)) {
    New-Item -Path $SavePath -ItemType Directory -Force
}

# Import the Active Directory PowerShell module
Import-Module ActiveDirectory

# Calculate the date 60 days ago from the current date
$time = (Get-Date).AddDays(-60)

# Get inactive servers (LastLogonDate older than the specified time and running a Windows Server OS)
Get-ADComputer -Filter {LastLogonDate -lt $time -and OperatingSystem -like '*Windows Server*'} -Properties * |
    Select-Object Name,LastLogonDate,OperatingSystem | 
    Export-Csv ($SavePath + "InactiveServers.csv") -NoTypeInformation

# Get inactive workstations (LastLogonDate older than the specified time and not running a Windows Server OS)
Get-ADComputer -Filter {LastLogonDate -lt $time -and OperatingSystem -notlike '*Windows Server*'} -Properties * |
    Select-Object Name,LastLogonDate,OperatingSystem | 
    Export-Csv ($SavePath + "InactiveWorkstations.csv") -NoTypeInformation
