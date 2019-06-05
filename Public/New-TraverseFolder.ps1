function New-TraverseFolder {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Name,
        [string]$TraverseGroupName,
        [string]$TraverseGroupOU,
        [string]$TraverseManagerGroupName,
        [string]$TraverseManagerGroupOU,

        [Parameter(Mandatory=$false)]
        [string]$TopLevelTraverseGroupName = $null,

        [Parameter(Mandatory=$false)]
        [string]$DomainName = (Get-ADDomain).NetBIOSName
    )

    if(-not (Test-Path -Path "$Path\$Name")) {
        New-Item -Path $Path -Name $Name -ItemType Directory
    } else {
        Write-Error -Message "Folder path already exists: $Path\$Name"
    }

    New-ADGroup -Name $TraverseManagerGroupName -SamAccountName $TraverseManagerGroupName -GroupCategory Security -GroupScope Global -Path $TraverseManagerGroupOU -Description "Controls access to: $Path\$Name"
    New-ADGroup -Name $TraverseGroupName -SamAccountName $TraverseGroupName -GroupCategory Security -GroupScope Global -Path $TraverseGroupOU -Description "Traverse to: $Path\$Name"

    Confirm-ADObjectDCReplication -ADObject $TraverseGroupName -Type Group
    Confirm-ADObjectDCReplication -ADObject $TraverseManagerGroupName -Type Group

    Set-ManagedByGroup -ADGroupName $TraverseGroupName -ADManagerGroupName $TraverseManagerGroupName

    $TraverseGroup = Get-ADGroup -Identity $TraverseGroupName

    if($TopLevelTraverseGroupName -ne $null) {
        Add-ADGroupMember -Identity $TopLevelTraverseGroupName -Members $TraverseGroup
    }

    $ACL = [System.IO.Directory]::GetAccessControl("$Path\$Name")
    $TraversePermission = "$DomainName\$TraverseGroupName", "ReadAndExecute", "None", "InheritOnly", "Allow"
    $TraverseAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $TraversePermission
    $ACL.SetAccessRule($TraverseAccessRule)
    [System.IO.Directory]::SetAccessControl("$Path\$Name", $ACL)
}