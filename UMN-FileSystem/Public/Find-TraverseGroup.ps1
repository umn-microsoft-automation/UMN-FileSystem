function Find-TraverseGroup {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true,
			Position = 0,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = "Path to one location.")]
		[Alias("PSPath")]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path
	)

	$TraverseRights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute,Synchronize"
	$TraverseInheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
	$TraversePropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
	$TraverseAccessControlType = [System.Security.AccessControl.AccessControlType]::Allow

	$FolderName = Split-Path -Path $Path -Leaf

	$TraverseGroupFound = $false
	$TraverseGroupName = $null

	$ACL = Get-Acl -Path $Path
	foreach ($ACE in $ACL.Access) {
		# Check the ACE for the traverse permissions defined earlier
		

		if (($ACE.InheritanceFlags -eq $TraverseInheritanceFlag) -and ($ACE.PropagationFlags -eq $TraversePropagationFlag) -and ($ACE.FileSystemRights -eq $TraverseRights) -and ($ACE.AccessControlType -eq $TraverseAccessControlType) -and ($ACE.IsInherited -eq $false)) {
			Write-Verbose -Message "Found traverse group on $($FolderName): $($ACE.IdentityReference)"
			if ($TraverseGroupFound) {
				Write-Error -Message "Multiple traverse groups found on $FolderName" -ErrorAction Inquire
			}
			else {
				$TraverseGroupFound = $true
				$TraverseGroupName = $ACE.IdentityReference
			}
		}
	}

	if ($TraverseGroupFound) {
		return $TraverseGroupName
	}
 else {
		return $null
	}
}
