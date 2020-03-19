<#
    TODO: Add comment based help.
#>
function New-SharedDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Path to the directory where the shared directory will be created and permissioned.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true,
            HelpMessage = "Name of the directory to be created and permissioned.")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true,
            HelpMessage = "The Active Directory group to give modify rights to on the folder.")]
        [ValidateNotNullOrEmpty()]
        [Microsoft.ActiveDirectory.Management.ADGroup]$ModifyGroup,

        [Parameter(Mandatory = $true,
            HelpMessage = "The Active Directory group to give read rights to on the folder.")]
        [ValidateNotNullOrEmpty()]
        [Microsoft.ActiveDirectory.Management.ADGroup]$ReadGroup,

        [Parameter(Mandatory = $false,
            HelpMessage = "The domain name where the Active Directory groups are located.")]
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

        $ModifyPermission = "$DomainName\$($ModifyGroup.SamAccountName)", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
        $ReadPermission = "$DomainName\$($ReadGroup.SamAccountName)", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"

        $ModifyAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $ModifyPermission
        $ReadAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $ReadPermission

        $ACL.SetAccessRule($ModifyAccessRule)
        $ACL.SetAccessRule($ReadAccessRule)

        [System.IO.Directory]::SetAccessControl("$Path\$Name", $ACL)
    }
    catch {
        Write-Error -Message "Message: $($_.Exception.Message)"
        Write-Error -Message "ItemName: $($_.Exception.ItemName)"
    }
}