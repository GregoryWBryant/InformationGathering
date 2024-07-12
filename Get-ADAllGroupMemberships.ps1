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

    # Get the path to the user's desktop
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)

    # Create the folder to store the results
    $SavePath = Join-Path -Path $DesktopPath -ChildPath "Information Gathered"
    if (!(Test-Path -Path $SavePath)) {
        New-Item -Path $SavePath -ItemType Directory -Force
    }

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