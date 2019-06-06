<#
    TODO: Add comment based help.
#>
function Get-DirectoryPermissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
            HelpMessage="Path to the directory to get permissions on.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$false,
            HelpMessage="Switch to use if you want to recurse through the structure and get permissions on all sub directories.",
            ParameterSetName="Recurse")]
        [switch]$Recurse = $false,

        [Parameter(Mandatory=$false,
            HelpMessage="Depth to go down the directories (not counting the root directory).",
            ParameterSetName="Recurse")]
        [ValidateNotNullOrEmpty()]
        [int]$Depth,

        [Parameter(Mandatory=$false,
            HelpMessage="Swich to use if you want to include inherited permission in the output.")]
        [switch]$IncludeInherited
    )

    [System.Collections.ArrayList]$Output = @()

    $RootACL = Get-NTFSAccess -Path $Path | Select-Object -Property *

    foreach($RootACE in $RootACL) {
        if($RootACE.IsInherited -eq $false) {
            [void]$Output.Add($RootACE)
        } elseif($IncludeInherited -and $RootACE.IsInherited -eq $true) {
            [void]$Output.Add($RootACE)
        }
    }

    if($Recurse) {
        $GetDirSpalt = @{
            "Path" = $Path
            "Directory" = $true
            "Hidden" = $true
            "System" = $true
            "SkipMountPoints" = $true
            "SkipSymbolicLinks" = $true
            "Recurse" = $true
        }

        if($Depth) {
            $GetDirSpalt.Add("Depth", $Depth)
        }

        $Directories = Get-ChildItem2 @GetDirSpalt

        foreach($Directory in $Directories) {
            $ACL = Get-NTFSAccess -Path $Directory.FullName

            foreach($ACE in $ACL) {
                if($ACE.IsInherited -eq $false) {
                    [void]$Output.Add($ACE)
                } elseif($IncludeInherited -and $ACE.IsInherited -eq $true) {
                    [void]$Output.Add($ACE)
                }
            }
        }
    }

    return $Output
}