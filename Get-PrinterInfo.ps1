function Get-Printers {
    <#
        .SYNOPSIS
            Retrieves printer information from enabled Windows Server machines in Active Directory and exports it to a CSV file.

        .DESCRIPTION
            This script retrieves printer details including server name, printer name, driver name, driver type, port name, port IP address, device URL, and status from Windows Server machines. It uses PowerShell cmdlets such as Get-Printer and Get-PrinterPort to gather this information.

        .PARAMETER All
            When specified, retrieves DHCP scope data from all enabled Searvers that are reachable. Otherwise, retrieves data from the local server.

        .EXAMPLE
            Get-Printers
            Retrieves printer information from the local server and saves it to CSV files.

            Get-Printers -All
            Retrieves printer information from all enabled Windows Server machines in Active Directory and saves it to a CSV file named "Printers.csv" in the Information Gathered folder on the desktop.

        .NOTES
            The script requires the Active Directory PowerShell module and administrator privileges to retrieve printer information from remote servers.
    #>

    param(
        [switch]$All
    )

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the folder to store the results
    $SavePath = $DesktopPath + "\Information Gathered\"
    if(!(Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
    }

    # Get the name of the computer you are running the script on
    $ComputerName = [System.Environment]::MachineName

    # Get a list of all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

    if (!($All)) {
        $Servers = $Servers | Where-Object {$_.Name -eq $ComputerName}
    }

    # Initialize an array to store printer information
    $AllPrinters = @()

    # Iterate through each server
    foreach ($Server in $Servers) {
        # Test if the server is reachable using Test-Connection
        if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {  # Using -Quiet for cleaner output
            $Name = $Server.Name
            Write-Output ("Checking Server:" + $Name)

            # Get all printers on the server
            $Printers = Get-Printer -ComputerName $Name

            # Iterate through each printer on the server
            foreach ($Printer in $Printers) {
                Write-Output ("Checking: " + $Printer.Name)
                # Get driver information for the printer
                $Driver = Get-PrinterDriver -Name $Printer.DriverName -ComputerName $Name
                $PortInformation = Get-PrinterPort -name $Printer[0].PortName -ComputerName $Name

                # Create a custom object to store printer details
                $NewPrinter = [PSCustomObject]@{
                    "Server Name" = $Name
                    "Printer Name" = $Printer[0].Name
                    "Driver Name" = $Printer[0].DriverName
                    "Driver Type" = $Driver[0].MajorVersion
                    "Port Name" = $Printer[0].PortName
                    "Port IP" = $PortInformation.printerhostaddress
                    "Device URL" = $PortInformation.DeviceURL
                    "Status" = $Printer[0].PrinterStatus
                    }
                # Add the printer object to the overall list
                $AllPrinters += $NewPrinter
                }
            } else {
                Write-Output ("Can't Reach: " + $Server.Name)
                }
        }
    # Export all printer information to a CSV file in the designated folder
    $AllPrinters | Export-Csv -Path ($SavePath + "Printers.csv") -NoTypeInformation
}
