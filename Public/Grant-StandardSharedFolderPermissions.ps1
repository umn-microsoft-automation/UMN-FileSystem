function Grant-StandardSharedFolderPermissions {
	<#
		.SYNOPSIS
			Gives standard permissions for a read and a modify group to a folder.
		.DESCRIPTION
			Takes in a path and two groups, one for modify and another for read permissions.
			It gives those groups their respective permissions and confirms the permissions have
			applied correctly.
		.EXAMPLE
			Grant-StandardSharedFolderPermissions -PathName "\\foo.bar\test" -ModifyName "ModifyGroup" -ReadName "ReadGroup" -DomainName "contoso.com" -MaxWait 10
		.PARAMETER PathName
			The path to the folder to be shared.
		.PARAMETER ModifyName
			The name of the group to give modify rights to the folder.
		.PARAMETER ReadName
			The name of the group to give read rights to the folder.
		.PARAMETER DomainName
			The name of the domain the groups are in.
		.PARAMETER MaxWait
			Maximum amount of time to wait before returning that the permissions have not applied correctly.
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$PathName,
		[Parameter(Mandatory=$true)][string]$ModifyName,
		[Parameter(Mandatory=$true)][string]$ReadName,
		[Parameter(Mandatory=$true)][string]$DomainName,
		[Parameter(Mandatory=$false)][int]$MaxWait = 30
	)

	$Count = 1
	$ShareStatus = $false
	while(($Count -le $MaxWait) -and (-not ($ShareStatus))) {
		try {
			# Get the ACL of the folder
			$ACL = [System.IO.Directory]::GetAccessControl($PathName)

			# Create the permissions
			$ModPermission = "$DomainName$ModifyName", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
			$ReadPermssion = "$DomainName$ReadName", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"

			# Create the access rule
			$ModifyAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $ModPermission
			$ReadAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $ReadPermssion

			# Set the ACL
			$ACL.SetAccessRule($ModifyAccessRule)
			$ACL.SetAccessRule($ReadAccessRule)

			# Apply the ACL to the folder
			[System.IO.Directory]::SetAccessControl($PathName, $ACL)

			$ShareStatus = $true
			$Count += $MaxWait
		
		} catch {
			if($_.Exception.Message -like "*SetAccessRule*") {
				# Catch an error referencing 'SetAccessRule'.  This string may be different in differnet languages.
				# Sleap 1 second then increment the counter to return to the while loop.
				Start-Sleep -Seconds 1
				$Count++
			} else {
				Write-Error -Message "Message: $($_.Exception.Message)"
				Write-Error -Message "ItemName: $($_.Exception.ItemName)"
			}
		}
	}

	if($ShareStatus) {
		return $true
	} else {
		return $false
	}
}