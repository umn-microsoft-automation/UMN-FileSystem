###
# Copyright 2017 University of Minnesota, Office of Information Technology

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
###

function Get-FileSharePermissionsParallel {
	<#
		.SYNOPSIS
		Retrieves all the explicit folder share permissions based on a supplied root path using parallelism.
		
		.DESCRIPTION
		Takes in a path and then inventories all folders in the path.  It then builds a report of file permissions explicitly defined in that path using parallelism.
		
		.PARAMETER RootPath
		A string which is the path to the file share you would like to have analyzed for explicit permissions.
		
		.EXAMPLE
		Get-FileSharePermissionsParallel -RootPath "\\Foo\bar"
		
		.EXAMPLE
		Get-FileSharePermissionsParallel -RootPath "\\Foo\bar" -Threads 50
		
		.NOTES
		Name: Get-FileSharePermissions
		Author: (Modularized by Jeff Bolduan)
		LASTEDIT: 2/15/2016, 3:35 PM
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)][string]$RootPath,
		[Parameter(Mandatory=$false)][int]$Threads=50
	)

	# Initialize an empty array to hold our report items
	$Report = @()

	# Get the ACL for our root level path pulling all properties
	$RootAccess = [array](Get-Access -Path $RootPath | Select-Object -Property *)

	# We want each ace item to have a property 'IsInheritedDuplicate' that indicates if it is 
	# not-inherited is it a duplicate of an inherited ace. (indicater that it's unnecessary).
	# Lastly we want the account attribute to be a simple string instaed of an identity reference.
	foreach($RootAce in $RootAccess) {
		Add-Member -InputObject $RootAce -MemberType NoteProperty -Name "IsInheritedDuplicate" -Value "root"
		Add-Member -InputObject $RootAce -MemberType NoteProperty -Name "Account" -Value $RootAce.Account.AccountName -Force
		$Report += $RootAce
	}

	# So that we can easily compare our ace objects we define the properties we want to evaluate.
	$AceCompareProperties = @("Account", "InheritanceFlags", "PropagationFlags", "AccessRights", "AccessControlType")

	# Let's get an array of all child paths by fullname.  Note the use of Get-ChildItem2 from NTFSSecurity / AlphaFS
	$FolderPaths = [array](Get-ChildItem2 -Path $RootPath -Directory -IncludeHidden -IncludeSystem -SkipMountPoints -SkipSymbolicLinks -Recurse | ForEach-Object { $_.FullName })

	# Proeccessing each path in parallel to speed things up, throttling to $Threads.
	$Report += $FolderPaths | Invoke-Parallel -ThrottleLimit $Threads -ScriptBlock {
		try {
			# Setup output object from invoke-parallel
			$ParallelOutput = @()

			# Get the acl for the path, pulling all properties
			$FolderAccess = [array](Get-Access -Path $_ | Select-Object -Property *)

			# Again we want the account attribute to be a simple string (works better for the Compare-Object cmdlet).
			foreach($FolderACE in $FolderAccess) {
				Add-Member -InputObject $FolderACE -MemberType NoteProperty -Name "Account" -Value $FolderACE.Account.AccountName -Force
			}

			# Seperate the inherited aces into their own array that we can compare against.
			$InheritedFolderAccess = [array]($FolderAccess | Where-Object -FilterScript { $_.IsInherited -eq $true })

			# Seperate the non-inherited aces into their own array to process.
			$NonInheritedFolderAccess = [array]($FolderAccess | Where-Object -FilterScript { $_.IsInherited -ne $true })

			# Process each non-inherited ace
			foreach($ace in $NonInheritedFolderAccess) {
			
				# Create an empty array to store using an array so we can use a simple count comparison for the IsInheritedDuplicateValue check
				$CompareResults = @()

				if($InheritedFolderAccess) {
					# Compare our ace against inherited aces based on the choosen ace properties. Only show objects that are identical
					$CompareResults = [array](Compare-Object -ReferenceObject $ace -DifferenceObject $InheritedFolderAccess -Property $AceCompareProperties -ExcludeDifferent -IncludeEqual)
				}

				# The CompareResults.Count should be greater than 0 if there was a duplicate, evaluating to $true otherwise false.
				$IsInheritedDuplicateValue = $CompareResults.Count -gt 0

				# Add the [bool] value of $IsInheritedDuplicateValue for the property IsInheritedDuplicate
				Add-Member -InputObject $ace -MemberType NoteProperty -Name "IsInheritedDuplicate" -Value $IsInheritedDuplicateValue -Force

				# Add the ace item to our report
				$ParallelOutput += $ace
			}

			Write-Output $ParallelOutput
		} catch {
			Write-Warning -Message "$($_.Exception.Message) : $($_.Exception.ItemName)"
		}
	}

	# Return the report
	return $Report
}

function Get-FileSharePermissions {
	<#
		.SYNOPSIS
		Retrieves all the explicit folder share permissions based on a supplied root path.
		
		.DESCRIPTION
		Takes in a path and then inventories all folders in the path.  It then builds a report of file permissions explicitly defined in that path.
		
		.PARAMETER RootPath
		A string which is the path to the file share you would like to have analyzed for explicit permissions.
		
		.EXAMPLE
		Get-FileSharePermissions -RootPath "\\Foo\bar"
		
		.NOTES
		Name: Get-FileSharePermissions
		Author: (Modularized by Jeff Bolduan)
		LASTEDIT: 2/15/2016, 3:35 PM
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)][string]$RootPath
	)

	# Initialize an empty array to hold our report items
	$Report = @()

	# Get the ACL for our root level path pulling all properties
	$RootAccess = [array](Get-Access -Path $RootPath | Select-Object -Property *)

	# We want each ace item to have a property 'IsInheritedDuplicate' that indicates if it is 
	# not-inherited is it a duplicate of an inherited ace. (indicater that it's unnecessary).
	# Lastly we want the account attribute to be a simple string instaed of an identity reference.
	foreach($RootAce in $RootAccess) {
		Add-Member -InputObject $RootAce -MemberType NoteProperty -Name "IsInheritedDuplicate" -Value "root"
		Add-Member -InputObject $RootAce -MemberType NoteProperty -Name "Account" -Value $RootAce.Account.AccountName -Force
		$Report += $RootAce
	}

	# So that we can easily compare our ace objects we define the properties we want to evaluate.
	$AceCompareProperties = @("Account", "InheritanceFlags", "PropagationFlags", "AccessRights", "AccessControlType")

	# Let's get an array of all child paths by fullname.  Note the use of Get-ChildItem2 from NTFSSecurity / AlphaFS
	$FolderPaths = [array](Get-ChildItem2 -Path $RootPath -Directory -IncludeHidden -IncludeSystem -SkipMountPoints -SkipSymbolicLinks -Recurse | ForEach-Object { $_.FullName })

	$i = 1

	# Proeccessing each path in parallel to speed things up, throttling to $Threads.
	foreach($Folder in $FolderPaths) {
		try {
			Write-Progress -Activity "Getting ACE for folder: $Folder" -Status "Percent complete: " -PercentComplete (($i / $FolderPaths.Count) * 100)

			# Setup output object from invoke-parallel
			$ParallelOutput = @()

			# Get the acl for the path, pulling all properties
			$FolderAccess = [array](Get-Access -Path $Folder | Select-Object -Property *)

			# Again we want the account attribute to be a simple string (works better for the Compare-Object cmdlet).
			foreach($FolderACE in $FolderAccess) {
				Add-Member -InputObject $FolderACE -MemberType NoteProperty -Name "Account" -Value $FolderACE.Account.AccountName -Force
			}

			# Seperate the inherited aces into their own array that we can compare against.
			$InheritedFolderAccess = [array]($FolderAccess | Where-Object -FilterScript { $_.IsInherited -eq $true })

			# Seperate the non-inherited aces into their own array to process.
			$NonInheritedFolderAccess = [array]($FolderAccess | Where-Object -FilterScript { $_.IsInherited -ne $true })

			# Process each non-inherited ace
			foreach($ace in $NonInheritedFolderAccess) {
			
				# Create an empty array to store using an array so we can use a simple count comparison for the IsInheritedDuplicateValue check
				$CompareResults = @()

				if($InheritedFolderAccess) {
					# Compare our ace against inherited aces based on the choosen ace properties. Only show objects that are identical
					$CompareResults = [array](Compare-Object -ReferenceObject $ace -DifferenceObject $InheritedFolderAccess -Property $AceCompareProperties -ExcludeDifferent -IncludeEqual)
				}

				# The CompareResults.Count should be greater than 0 if there was a duplicate, evaluating to $true otherwise false.
				$IsInheritedDuplicateValue = $CompareResults.Count -gt 0

				# Add the [bool] value of $IsInheritedDuplicateValue for the property IsInheritedDuplicate
				Add-Member -InputObject $ace -MemberType NoteProperty -Name "IsInheritedDuplicate" -Value $IsInheritedDuplicateValue -Force

				# Add the ace item to our report
				$ParallelOutput += $ace
			}

			Write-Output $ParallelOutput
		} catch {
			Write-Warning -Message "$($_.Exception.Message) : $($_.Exception.ItemName)"
		}
		$i++
	}
	
	# Return the report
	return $Report
}

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
		[Parameter(Mandatory=$true)][string]$Path
	)


	$TraverseGroups = @()

	# Build tests for traverse group
	$travRights = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute,Synchronize"
	$travInheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
	$travPropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
	$travType = [System.Security.AccessControl.AccessControlType]::Allow

	# Get the root of the path
	if($Path.StartsWith("\\")) {
		$RootPath = "\\" + [string]::Join("\",$Path.Split("\")[2])
	} else {
		$RootPath = Split-Path -Path $Path -Qualifier
	}
	

	# Split up paths and pull the root
	$spath = $Path.Replace("$RootPath\", "").Split("\")
	$Paths = New-Object System.Collections.ArrayList

	# Build a list of all the directories that lead to the target directory
	for($i = 0; $i -le $spath.Length; $i++) {
		if($spath[$i] -ne $null) {
			$PathToAdd = ""
			for($j = 0; $j -le $i; $j++) {
				$PathToAdd += "$($spath[$j])\"
			}
			# Add the new path to our list of paths
			$Paths.Add("$RootPath\$PathToAdd") | Out-Null
		}
	}

	# Loop through the paths and determine which contain a traverse group
	foreach($item in $Paths) {
		$itemacl = Get-Acl -Path $item

		foreach($acl in $itemacl.Access) {
			# Check the acl for the traverse permissions defined earlier
			if(($acl.InheritanceFlags -eq $travInheritanceFlag) -and ($acl.PropagationFlags -eq $travPropagationFlag) -and ($acl.FileSystemRights -eq $travRights) -and ($acl.AccessControlType -eq $travType) -and ($acl.IsInherited -eq $false)) {
				
				# We've now found a traverse group
				$SamAccountName = $acl.IdentityReference.ToString().Split("\")[1]

				# Make sure the account name isn't null, then get the group make sure it exists in AD then add the path to the group output object.
				if($null -ne $SamAccountName) {
					$ADObject = Get-ADGroup -Identity $SamAccountName
					if($ADObject -ne $null) {
						$TraverseGroups += $ADObject | Add-Member -MemberType NoteProperty -Name TraversePath -Value $item -Force -PassThru
					}
				}
			}
		}
	}

	return $TraverseGroups
}

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