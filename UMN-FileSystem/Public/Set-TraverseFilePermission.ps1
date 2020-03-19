function Set-TraverseFilePermission {
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
		$ADGroup
	)

	$ACL = Get-ACL -Path $Path

	$FileSystemRights = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute
	$InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::None
	$PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None
	$AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow

	$TraverseAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($ADGroup.SID, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType)
	$ACL.AddAccessRule($TraverseAccessRule)
	Set-Acl -Path $Path -AclObject $ACL
}
