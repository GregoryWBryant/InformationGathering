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
