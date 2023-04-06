<#
Script is useful for gathering Applications installed on Servers in Active Directory
Creates a Folder on your desktop
Queries Registry on each server and creates CSV files on each
Copies the CSV to the Server you ran this from
#>

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

$ComputerName = (Get-ComputerInfo).CSName

$Servers = Get-ADComputer -Filter {enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

$Reg32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Reg64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

Foreach ($Server in $Servers) {

    if ($Server.Name -eq $ComputerName) {
    
        $AllApplications = @()
        $Reg32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $Reg64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        $Applications = Get-ItemProperty -Path $Reg32,$Reg64 | Select-Object DisplayName, DisplayVersion, InstallDate
        foreach ($Application in $Applications) {
            $NewApplication = [PSCustomObject]@{
                Server = $Server.Name
                Name = $Application.DisplayName
                Version = $Application.DisplayVersion
                InstalledOn = $Application.InstallDate
           }

            $AllApplications += $NewApplication

       }
       $AllApplications | Export-Csv -Path ($SavePath + $Server.Name + "-Applications.csv")  -NoTypeInformation
    
    } else {

        Invoke-Command -ComputerName $Server.Name {
            $ComputerName = (Get-ComputerInfo).CSName
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
            $AllApplications | Export-Csv -Path ("C:\Temp\" + $ComputerName + "-Applications.csv") -NoTypeInformation
        }
        Copy-Item -Path ("\\" + $Server.Name + "\C$\Temp\" + $Server.Name + "-Applications.csv") -Destination ($SavePath + $Server.Name + "-Applications.csv")
        #Uncomment if you wish to remove the file from the remote server
        #Remove-Item -Path ("\\" + $Server.Name + "\C$\Temp\" + $Server.Name + "-Applications.csv") 
    }
}