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
    # Gets the Desktop folder path
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Creates the output folder path by combining Desktop path and "Information Gathered" subfolder
    $SavePath = $DesktopPath + "\Information Gathered\"

    # Checks if the output folder exists. If not, creates it (Force parameter ensures overwriting if it already exists)
    if (!(Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
        }
        
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
