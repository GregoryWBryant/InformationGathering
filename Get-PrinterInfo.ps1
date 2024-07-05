function Get-Printers {
    <#
        .SYNOPSIS
            Retrieves printer information from enabled Windows Server machines in Active Directory and exports it to a CSV file.

        .DESCRIPTION
            This script retrieves printer details including server name, printer name, driver name, driver type, port name, port IP address, device URL, and status from Windows Server machines. It uses PowerShell cmdlets such as Get-Printer and Get-PrinterPort to gather this information.

        .PARAMETER
            No additional parameters.

        .EXAMPLE
            Get-Printers
            Retrieves printer information from all enabled Windows Server machines in Active Directory and saves it to a CSV file named "Printers.csv" in the Information Gathered folder on the desktop.

        .NOTES
            The script requires the Active Directory PowerShell module and administrator privileges to retrieve printer information from remote servers.
    #>

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

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
                    "Port Name" = $Printer[0].PortName
                    "Port IP" = (Get-PrinterPort -name $Printer[0].PortName).printerhostaddress # This property provides the IP of the port
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
}
