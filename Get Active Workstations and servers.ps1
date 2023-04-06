<#
Script is useful for gathering how many Servers and Workstations are active in the last 60 days in Active Directory
Creates a Folder on your desktop
Queries Active Directory for all enabled Servers and Workstations
Creates a cleaned up export and exports to the new folder
#>

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

Import-Module ActiveDirectory

$time = (Get-Date).Adddays(-(60))

Get-ADComputer -Filter {LastLogon -gt $time -and enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem | Export-Csv ($SavePath + "Servers.csv") -NoTypeInformation

Get-ADComputer -Filter {LastLogon -gt $time -and enabled -eq $true -and OperatingSystem -notlike '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem | Export-Csv ($SavePath + "Workstations.csv") -NoTypeInformation
