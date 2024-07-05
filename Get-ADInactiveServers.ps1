function Get-ADInactiveServers {
    <#
        .SYNOPSIS
            Retrieves a list of inactive servers from Active Directory.

        .DESCRIPTION
            This script identifies inactive servers in Active Directory that have not been logged into within the last specified number of days. 
            The servers must be not be Windows workstation machines. 
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER Days
            The number of days to look back from the current date for the last logon time. 
            Default is 60 days.

        .EXAMPLE
            Get-ADInactiveServers -Days 90
            Retrieves a list of inactive servers that have not been logged into within the last 90 days 
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

    # Get inactive servers (LastLogonDate older than the specified time and running a Windows Server OS)
    Get-ADComputer -Filter {LastLogonDate -lt $time -and OperatingSystem -like '*Windows Server*'} -Properties * |
        Select-Object Name,LastLogonDate,OperatingSystem | 
        Export-Csv ($SavePath + "InactiveServers.csv") -NoTypeInformation
}
