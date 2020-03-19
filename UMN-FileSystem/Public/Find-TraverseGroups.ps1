function Find-TraverseGroups {
	<#
		.SYNOPSIS
			Takes a path and returns the traverse groups on the folder.
		.DESCRIPTION
			Returns an array of ADGroups objects that have traverse rights to the path given.
		.EXAMPLE
			Find-TraverseGroups -Path \\foo.bar\test
		.PARAMETER Path
			The full path to the folder you would like to get traverse folders for.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)][string]$Path
	)


	$TraverseGroups = @()

	# Build tests for traverse group
	$travRights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute,Synchronize"
	$travInheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
	$travPropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
	$travType = [System.Security.AccessControl.AccessControlType]::Allow

	# Get the root of the path
	if ($Path.StartsWith("\\")) {
		$RootPath = "\\" + [string]::Join("\", $Path.Split("\")[2])
	}
 else {
		$RootPath = Split-Path -Path $Path -Qualifier
	}
	

	# Split up paths and pull the root
	$spath = $Path.Replace("$RootPath\", "").Split("\")
	$Paths = New-Object System.Collections.ArrayList

	# Build a list of all the directories that lead to the target directory
	for ($i = 0; $i -le $spath.Length; $i++) {
		if ($null -ne $spath[$i]) {
			$PathToAdd = ""
			for ($j = 0; $j -le $i; $j++) {
				$PathToAdd += "$($spath[$j])\"
			}
			# Add the new path to our list of paths
			$Paths.Add("$RootPath\$PathToAdd") | Out-Null
		}
	}

	# Loop through the paths and determine which contain a traverse group
	foreach ($item in $Paths) {
		$itemacl = Get-Acl -Path $item

		foreach ($acl in $itemacl.Access) {
			# Check the acl for the traverse permissions defined earlier
			if (($acl.InheritanceFlags -eq $travInheritanceFlag) -and ($acl.PropagationFlags -eq $travPropagationFlag) -and ($acl.FileSystemRights -eq $travRights) -and ($acl.AccessControlType -eq $travType) -and ($acl.IsInherited -eq $false)) {
				
				# We've now found a traverse group
				$SamAccountName = $acl.IdentityReference.ToString().Split("\")[1]

				# Make sure the account name isn't null, then get the group make sure it exists in AD then add the path to the group output object.
				if ($null -ne $SamAccountName) {
					$ADObject = Get-ADGroup -Identity $SamAccountName
					if ($null -ne $ADObject) {
						$TraverseGroups += $ADObject | Add-Member -MemberType NoteProperty -Name TraversePath -Value $item -Force -PassThru
					}
				}
			}
		}
	}

	return $TraverseGroups
}