<#
    Script Name: Get-ADUsersDetailedReport.ps1

    Description:
        Gathers comprehensive information about enabled users in Active Directory (AD).
        Creates a folder named "Information Gathered" on your desktop.
        Exports the user data to a CSV file within the created folder.

    Requirements:
        Active Directory module for PowerShell (already included by default in most AD environments).

    Usage
        Run the script from a computer with access to your Active Directory domain.
        The CSV file "Users.csv" will be generated in the "Information Gathered" folder on your desktop.

    Customization
        Modify the `Select-Object` statement in the `$NewUser` creation section to include or exclude specific user attributes.
        Adjust the CSV file path (`$SavePath + "Users.csv"`) if you prefer a different location.
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
    
    $UserStreetAddress = $User.streetaddress

    # Create a custom object for the user with relevant properties
    $NewUser = [PSCustomObject]@{
        FirstName            = $User.GivenName
        LastName             = $User.Surname
        Name                 = $User.DisplayName
        UPN                  = $User.UserPrincipalName
        SamAccount           = $User.SamAccountName
        Title                = $User.Title
        LastLogonDate        = $User.LastLogonDate
        LastLogonTimeStamp   = [DateTime]::FromFileTime($User.LastLogonTimestamp).ToString('yyyy-MM-dd HH:mm:ss')
        LastPasswordChange   = [DateTime]::FromFileTime($User.PasswordLastSet)
        Email                = $User.EmailAddress
        Proxy                = $ProxyAddresses
        Manager              = $Manager
        ManagerEmail         = $ManagerEmail
        MemberOf             = $Groups
        HomeDirectory        = $User.HomeDirectory
        ProfilePath          = $User.ProfilePath
        LogonScript          = $User.ScriptPath
        OU                   = $User.CanonicalName
        Description          = $User.Description
        Office               = $User.Office
        State                = $User.State
        City                 = $User.City
        StreetAddress        = $UserStreetAddress
        OfficePhone          = $User.OfficePhone
        UserMustChangePassword     = $MustChangePassword
        UserCannotChangePassword  = $User.CannotChangePassword
        PasswordNeverExpires       = $User.PasswordNeverExpires
    }

    # Add the new user object to the array
    $NewUsers += $NewUser
}

# Export the user data to a CSV file
$NewUsers | Export-Csv -Path ($SavePath + "Users.csv") -NoTypeInformation
