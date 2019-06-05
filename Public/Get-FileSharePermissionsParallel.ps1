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