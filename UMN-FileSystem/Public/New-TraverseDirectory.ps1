<#
.SYNOPSIS
    Creates a directory and gives an active directory group traverse rights to it.

.DESCRIPTION
    Given a path, a directory name and an active directory group it will create a folder and then give the active directory
    group read rights to the newly created directory at that level only (traverse).

.EXAMPLE
    New-TraverseDirectory -Path "K:\foo\bar" -Name "Test" -TraverseGroup (Get-ADGroup -Identity "MyTraverseGroup")

.PARAMETER Path
    Path to where the traverse folder will be created.

.PARAMETER Name
    Name of the folder to be created with traverse permissions.

.PARAMETER TraverseGroupName
    Name of the group to create and grant traverse rights to.

.PARAMETER TraverseGroupOU
    The distinguished name for the OU to create the AD group in.

.PARAMETER DomainName
    Domain name being worked on, by default will load the netbiosname of the Get-ADDomain command.
#>
function New-TraverseDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Path to where the traverse folder will be created.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true,
            HelpMessage = "Name of the folder to be created with traverse permissions.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true,
            HelpMessage = "Name of the group to grant traverse rights to.")]
        [ValidateNotNullOrEmpty()]
        [Microsoft.ActiveDirectory.Management.ADGroup]$TraverseGroup,

        [Parameter(Mandatory = $false,
            HelpMessage = "Domain name being worked on, by default will load the netbiosname of the Get-ADDomain command.")]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName = (Get-ADDomain).NetBIOSName
    )

    if (-not(Test-Path -Path "$Path\$Name")) {
        New-Item -Path $Path -Name $Name -ItemType Directory
    }
    else {
        throw "Folder path already exists: $Path\$Name"
    }

    try {
        $ACL = [System.IO.Directory]::GetAccessControl("$Path\$Name")
        $TraversePermission = "$DomainName\$($TraverseGroup.SamAccountName)", "ReadAndExecute", "None", "InheritOnly", "Allow"
        $TraverseAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $TraversePermission
        $ACL.SetAccessRule($TraverseAccessRule)
        [System.IO.DIrectory]::SetAccessControl("$Path\$Name", $ACL)
    }
    catch {
        throw "Error granting access permissions."
    }
    
}