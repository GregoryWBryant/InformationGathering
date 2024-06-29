<#
    Script: Active Directory Server and Workstation Activity Report

    Purpose
        Gathers information about active servers and workstations in the last 60 days.
        Creates a folder on your desktop to store the results.
        Exports the information to separate CSV files.

    Requirements:
        Active Directory PowerShell module (Import-Module ActiveDirectory)
        Sufficient permissions to query Active Directory computer objects

    Notes
        Adjust the `$time` variable to modify the time frame for active computers.
        Customize the `Select` statement to include other relevant properties if needed.
#>

# Get the path to the user's desktop
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

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

# Get active servers (LastLogonDate within the last 60 days and enabled)
Get-ADComputer -Filter {LastLogonDate -gt $time -and Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties * |
    Select Name,LastLogonDate,OperatingSystem | 
    Export-Csv ($SavePath + "ActiveServers.csv") -NoTypeInformation

# Get active workstations (LastLogonDate within the last 60 days, enabled, and not servers)
Get-ADComputer -Filter {LastLogonDate -gt $time -and Enabled -eq $true -and OperatingSystem -notlike '*Windows Server*'} -Properties * |
    Select Name,LastLogonDate,OperatingSystem | 
    Export-Csv ($SavePath + "ActiveWorkstations.csv") -NoTypeInformation
