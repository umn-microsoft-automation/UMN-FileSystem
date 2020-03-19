function Set-ModifyFilePermission {
	[CmdletBinding()]
	param(
		[Parameter(
			Mandatory = $true,
			Position = 0,
			ParameterSetName = "Path",
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = "Path to one location."
		)]
		[Alias("PSPath")]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,

		[Parameter(
			Mandatory = $true,
			Position = 1,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = "The Active Directory group to give modify rights to."
		)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.ActiveDirectory.Management.ADPrincipal]
		$ADGroup,
		
		[Parameter(
			Mandatory = $false,
			Position = 2,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = "Set deny delete on this folder only perm as well."
		)]
		[switch]
		$DenyDelete
	)

	$ACL = Get-ACL -Path $Path

	$FileSystemRights = [System.Security.AccessControl.FileSystemRights]::Modify
	$InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
	$PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None
	$AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow

	$ModifyAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($ADGroup.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
	$ACL.AddAccessRule($ModifyAccessRule)

	if ($DenyDelete) {
		$DDFileSystemRights = [System.Security.AccessControl.FileSystemRights]::Delete
		$DDInheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::None
		$DDPropagationFlags = [System.Security.AccessControl.PropagationFlags]::None
		$DDAccessControlType = [System.Security.AccessControl.AccessControlType]::Deny

		$DenyDeleteAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($ADGroup.SID, $DDFileSystemRights, $DDInheritanceFlags, $DDPropagationFlags, $DDAccessControlType)
		$ACL.AddAccessRule($DenyDeleteAccessRule)
	}

	Set-Acl -Path $Path -AclObject $ACL
}
