<#
Before running this script you need to setup a Shared Folder that Authenticated users can wrote to.
You need to run this script on the Computers with either System or a Local Admin
This will query the Registry to get all Mapped drives for all users.
#>
$Drives = Get-ItemProperty "Registry::HKEY_USERS\*\Network\*"
$AllMappedDrives = @()

foreach ($Drive in $Drives) {

    $Path = $Drive.PSParentPath
    $Path = $Path.Substring(($Path.IndexOf("\") +1), ($Path.lastIndexOf("\") - $Path.IndexOf("\")))
    $Username = (Get-ItemProperty -Path ($Path + "Volatile Environment") -Name "USERNAME").USERNAME
    $MappedDrive = [PSCustomObject] @{
        "Computer Name" = $env:COMPUTERNAME
        "Drive Letter" = $Drive.PSChildName
        "Drive Location" = $Drive.RemotePath
        "User Name" = $Username
    }
    $AllMappedDrives += $MappedDrive

}

$AllMappedDrives | Export-Csv -Path ("\\ShareServer\MappedDrives\AllMappedDrives.csv") -NoTypeInformation -Append
