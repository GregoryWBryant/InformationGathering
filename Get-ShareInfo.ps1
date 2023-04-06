<#
Script is useful for gathering information on all Shared folders for Servers in Active Directory
Creates a Folder on your desktop
Queries Active Directory for all enabled Servers
Creates a cleaned up export and exports to the new folder
#>

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

$Servers = Get-ADComputer -Filter {enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *
$SharesData = @()
$NewShares = @()

foreach ($Server in $Servers) {

    #Test to see if Server is reachable
    if (Test-Connection -ComputerName $Server.Name -ErrorAction SilentlyContinue) {
        $Cim = New-CimSession -ComputerName $Server.Name
        #Excludes builtin Share types and Shared Printers
        $Shares = Get-SmbShare -CimSession $Cim | Where-Object {$_.ShareType -eq "FileSystemDirectory" -and $_.Description -ne "Remote Admin" -and $_.Description -ne "Default Share" `
                                                        -and $_.Description -ne "Printer Drivers" -and $_.Description -ne "Logon server share "}
        Remove-CimSession -CimSession $Cim
        foreach ($Share in $Shares) {
        
            $NewShare = [PSCustomObject]@{
                Server = $Server.Name
                Share = $Share.Name
                Path = $Share.Path
                Description = $Share.Description
            }

            $NewShares += $NewShare
        
        }

        $SharesData += $NewShares
    } else {
    
        Write-Output ($Server.Name + " is not online")
    
    }

}

$SharesData | Export-Csv -Append ($SavePath + "Shares.csv") -NoTypeInformation