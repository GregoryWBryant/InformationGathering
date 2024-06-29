<#
    Script: Shared Printer Inventory in Active Directory

    Purpose
        Collects information about shared printers on all active servers in Active Directory.
        Creates a folder on the desktop named "Information Gathered."
        Iterates through each server, querying for shared printer details.
        Creates a CSV file in the "Information Gathered" folder containing printer information from all reachable servers.

    Requirements
        Active Directory PowerShell module (imported by default on domain-joined computers).
        Permissions to query printer information on remote servers.

    Notes
        Before running, ensure you are connected to the network where the servers reside.
        The script skips unreachable servers and outputs a "Can't Ping" message.
#>

# Get the path to the user's desktop
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment.SpecialFolder]::Desktop)

# Create the folder to store the results
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {
    New-Item -Path $SavePath -ItemType Directory -Force
}

# Get all enabled servers in Active Directory
$Servers = Get-ADComputer -Filter {enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

# Initialize an array to store printer information
$AllPrinters = @()

# Iterate through each server
foreach ($Server in $Servers) {

    # Test if the server is reachable using Test-Connection
    if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {  # Using -Quiet for cleaner output
        $Name = $Server.Name
        Write-Output "Checking Server: $Name"

        # Get all printers on the server
        $Printers = Get-Printer -ComputerName $Name

        # Iterate through each printer on the server
        foreach ($Printer in $Printers) {

            # Get driver information for the printer
            $Driver = Get-PrinterDriver -Name $Printer.DriverName -ComputerName $Name

            # Create a custom object to store printer details
            $NewPrinter = [PSCustomObject]@{
                "Server Name" = $Name
                "Printer Name" = $Printer[0].Name
                "Driver Name" = $Printer[0].DriverName
                "Driver Type" = $Driver[0].MajorVersion
                "IP Port" = $Printer[0].PortName
                "Device URL" = (Get-PrinterPort -name $Printer[0].PortName -computername $Name).DeviceURL # This property provides the IP of WSD ports.
                "Status" = $Printer[0].PrinterStatus
            }

            # Add the printer object to the overall list
            $AllPrinters += $NewPrinter
        }
    } else {
        Write-Output "Can't Ping: $Server.Name"
    }
}

# Export all printer information to a CSV file in the designated folder
$AllPrinters | Export-Csv -Path ($SavePath + "Printers.csv") -NoTypeInformation
