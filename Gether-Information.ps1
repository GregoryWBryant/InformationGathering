<#
Script is useed for gathering information (Combination of the other scripts lsited)
Script should be ran on a Domain Controller that can contact all servers
Will save to a folder called "Information Gathered" on your desktop
This will gather the following information
Active and Inactive Servers and Workstations
    This is defined by devices that have not contacted Active Directory in the last 60 days are considered Inactive
Information about Active Users
    Users that are enabled
DHCP Scopes on Active Servers
Shared Printers on Active Servers
Shared Folders on Active Servers
Applications installed on Active servers
#>
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
$ApplicationPath = ($SavePath + "\Applications Installed on Servers\")
$DHCPPath = ($SavePath + "\DHCP\")
$AllPrinters = @()
$SharesData = @()
$NewShares = @()
$NewUsers = @()

if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

if(!(Test-Path -Path $DHCPPath)) {

    New-Item -Path $DHCPPath -ItemType Directory -Force

}

if(!(Test-Path -Path $ApplicationPath)) {

    New-Item -Path $ApplicationPath -ItemType Directory -Force

}

#Get Inactive servers and workstations
Import-Module ActiveDirectory
$time = (Get-Date).Adddays(-(60))
Get-ADComputer -Filter {LastLogon -lt $time -and OperatingSystem -like '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem | Export-Csv ($SavePath + "InactiveServers.csv") -NoTypeInformation
Get-ADComputer -Filter {LastLogon -lt $time -and OperatingSystem -notlike '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem | Export-Csv ($SavePath + "InactiveWorkstations.csv") -NoTypeInformation

#Get Active servers and workstations
Get-ADComputer -Filter {LastLogon -gt $time -and enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem | Export-Csv ($SavePath + "ActiveServers.csv") -NoTypeInformation
Get-ADComputer -Filter {LastLogon -gt $time -and enabled -eq $true -and OperatingSystem -notlike '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem | Export-Csv ($SavePath + "ActiveWorkstations.csv") -NoTypeInformation
$Servers = Get-ADComputer -Filter {LastLogon -gt $Time -and enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties * | Select Name,Lastlogondate,OperatingSystem

#Get Active AD Users information
$Users = Get-ADUser -Filter * -Properties * | Where { $_.Enabled -eq $True}
foreach ($User in $Users) {
    $ProxyAddresses = $User.proxyAddresses -join ", "
    $Groups = $User.MemberOf -join ", "
    $NewUser = [PSCustomObject]@{
        FirstName = $User.GivenName
        LastName = $User.Surname
        Name = $User.DisplayName
        UPN = $User.UserPrincipalName
        SamAccount = $User.SamAccountName
        Title = $User.Title
        LastLogonDate = $User.LastLogonDate
        LastLogonTimeStamp = [DateTime]::FromFileTime($User.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')
        Email = $User.EmailAddress
        Proxy = $ProxyAddresses
        MemberOf = $Groups
        HomeDirectory = $User.HomeDirectory
        ProfilePath = $User.ProfilePath
        LogonScript = $User.ScriptPath
        OU = $User.CanonicalName
        PasswordNeverExpires = $User.PasswordNeverExpires

    }
    $NewUsers += $NewUser #>
}
$NewUsers | Export-Csv -Path ($SavePath + "Users.csv") -NoTypeInformation

#Get DHCP scope information
foreach ($Server in $Servers.Name) {
    try {
        Write-Output "Checking Server for DHCP: $Server"
        $Scopes = Get-DhcpServerv4Scope -ComputerName $Server
        foreach ($Scope in $Scopes) {

            Get-DhcpServerv4ExclusionRange -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($DHCPPath + "$Server" + "-" + $Scope.ScopeId + "-ExcusionRange.csv") -NoTypeInformation
            Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($DHCPPath + "$Server" + "-" + $Scope.ScopeId + "-Leases.csv") -NoTypeInformation
            Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($DHCPPath + "$Server" + "-" + $Scope.ScopeId + "-Reservations.csv") -NoTypeInformation
            Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId -ComputerName $Server | Select-Object OptionId,Name,Type,@{Name=’Value’;Expression={[string]::join(“;”, ($_.Value))}}  | Export-Csv -Path ($DHCPPath + "$Server" + "-" + $Scope.ScopeId + "-Options.csv") -NoTypeInformation
            Get-DhcpServerv4Scope -ScopeId $Scope.ScopeId -ComputerName $Server | Export-Csv -Path ($DHCPPath + "$Server" + "-" + $Scope.ScopeId + "-Scope.csv") -NoTypeInformation
            }
        } catch { Write-Output ("No scopes found on: " + $Server) }
    }

#Get Shared printer informaion
foreach ($Server in $Servers.Name) {
    #Test to see if server is reachable
    if (Test-Connection -ComputerName $Server -ErrorAction SilentlyContinue) {
        Write-Output "Checking Server for Printers: $Server"
        $Printers = Get-Printer -ComputerName $Server
        foreach ($Printer in $Printers) {

            $Driver = Get-PrinterDriver -Name $Printer.DriverName -ComputerName $Server
            $NewPrinter = [PSCustomObject]@{
                "Server Name" = $Server
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

#Gather Shared folders infomration
foreach ($Server in $Servers.Name) {
    #Test to see if Server is reachable
    if (Test-Connection -ComputerName $Server -ErrorAction SilentlyContinue) {
        Write-Output "Checking Server for Shares: $Server"
        $Cim = New-CimSession -ComputerName $Server
        #Excludes builtin Share types and Shared Printers
        $Shares = Get-SmbShare -CimSession $Cim | Where-Object {$_.ShareType -eq "FileSystemDirectory" -and $_.Description -ne "Remote Admin" -and $_.Description -ne "Default Share" `
                                                        -and $_.Description -ne "Printer Drivers" -and $_.Description -ne "Logon server share "}
        Remove-CimSession -CimSession $Cim
        foreach ($Share in $Shares) {
            $NewShare = [PSCustomObject]@{
                Server = $Server
                Share = $Share.Name
                Path = $Share.Path
                Description = $Share.Description
            }

            $NewShares += $NewShare
        }
        $SharesData += $NewShares
    } else {
        Write-Output ($Server + " is not online")
    }
}
$SharesData | Export-Csv -Append ($SavePath + "Shares.csv") -NoTypeInformation

#Get Installed applications on servers
$ComputerName = (Get-ComputerInfo).CSName

Foreach ($Server in $Servers.Name) {

    if ($Server -eq $ComputerName) {
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
       $AllApplications | Export-Csv -Path ($SavePath + $ComputerName + "-Applications.csv")  -NoTypeInformation
    
    } else {

        Invoke-Command -ComputerName $Server {
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
        Copy-Item -Path ("\\" + $Server + "\C$\Temp\" + $Server + "-Applications.csv") -Destination ($ApplicationPath + $Server + "-Applications.csv")
        Remove-Item -Path ("\\" + $Server + "\C$\Temp\" + $Server + "-Applications.csv") 
    }
}
