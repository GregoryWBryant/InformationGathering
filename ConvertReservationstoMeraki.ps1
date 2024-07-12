function Validate-MacAddress {
    <#
        .SYNOPSIS
            Validates whether a given string is a properly formatted MAC address.

        .DESCRIPTION
            The Validate-MacAddress function checks if the input string matches the
            standard MAC address format. MAC addresses typically consist of six
            pairs of hexadecimal digits separated by colons or hyphens.

        .PARAMETER macAddress
            The string representing the MAC address to be validated.

        .EXAMPLE
            Validate-MacAddress -macAddress "00:1A:2B:3C:4D:5E"
            True

            Validate-MacAddress -macAddress "00-1A-2B-3C-4D-5E"
            True

            Validate-MacAddress -macAddress "001A2B3C4D5E"
            False
    #>

    param (
        [string]$macAddress
    )
    # Define the regex pattern for a MAC address
    $macPattern = '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'
    if ($macAddress -match $macPattern) {
        return $true
    } else {
        return $false
    }
}

function Convert-WindowsDHCPToMerakiDHCP {
    <#
        .SYNOPSIS
            Converts Windows DHCP reservation files to Meraki-compatible DHCP configuration files.

        .DESCRIPTION
            The Convert-WindowsDHCPToMerakiDHCP function reads CSV files containing DHCP reservation
            data, validates MAC addresses, and separates the entries into fixed IPs and reserved IPs.
            The function then exports the processed data into separate CSV files for fixed and reserved IPs.

        .PARAMETER
            None. The function does not take any parameters and operates on files found in a predefined directory.

        .EXAMPLE
            Convert-WindowsDHCPToMerakiDHCP
            This command processes all DHCP reservation files in the specified directory, validates the
            MAC addresses, and exports the data into separate CSV files for fixed and reserved IPs.
    #>

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the save path for the CSV files
    $SavePath = $DesktopPath + "\Information Gathered\"

    # Get files with "Reservations" in the name from the specified directory
    $DHCPReservations = Get-ChildItem -Path ($SavePath + "DHCP\") -Filter "*Reservations*"

    # Process each file
    foreach ($DHCPReservation in $DHCPReservations) {
        try {
            # Import the CSV content of the current file
            $IPReservations = Import-Csv -Path $DHCPReservation.FullName

            # Initialize arrays to store fixed and reserved IPs
            $AllFixedIPs = @()
            $AllReservedIPs = @()

            # Define paths to save the output CSV files
            $FixedIPSavePath = $DHCPReservation.FullName -replace "Reservations", "FixedIPs"
            $ReservedIPSavePath = $DHCPReservation.FullName -replace "Reservations", "ReservedIPs"

            # Process each reservation in the imported CSV
            foreach ($IPReservation in $IPReservations) {
                # Validate the MAC address
                $Test = Validate-MacAddress -macAddress $IPReservation.ClientId
                if ($Test) {
                    # Create a custom object for fixed IPs if MAC address is valid
                    $FixedIP = [PSCustomObject] @{
                        ClientName = $IPReservation.Name
                        MacAddress = $IPReservation.ClientId
                        LanIP = $IPReservation.IPAddress
                    }
                    # Add to the fixed IPs array
                    $AllFixedIPs += $FixedIP
                } else {
                    # Create a custom object for reserved IPs if MAC address is invalid
                    $ReservedIP = [PSCustomObject] @{
                        FirstIP = $IPReservation.IPAddress
                        LastIP = $IPReservation.IPAddress
                        Comment = $IPReservation.Name
                    }
                    # Add to the reserved IPs array
                    $AllReservedIPs += $ReservedIP
                }
            }

            # Export the fixed IPs to a CSV file
            $AllFixedIPs | Export-Csv -Path $FixedIPSavePath -NoTypeInformation

            # Export the reserved IPs to a CSV file
            $AllReservedIPs | Export-Csv -Path $ReservedIPSavePath -NoTypeInformation
        } catch {
            Write-Error "Failed to process file: $($DHCPReservation.FullName). Error: $_"
        }
    }
}