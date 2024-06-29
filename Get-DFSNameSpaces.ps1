<#
    Script: DFS Share Information Report

    Purpose
        Gathers information about DFS namespaces and their folder targets.
        Creates a folder on your desktop to store the results.
        Exports the information to a CSV file (DFSShares.csv).

    Requirements
        Must be run on a Domain Controller with the DFS Management Tools installed.
        Requires the DFSN (Distributed File System Namespace) PowerShell module.

    Notes
        The script will automatically retrieve all DFS namespaces in the current domain.
        Adjust the `$SavePath` if you want to store the CSV file in a different location.
#>

# Get the path to the user's desktop
$DesktopPath = [System.Environment]::GetFolderPath([System.Environment.SpecialFolder]::Desktop)

# Create the folder to store the output CSV file
$SavePath = $DesktopPath + "\Information Gathered\"
if (-not (Test-Path -Path $SavePath)) {
    New-Item -Path $SavePath -ItemType Directory -Force  
}

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
