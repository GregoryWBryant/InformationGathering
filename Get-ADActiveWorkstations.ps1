function Get-ADActiveWorkstations {
    <#
        .SYNOPSIS
        Retrieves a list of active workstations from Active Directory.

        .DESCRIPTION
        This script identifies active workstations in Active Directory that have been logged into within the last specified number of days. 
        The workstations must be enabled and not be Windows Server machines. 
        The results are saved to a CSV file on the user's desktop.

        .PARAMETER Days
        The number of days to look back from the current date for the last logon time. 
        Default is 60 days.

        .EXAMPLE
            Get-ADActiveWorkstations -Days 90
        Retrieves a list of active workstations that have been logged into within the last 90 days 
        and saves the information to a CSV file on the desktop.

        .NOTES
        The script requires the Active Directory module.
    #>
    param (
        [int]$Days = 60
    )

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

    # Calculate the date for the specified number of days ago
    $time = (Get-Date).AddDays(-$Days)

    # Get active workstations (LastLogonDate within the specified number of days, enabled, and not servers)
    Get-ADComputer -Filter {LastLogonDate -gt $time -and Enabled -eq $true -and OperatingSystem -notlike '*Windows Server*'} -Properties * |
        Select Name,LastLogonDate,OperatingSystem |
        Export-Csv ($SavePath + "ActiveWorkstations.csv") -NoTypeInformation
}
