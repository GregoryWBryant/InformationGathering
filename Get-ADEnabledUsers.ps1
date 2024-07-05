function Get-ADEnabledUsers {
    <#
        .SYNOPSIS
            Retrieves information about enabled users in Active Directory and exports it to a CSV file.

        .DESCRIPTION
            This script collects detailed information about all enabled users in Active Directory, including their 
            properties such as display name, user principal name, group memberships, manager information, and organizational unit.
         The collected information is saved to a CSV file on the user's desktop.

        .PARAMETER None
            The script does not require any parameters.

        .EXAMPLE
            Get-ADEnabledUsers
            Retrieves information about enabled users in Active Directory and saves it to a CSV file on the desktop.

        .NOTES
            The script requires the Active Directory PowerShell module.
    #>

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the folder to store the output
    $SavePath = $DesktopPath + "\Information Gathered\"
    if (-not (Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
    }

    # Initialize an empty array to store user objects
    $NewUsers = @()

    # Get all enabled users and their properties from Active Directory
    $Users = Get-ADUser -Filter * -Properties * | Where-Object { $_.Enabled -eq $true }

    # Iterate through each user
    foreach ($User in $Users) {
        # Join proxy addresses into a comma-separated string
        $ProxyAddresses = $User.ProxyAddresses -join ", "

        # Join group memberships into a comma-separated string
        $Groups = $User.MemberOf -join ", "

        # Determine if the user must change their password
        $MustChangePassword = if ($User.PasswordLastSet -eq 0) { "Yes" } else { "No" }

        # Get manager information if available
        if ($User.Manager) {
            $Manager = (Get-ADUser -Identity $User.Manager).Name
            $ManagerEmail = (Get-ADUser -Identity $User.Manager -Properties EmailAddress).EmailAddress
        } else {
            $Manager = "Blank"
            $ManagerEmail = "Blank"
        }

        # Create a custom object for the user with relevant properties
        $NewUser = [PSCustomObject]@{
            FirstName                  = $User.GivenName
            LastName                   = $User.Surname
            Name                       = $User.DisplayName
            UPN                        = $User.UserPrincipalName
            SamAccount                 = $User.SamAccountName
            Title                      = $User.Title
            LastLogonDate              = $User.LastLogonDate
            LastLogonTimeStamp         = [DateTime]::FromFileTime($User.LastLogonTimestamp).ToString('yyyy-MM-dd HH:mm:ss')
            LastPasswordChange         = $User.PasswordLastSet
            Email                      = $User.EmailAddress
            Proxy                      = $ProxyAddresses
            Manager                    = $Manager
            ManagerEmail               = $ManagerEmail
            MemberOf                   = $Groups
            HomeDirectory              = $User.HomeDirectory
            ProfilePath                = $User.ProfilePath
            LogonScript                = $User.ScriptPath
            OU                         = $user.CanonicalName.Substring(0, $user.CanonicalName.LastIndexOf('/'))
            Description                = $User.Description
            Office                     = $User.Office
            State                      = $User.State
            City                       = $User.City
            StreetAddress              = $User.streetaddress
            OfficePhone                = $User.OfficePhone
            UserMustChangePassword     = $MustChangePassword
            UserCannotChangePassword   = $User.CannotChangePassword
            PasswordNeverExpires       = $User.PasswordNeverExpires
        }

        # Add the new user object to the array
        $NewUsers += $NewUser
    }

    # Export the user data to a CSV file
    $NewUsers | Export-Csv -Path ($SavePath + "EnabledUsers.csv") -NoTypeInformation
}
