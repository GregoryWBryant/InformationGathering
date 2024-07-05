<#
    Script: Mapped Drive Report

    Purpose
        Gathers information about mapped drives on the local computer.
        Exports the information to a CSV file (AllMappedDrives.csv) on a network share.

    Requirements
        Must be run with System or Local Administrator privileges.
        A shared folder (\\RS6\MappedDrives in this example) must exist and be accessible to authenticated users with write permissions.

    Note
        This is meant to be used with a RMM tools to run this silently.
        This script only retrieves mapped drives for users whose registry hives are currently loaded (i.e., users who are logged in or whose profiles are actively loaded). Mapped drives for other users will not be detected.

    Usage
        Run this script on each computer where you want to collect mapped drive information.
        The results will be appended to the AllMappedDrives.csv file on the \\Server\MappedDrives share.
#>

# Get properties of all mapped drives from the registry
$Drives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*"

# Initialize an array to store mapped drive information
$AllMappedDrives = @()

# Iterate through each drive found in the registry
foreach ($Drive in $Drives) {

    # Extract the user's SID from the registry path
    $Path = $Drive.PSParentPath
    $Path = $Path.Substring(($Path.IndexOf("\") + 1), ($Path.LastIndexOf("\") - $Path.IndexOf("\")))

    # Attempt to get the username associated with the SID (only possible if the user's profile is loaded)
    $Username = (Get-ItemProperty -Path ($Path + "Volatile Environment") -Name "USERNAME").USERNAME

    # Create a custom object to store information about the mapped drive
    $MappedDrive = [PSCustomObject] @{
        "Computer Name" = $env:COMPUTERNAME
        "Drive Letter" = $Drive.PSChildName
        "Drive Location" = $Drive.RemotePath
        "User Name" = $Username  # This might be empty if the user's profile isn't loaded
    }

    # Add the mapped drive object to the array
    $AllMappedDrives += $MappedDrive
}

# Export the mapped drive information to a CSV file on the network share
$AllMappedDrives | Export-Csv -Path "\\Server\MappedDrives\AllMappedDrives.csv" -NoTypeInformation -Append
