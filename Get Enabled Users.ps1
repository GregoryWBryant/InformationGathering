<#
Script is useful for gathering how many users are in Active Directory
Creates a Folder on your desktop
Queries Active Directory for all enabled users
Creates a cleaned up export and exports to the new folder
#>

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

$NewUsers = @()
$Users = Get-ADUser -Filter * | Where { $_.Enabled -eq $True}

foreach ($User in $Users) {

    $Info = Get-ADUser -Identity $User.SamAccountName -Properties *
    $ProxyAddresses = $Info.proxyAddresses -join ", "
    $Groups = $Info.MemberOf -join ", "
    $NewUser = [PSCustomObject]@{
        FirstName = $Info.GivenName
        LastName = $Info.Surname
        Name = $Info.DisplayName
        UPN = $Info.UserPrincipalName
        SamAccount = $Info.SamAccountName
        Title = $Info.Title
        LastLogonDate = $Info.LastLogonDate
        LastLogonTimeStamp = [DateTime]::FromFileTime($Info.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')
        Email = $Info.EmailAddress
        Proxy = $ProxyAddresses
        MemberOf = $Groups
        HomeDirectory = $Info.HomeDirectory
        OU = $Info.CanonicalName
        PasswordNeverExpires = $info.PasswordNeverExpires

    }
    $NewUsers += $NewUser

}

$NewUsers | Export-Csv -Path ($SavePath + "Users.csv") -NoTypeInformation