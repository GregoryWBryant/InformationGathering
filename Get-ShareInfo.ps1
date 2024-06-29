<#
    Script: Shared Folder Inventory in Active Directory

    Purpose
        Gathers information about shared folders on all enabled servers in Active Directory.
        Creates a folder on your desktop named "Information Gathered."
        Iterates through each server, querying for shared folder details.
        Excludes built-in shares and printer shares.
        Creates a CSV file named "Shares.csv" in the "Information Gathered" folder containing the collected data.

    Requirements
        Active Directory PowerShell module (included by default on domain-joined computers).
        Permissions to query shared folder information on remote servers.

    Notes
        Before running, ensure you are connected to the network where the servers reside.
        The script skips unreachable servers and outputs a message indicating the server is offline.
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
$SharesData = @() 

# Iterate through each server
foreach ($Server in $Servers) {

    # Test if the server is reachable
    if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {  # Using -Quiet for cleaner output
        Write-Output "Checking Server: $Server.Name" # Informational message

        # Create a CIM session to the remote server
        $Cim = New-CimSession -ComputerName $Server.Name 

        # Get shared folders, excluding built-in and printer shares
        $Shares = Get-SmbShare -CimSession $Cim | Where-Object {
            $_.ShareType -eq "Disk" -and 
            $_.Name -notmatch "^(ADMIN\$|C\$|IPC\$|PRINT\$|NETLOGON|SYSVOL)" # Exclude common system shares
        }
        
        # Close the CIM session
        Remove-CimSession -CimSession $Cim

        # Iterate through each shared folder
        foreach ($Share in $Shares) {
            # Create a custom object for the share data
            $NewShare = [PSCustomObject]@{
                Server = $Server.Name
                Share = $Share.Name
                Path = $Share.Path
                Description = $Share.Description
            }
            # Add the share data to the array
            $SharesData += $NewShare 
        }
    } else {
        Write-Output "$($Server.Name) is not online"  # Output message for offline servers
    }
}

# Export the collected share data to a CSV file
$SharesData | Export-Csv -Path ($SavePath + "Shares.csv") -NoTypeInformation
