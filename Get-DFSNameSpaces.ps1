<#
Script is useful for gathering Information on DFS Shares
Must have DFS role installed where this is ran
Creates a Folder on your desktop
Queries DFS for all names Spaces in current Domain
Creates a cleaned up export and exports to the new folder
#>

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$SavePath = $DesktopPath + "\Information Gathered\"
if(!(Test-Path -Path $SavePath)) {

    New-Item -Path $SavePath -ItemType Directory -Force

}

$NameSpaces = Get-DfsnRoot
$DFSShares = @()

Foreach ($NameSpace in $NameSpaces) {

    $Folders = Get-DfsnFolder -Path ($NameSpace.Path + "\*")
    Foreach ($Folder in $Folders) {
    
        $Targets = Get-DfsnFolderTarget -Path $Folder.Path

        foreach ($Target in $Targets) {
            $DFSShare = [PSCustomObject]@{
                DFSNameSpace = $NameSpace.Path
                DFSFolder = ($Folder.Path -split '\\')[-1]
                Target = $Target.TargetPath
                State = $Target.State
            }
            $DFSShares += $DFSShare
        }

    }

}

$DFSShares | Export-Csv -Path ($SavePath + "DFSShares.csv") -NoTypeInformation