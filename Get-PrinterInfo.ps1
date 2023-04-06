<#
Script is useful for gathering information on Shared pRinters across all servers in Active Directory
Creates a Folder on your desktop
Queries Active Directory for all Servers
Queries each server and creates a cleaned up export of all shared rpinters from each server and exports to the new folder.
#>

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

$Servers = Get-ADComputer -Filter {enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *
$AllPrinters = @()

foreach ($Server in $Servers) {

    #Test to see if server is reachable
    if (Test-Connection -ComputerName $Server.Name -ErrorAction SilentlyContinue) {

        $Name = $Server.Name
        Write-Output "Checking Server: $Name"
        $Printers = Get-Printer -ComputerName $Name
        foreach ($Printer in $Printers) {

            $Driver = Get-PrinterDriver -Name $Printer.DriverName -ComputerName $Name
            $NewPrinter = [PSCustomObject]@{
                "Server Name" = $Name
                "Printer Name" = $Printer[0].Name
                "Driver Name" = $Printer[0].DriverName
                "Driver Type" = $Driver[0].MajorVersion
                "IP Port" = $Printer[0].PortName
                "Status" = $Printer[0].PrinterStatus
    
            }
      
        $AllPrinters += $NewPrinter
        }
    }
}

$AllPrinters | Export-Csv -Path ($SavePath + "Printers.csv") -NoTypeInformation