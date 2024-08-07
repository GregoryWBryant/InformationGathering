<#
    This is a collection of all the scripts for collectiong information.
#>


function Create-DesktopInformationGathered {
    <#
        .SYNOPSIS
            Creates the folder structure on the desktop for storing gathered information.

        .DESCRIPTION
            This function checks for the existence of a folder named "Information Gathered" on the user's desktop. If the folder does not exist, it creates it. This folder is intended to store various information gathered by other functions or scripts.

        .PARAMETER
            No parameters are required.

        .EXAMPLE
            Create-DesktopInformationGathered
            Checks for the presence of the "Information Gathered" folder on the desktop. If not found, creates the folder to ensure it is available for storing gathered information.

        .NOTES
            This function assumes the script is running on a Windows environment where PowerShell can access the desktop path using .NET Framework.
    #>

    # Gets the Desktop folder path
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    # Creates the output folder path by combining Desktop path and "Information Gathered" subfolder
    $global:SavePath = $DesktopPath + "\Information Gathered\"
    # Checks if the output folder exists. If not, creates it (Force parameter ensures overwriting if it already exists)
    if (!(Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
        }
    # Checks if the output folder exists for DHCP. If not, creates it (Force parameter ensures overwriting if it already exists)
    if (!(Test-Path -Path $SavePath)) {
        New-Item -Path ($SavePath + "\DHCP\") -ItemType Directory -Force
        }

}

function Get-ACLsFolders {
    <#
        .SYNOPSIS
            Gets the Access Control Lists (ACLs) for folders within a specified path.

        .DESCRIPTION
            This function retrieves the security permissions for folders. You can choose to include subfolders using the -Recursive parameter. 
            It excludes some pre-defined folders like "Program Files" and "Windows" for efficiency. 
            The script gathers information about the folder name, security identity, 
            associated permissions, and whether the permission is inherited. 
            The information is then stored in a report object and exported as a CSV file.

        .PARAMETER Path
            The path to the directory for which you want to gather ACL information. 
            This parameter is mandatory (marked with [Parameter(Mandatory = $true)]).

        .PARAMETER Recursive
            [Switch] parameter. Specifies whether to include subfolders in the ACL gathering process. 
            If not specified, only the provided path's direct child folders will be analyzed.

        .EXAMPLE
            Get-ACLs -Path "C:\MyDocuments"

            This example retrieves the ACLs for all folders within the "C:\MyDocuments" directory (excluding subfolders).

        .EXAMPLE
            Get-ACLs -Path "C:\MyDocuments" -Recursive

            This example retrieves the ACLs for all folders and subfolders within the "C:\MyDocuments" directory.

        .Notes
            Should be ran ad Administrator for best results.
    #>

    param (
    [Parameter(Mandatory = $true)]
        [string]$Path,
        [switch]$Recursive
    )

    $Report = @()

    # Determines how to get folders based on the Recursive parameter
    if ($Recursive) {
        # Gets all directories recursively (including subfolders) in the specified path, excluding some predefined folders for efficiency
        $AllFolders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object { $_.Name -notmatch 'DFSPrivate|DFSRoots|Program Files|SharedFolders|Users|Windows' }
        } else {
            # Gets all child directories in the specified path, excluding some predefined folders for efficiency
            $AllFolders = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -notmatch 'DFSPrivate|DFSRoots|Program Files|SharedFolders|Users|Windows' }
            }

    # Loops through each folder (including subfolders if specified)
    Foreach ($Folder in $AllFolders) {
        write-host $Folder.FullName
        # Gets the Access Control List (ACL) for the current folder
        $Acl = Get-Acl -Path $Folder.FullName
        # Loops through each access entry in the ACL
        foreach ($Access in $acl.Access) {
            # Creates a hashtable to store folder information and access details
            $Properties = [ordered]@{'FolderName'=$Folder.FullName;'Security' = $Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
            # Adds the hashtable containing folder information and access details to an output collection ($Report)
            $Report += New-Object -TypeName PSObject -Property $Properties
            }
        }

    # Exports Report to "\Information Gathered\" Folder on your Desktop
    $Report | Export-Csv -path ( $SavePath + "FolderPermissions.csv") -NoTypeInformation
}

function Get-ADActiveServers {
    <#
        .SYNOPSIS
            Retrieves a list of active servers from Active Directory.

        .DESCRIPTION
            This script identifies active servers in Active Directory that have been logged into within the last specified number of days. 
            The servers must be enabled and not be Windows workstation machines. 
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER Days
            The number of days to look back from the current date for the last logon time. 
            Default is 90 days.

        .EXAMPLE
            Get-ADActiveServers -Days 90
            Retrieves a list of active servers that have been logged into within the last 90 days 
            and saves the information to a CSV file on the desktop.

        .NOTES
            Function requires the Active Directory module.
#>
    param (
        [int]$Days = 90
    )

    # Import the Active Directory PowerShell module
    Import-Module ActiveDirectory

    # Calculate the date for the specified number of days ago
    $time = (Get-Date).AddDays(-$Days)

    # Get active servers (LastLogonDate within the last 60 days and enabled)
    Get-ADComputer -Filter {LastLogonDate -gt $time -and Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties * |
        Select Name,LastLogonDate,OperatingSystem | 
        Export-Csv ($SavePath + "ActiveServers.csv") -NoTypeInformation
}

function Get-ADActiveWorkstations {
    <#
        .SYNOPSIS
            Retrieves a list of active workstations from Active Directory.

        .DESCRIPTION
            This script identifies active workstations in Active Directory that have been logged into within the last specified number of days. 
            The workstations must be enabled and not be Windows Server machines. 
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER Days
            The number of days to look back from the current date for the last logon time. 
            Default is 90 days.

        .EXAMPLE
            Get-ADActiveWorkstations -Days 90
            Retrieves a list of active workstations that have been logged into within the last 90 days 
            and saves the information to a CSV file on the desktop.

        .NOTES
            The script requires the Active Directory module.
    #>
    param (
        [int]$Days = 90
    )

    # Import the Active Directory PowerShell module
    Import-Module ActiveDirectory

    # Calculate the date for the specified number of days ago
    $time = (Get-Date).AddDays(-$Days)

    # Get active workstations (LastLogonDate within the specified number of days, enabled, and not servers)
    Get-ADComputer -Filter {LastLogonDate -gt $time -and Enabled -eq $true -and OperatingSystem -notlike '*Windows Server*'} -Properties * |
        Select Name,LastLogonDate,OperatingSystem |
        Export-Csv ($SavePath + "ActiveWorkstations.csv") -NoTypeInformation
}

function Get-ADAllGroupMemberships {
    <#
        .SYNOPSIS
            Retrieves all members of all security groups in Active Directory and saves the information to a CSV file on the user's desktop.

        .DESCRIPTION
            This script queries all groups in Active Directory and retrieves their members. The gathered information includes the group name, category, scope, member name, and member class.
            The results are then exported to a CSV file on the user's desktop.

        .PARAMETER
            No additional parameters are required for this function.

        .EXAMPLE
            Get-ADAllGroupMemberships

        .NOTES
            The script requires the Active Directory PowerShell module.
            Ensure you have the necessary permissions to read group memberships in Active Directory.
    #>

    # Initialize an array to store group information
    $AllGroups = @()

    # Get all security groups in Active Directory
    $Groups = Get-ADGroup -Filter *

    foreach ($Group in $Groups) {
        try {
            # Get members of the group
            $Members = Get-ADGroupMember -Identity $Group.DistinguishedName

            if ($Members.Count -eq 0) {
                # Handle empty groups
                $GroupInfo = [PSCustomObject] @{
                    GroupName     = $Group.Name
                    GroupCategory = $Group.GroupCategory
                    GroupScope    = $Group.GroupScope
                    MemberName    = "Empty"
                    MemberClass   = "NA"
                }
                $AllGroups += $GroupInfo
            } else {
                foreach ($Member in $Members) {
                    # Create a custom object for each member's group info
                    $GroupInfo = [PSCustomObject] @{
                        GroupName     = $Group.Name
                        GroupCategory = $Group.GroupCategory
                        GroupScope    = $Group.GroupScope
                        MemberName    = $Member.Name
                        MemberClass   = $Member.objectClass
                    }
                    # Add the group info to the array
                    $AllGroups += $GroupInfo
                }
            }
        } catch {
            Write-Output ("Unable to get members of: " + $Group.Name)
        }
    }

    # Export the collected group data to a CSV file
    $AllGroups | Export-Csv -Path (Join-Path -Path $SavePath -ChildPath "AllGroupsMemberShips.csv") -NoTypeInformation
}

function Get-ADDisabledUsers {
    <#
        .SYNOPSIS
            Retrieves information about disabled users in Active Directory and exports it to a CSV file.

        .DESCRIPTION
            This script collects detailed information about all disabled users in Active Directory, including their 
            properties such as display name, user principal name, group memberships, manager information, and organizational unit.
            The collected information is saved to a CSV file on the user's desktop.

        .PARAMETER None
            The script does not require any parameters.

        .EXAMPLE
            Get-ADDisabledUsers
            Retrieves information about Disabled users in Active Directory and saves it to a CSV file on the desktop.

        .NOTES
            The script requires the Active Directory PowerShell module.
    #>

    # Initialize an empty array to store user objects
    $NewUsers = @()

    # Get all disabled users and their properties from Active Directory
    $Users = Get-ADUser -Filter * -Properties * | Where-Object { $_.Enabled -eq $false }

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
    $NewUsers | Export-Csv -Path ($SavePath + "DisabledUsers.csv") -NoTypeInformation
}

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

function Get-ADInactiveServers {
    <#
        .SYNOPSIS
            Retrieves a list of inactive servers from Active Directory.

        .DESCRIPTION
            This script identifies inactive servers in Active Directory that have not been logged into within the last specified number of days. 
            The servers must be not be Windows workstation machines. 
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER Days
            The number of days to look back from the current date for the last logon time. 
            Default is 90 days.

        .EXAMPLE
            Get-ADInactiveServers -Days 30
            Retrieves a list of inactive servers that have not been logged into within the last 30 days 
            and saves the information to a CSV file on the desktop.

        .NOTES
            The script requires the Active Directory module.
    #>

    param (
        [int]$Days = 90
    )

    # Import the Active Directory PowerShell module
    Import-Module ActiveDirectory

    # Calculate the date for the specified number of days ago
    $time = (Get-Date).AddDays(-$Days)

    # Get inactive servers (LastLogonDate older than the specified time and running a Windows Server OS)
    Get-ADComputer -Filter {LastLogonDate -lt $time -and OperatingSystem -like '*Windows Server*'} -Properties * |
        Select-Object Name,LastLogonDate,OperatingSystem | 
        Export-Csv ($SavePath + "InactiveServers.csv") -NoTypeInformation
}

function Get-ADInactiveWorkstations {
    <#
        .SYNOPSIS
            Retrieves a list of inactive workstations from Active Directory.

        .DESCRIPTION
            This script identifies inactive workstations in Active Directory that have been logged into within the last specified number of days. 
            The workstations must not be Windows Server machines. 
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER Days
            The number of days to look back from the current date for the last logon time. 
            Default is 90 days.

        .EXAMPLE
            Get-ADInactiveWorkstations -Days 30
            Retrieves a list of inactive workstations that have been logged into within the last 30 days 
            and saves the information to a CSV file on the desktop.

        .NOTES
            The script requires the Active Directory module.
    #>

    param (
        [int]$Days = 90
    )

    # Import the Active Directory PowerShell module
    Import-Module ActiveDirectory

    # Calculate the date for the specified number of days ago
    $time = (Get-Date).AddDays(-$Days)

    # Get inactive workstations (LastLogonDate older than the specified time and not running a Windows Server OS)
    Get-ADComputer -Filter {LastLogonDate -lt $time -and OperatingSystem -notlike '*Windows Server*'} -Properties * |
        Select-Object Name,LastLogonDate,OperatingSystem | 
        Export-Csv ($SavePath + "InactiveWorkstations.csv") -NoTypeInformation
}

function Get-DFSNameSpaces {
    <#
        .SYNOPSIS
            Retrieves DFS Namespace and target information from the current domain.

        .DESCRIPTION
            This script identifies all DFS Namespaces in the current domain and collects information about each DFS folder and its targets. 
            The results are saved to a CSV file on the user's desktop, providing details about the namespace path, folder name, target path, and state.

        .PARAMETER None
            The script does not require any parameters.

        .EXAMPLE
            et-DFSNamespaces
            Retrieves DFS Namespace and target information and saves the information to a CSV file on the desktop.

        .NOTES
            The script requires DFS be installed on the local device.
    #>

    # Get all DFS Namespace roots in the current domain
    $NameSpaces = Get-DfsnRoot

    # Initialize an array to hold DFS share information
    $DFSShares = @()

    # Iterate through each DFS Namespace
    foreach ($NameSpace in $NameSpaces) {
        Write-Output "Processing DFS Namespace: $($NameSpace.Path)" # Add a status message

        # Get all folders within the current namespace
        $Folders = Get-DfsnFolder -Path ($NameSpace.Path + "\*") # Use wildcard to get all folders

        # Iterate through each folder in the namespace
        foreach ($Folder in $Folders) {
            # Get the targets (shared folders) for the current DFS folder
            $Targets = Get-DfsnFolderTarget -Path $Folder.Path

            # Iterate through each target and create a custom object
            foreach ($Target in $Targets) {
                $DFSShare = [PSCustomObject]@{
                    DFSNamespace = $NameSpace.Path # Full DFS Namespace path
                    DFSFolder = ($Target.Path -split '\\')[-1] # Extract folder name from path
                    Target = $Target.TargetPath # Full path of the shared folder target
                    State = $Target.State  # Active or Offline status
                }
                $DFSShares += $DFSShare  # Add the object to the array
            }
        }
    }

    # Export the DFS share information to a CSV file
    $DFSShares | Export-Csv -Path ($SavePath + "DFSShares.csv") -NoTypeInformation

    # Add a success message
    Write-Output "DFS share information exported to: $($SavePath + 'DFSShares.csv')" 
}

function Get-DHCPScopeData {
    <#
        .SYNOPSIS
            Retrieves DHCP scope data from specified DHCP servers and exports it to CSV files.

        .DESCRIPTION
            This script collects detailed DHCP scope information, including exclusion ranges, leases, reservations, option values, and scope details from specified DHCP servers. The data is exported to CSV files stored in a directory on the user's desktop.

        .PARAMETER All
            When specified, retrieves DHCP scope data from all enabled Searvers that are reachable. Otherwise, retrieves data from the local server.

        .EXAMPLE
            Get-DHCPScopeData
            Retrieves DHCP scope data from the local server and saves it to CSV files.

            Get-DHCPScopeData -All
            Retrieves DHCP scope data from all active servers within the specified timeframe and saves it to CSV files.

        .NOTES
            The script requires the DHCP Server PowerShell module.
    #>

    param(
        [switch]$All
    )

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the save path for the CSV files
    $DHCPPath = $SavePath + "DHCP\"
    if (-not (Test-Path -Path $DHCPPath)) {
        New-Item -Path $DHCPPath -ItemType Directory -Force
    }

    # Get the name of the computer you are running the script on
    $ComputerName = [System.Environment]::MachineName

    # Get a list of all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

    if (!($All)) {
        $Servers = $Servers | Where-Object {$_.Name -eq $ComputerName}
    }

    foreach ($Server in $Servers) {
        if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {
            try {
                $Scopes = Get-DhcpServerv4Scope -ComputerName $Server.Name
                foreach ($Scope in $Scopes) {
                    Write-Output "Processing Server: $($Server.Name), Scope: $($Scope.ScopeId)"
                    # Get and export DHCP data for each scope (with server name in file name)
                    Get-DhcpServerv4ExclusionRange -ScopeId $Scope.ScopeId -ComputerName $Server.name | Export-Csv -Path ($DHCPPath + "\" + $Server.name + "-" + $Scope.ScopeId + "-ExclusionRange.csv") -NoTypeInformation
                    Get-DhcpServerv4Lease -ScopeId $Scope.ScopeId -ComputerName $Server.name | Export-Csv -Path ($DHCPPath + "\" + $Server.name + "-" + $Scope.ScopeId + "-Leases.csv") -NoTypeInformation
                    Get-DhcpServerv4Reservation -ScopeId $Scope.ScopeId -ComputerName $Server.name | Export-Csv -Path ($DHCPPath + "\" + $Server.name + "-" + $Scope.ScopeId + "-Reservations.csv") -NoTypeInformation
                    Get-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId -ComputerName $Server.name | Select-Object OptionId,Name,Type,@{Name='Value';Expression={[string]::join(";", ($_.Value))}} | Export-Csv -Path ($DHCPPath + "\" + $Server.name + "-" + $Scope.ScopeId + "-Options.csv") -NoTypeInformation
                    Get-DhcpServerv4Scope -ScopeId $Scope.ScopeId -ComputerName $Server.name | Export-Csv -Path ($DHCPPath + "\" + $Server.name+ "-" + $Scope.ScopeId + "-Scope.csv") -NoTypeInformation
                    }
                } catch { Write-Warning "No scopes found on: $($Server.Name)" }
            } else { Write-Output ("Can't Reach: " + $Server.Name) }
        }
}

function Get-InstalledApplications {
    <#
        .SYNOPSIS
            Retrieves installed applications from local or remote servers and exports the data to CSV files.

        .DESCRIPTION
            This script collects information about installed applications from servers within the Active Directory domain. It retrieves data from both 32-bit and 64-bit registry keys, creates custom objects for each application, and exports the information to CSV files stored in a directory on the user's desktop or copied from remote servers.

        .PARAMETER All
            When specified, retrieves DHCP scope data from all enabled Searvers that are reachable. Otherwise, retrieves data from the local server.

        .EXAMPLE
            Get-InstalledApplications
            Retrieves installed applications from the local server and saves it to CSV files.

            Get-InstalledApplications -All
            Retrieves installed applications from all enabled servers in Active Directory, including the local server, and saves the data to CSV files.

        .NOTES
            The script requires the Active Directory PowerShell module and administrator privileges on remote servers to retrieve registry information.
    #>

    param(
        [switch]$All
    )

    # Get the name of the computer you are running the script on
    $ComputerName = [System.Environment]::MachineName

    # Get a list of all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

    if (!($All)) {
        $Servers = $Servers | Where-Object {$_.Name -eq $ComputerName}
    }

    # Iterate through each server in the list
    foreach ($Server in $Servers) {
        if (Test-Connection -ComputerName $Server.name -Quiet -Count 1) {
            Write-Output ("Checking Server: " + $Server.name) # Informational message

            # If the server is the same as the computer you are running the script on...
            if ($Server.name -eq $ComputerName) {
                $AllApplications = @() # Initialize an empty array to store application data
                $Reg32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"  # 32-bit registry key path
                $Reg64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"  # 64-bit registry key path

                # Get installed application information from both 32-bit and 64-bit registry keys
                $Applications = Get-ItemProperty -Path $Reg32, $Reg64 | Select-Object DisplayName, DisplayVersion, InstallDate

                # Create custom objects for each application and add to the array
                foreach ($Application in $Applications) {
                    $NewApplication = [PSCustomObject]@{
                        Server = $Server.name
                        Name = $Application.DisplayName
                        Version = $Application.DisplayVersion
                        InstalledOn = $Application.InstallDate
                    }
                    $AllApplications += $NewApplication
                }

                # Export the application information to a CSV file in the Information Gathered folder
                $AllApplications | Export-Csv -Path ($SavePath + $ComputerName + "-Applications.csv") -NoTypeInformation
            } else {
                # If the server is not the same as the computer you are running the script on...

                # Use Invoke-Command to run the script remotely on the server
                Invoke-Command -ComputerName $Server.name {
                    $ComputerName = (Get-ComputerInfo).CSName # Get the server name
                    $AllApplications = @()
                    $Reg32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                    $Reg64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                    $Applications = Get-ItemProperty -Path $Reg32, $Reg64 | Select-Object DisplayName, DisplayVersion, InstallDate

                    foreach ($Application in $Applications) {
                        $NewApplication = [PSCustomObject]@{
                            Server = $ComputerName
                            Name = $Application.DisplayName
                            Version = $Application.DisplayVersion
                            InstalledOn = $Application.InstallDate
                        }
                        $AllApplications += $NewApplication
                    }

                    # Export the application information to a CSV file in the C:\Temp folder on the server
                    $AllApplications | Export-Csv -Path ("C:\Temp\" + $ComputerName + "-Applications.csv") -NoTypeInformation
                }

                # Copy the CSV file from the server to the Information Gathered folder on your computer
                Copy-Item -Path ("\\" + $Server.name + "\C$\Temp\" + $Server.name + "-Applications.csv") -Destination ($SavePath + $Server.name + "-Applications.csv")
                # Remove the temporary CSV file from the server
                Remove-Item -Path ("\\" + $Server.name + "\C$\Temp\" + $Server.name + "-Applications.csv")
            }
        } else {
            Write-Output ("Can't reach: " + $Server.Name)
        }
    }
}

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

function Get-RolesInstalled {
    <#
        .SYNOPSIS
            Retrieves the installed Windows Server roles on all enabled servers in Active Directory.

        .DESCRIPTION
            This script queries all enabled servers in Active Directory that are running a version of Windows Server.
            It checks if each server is reachable, then retrieves and records the installed roles on each server.
            The results are saved to a CSV file on the user's desktop.

        .PARAMETER All
            When specified, retrieves DHCP scope data from all enabled Searvers that are reachable. Otherwise, retrieves data from the local server.

        .EXAMPLE
            Get-RolesInstalled
            Retrieves the installed roles from the local server and saves it to CSV files.

            Get-RolesInstalled -All
            Retrieves the installed roles from all active servers within the specified timeframe and saves it to CSV files.

        .NOTES
            This function assumes the script is running on a Windows environment where PowerShell can access the desktop path using .NET Framework.
    #>

    param(
        [switch]$All
    )

    # Get the name of the computer you are running the script on
    $ComputerName = [System.Environment]::MachineName

    # Get a list of all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

    if (!($All)) {
        $Servers = $Servers | Where-Object {$_.Name -eq $ComputerName}
    }

    $RolesData = @()

    # Iterate through each server
    foreach ($Server in $Servers) {
        # Test if the server is reachable
        if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {
            Write-Output ("Checking Server: " + $Server.Name) # Informational message
            $Roles = Get-WindowsFeature -ComputerName $Server.Name | Where-Object { $_.installstate -eq "installed" -and $_.FeatureType -eq "Role" }
            foreach ($Role in $Roles) {
                $NewRole = [PSCustomObject]@{
                    Server = $Server.Name
                    Name = $Role.DisplayName
                }
                $RolesData += $NewRole
            }
        } else {
            Write-Output ("Can't reach: " + $Server.Name)
        }
    }

    # Export the collected role data to a CSV file
    $RolesData | Export-Csv -Path ($SavePath + "Roles.csv") -NoTypeInformation
}

function Get-ShareInfo {
    <#
        .SYNOPSIS
            Retrieves information about shared folders from enabled Windows Server machines in Active Directory and exports it to a CSV file.

        .DESCRIPTION
            This script connects to each enabled Windows Server in Active Directory, retrieves information about shared folders excluding built-in and printer shares, and exports the details (server name, share name, path, description) to a CSV file.

        .PARAMETER All
            When specified, retrieves DHCP scope data from all enabled Searvers that are reachable. Otherwise, retrieves data from the local server.

        .EXAMPLE
            Get-ShareInfo
            Retrieves shared folder information from the local server and saves it to CSV files.

            Get-ShareInfo -All
            Retrieves shared folder information from all active servers within the specified timeframe and saves it to CSV files.

        .NOTES
            The script requires the Active Directory PowerShell module and administrator privileges to retrieve share information from remote servers.
    #>

    param(
        [switch]$All
    )

    # Get the name of the computer you are running the script on
    $ComputerName = [System.Environment]::MachineName

    # Get a list of all enabled servers in Active Directory
    $Servers = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -like '*Windows Server*'} -Properties *

    if (!($All)) {
        $Servers = $Servers | Where-Object {$_.Name -eq $ComputerName}
    }

    $SharesData = @() 

    # Iterate through each server
    foreach ($Server in $Servers) {
        # Test if the server is reachable
        if (Test-Connection -ComputerName $Server.Name -Quiet -Count 1) {
            Write-Output ("Checking Server: " + $Server.Name) # Informational message
            # Create a CIM session to the remote server
            $Cim = New-CimSession -ComputerName $Server.Name 
            # Get shared folders, excluding built-in and printer shares
            $Shares = Get-SmbShare -CimSession $Cim | Where-Object {
                $_.ShareType -eq "FileSystemDirectory" -and 
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
                Write-Output ("Can't reach: " + $Server.Name)
                }
        }

    # Export the collected share data to a CSV file
    $SharesData | Export-Csv -Path ($SavePath + "Shares.csv") -NoTypeInformation
}

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



Write-Output "Creating Desktop Folder"
Create-DesktopINformationGathered
#Get-ACLs _Path
    # Must provide a path for the location of folders to get ACLs of
Write-Output "Getting active servers"
Get-ADActiveServers
Write-Output "Getting active workstations"
Get-ADActiveWorkstations
Write-Output "Getting all groups and memberships"
Get-ADAllGroupMemberships
Write-Output "Getting disabled users"
Get-ADDisabledUsers
Write-Output "Getting enabled users"
Get-ADEnabledUsers
Write-Output "Getting inactive servers"
Get-ADInactiveServers
Write-Output "Getting inactive workstations"
Get-ADInactiveWorkstations
Write-Output "Getting DFS name spaces"
Get-DFSNameSpaces  -All
Write-Output "Getting DHCP scopes"
Get-DHCPScopeData -All
Write-Output "Getting installed applications"
Get-InstalledApplications -All
Write-Output "Getting shared printers"
Get-Printers -All
Write-Output "Getting installed roles"
Get-RolesInstalled -All
Write-Output "Getting shared folders"
Get-ShareInfo -All
Write-Output "Converting DHCP Reservations to Meraki Format"
Convert-WindowsDHCPToMerakiDHCP
