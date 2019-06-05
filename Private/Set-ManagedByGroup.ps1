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

function Set-ManagedByGroup {
    [CmdletBinding()]
    param(
        [string]$ADGroupName,
        [string]$ADManagerGroupName,
        [string]$TargetDC = (Get-ADDomainController).HostName
    )
    
    $ADGroup = Get-ADGroup -Identity $ADGroupName -Server $TargetDC
    $ADObject = [adsi]"LDAP://$TargetDC/$($ADGroup.DistinguishedName)"

    $ManagedByADGroup = Get-ADGroup -Identity $ADManagerGroupName -Server $TargetDC

    $ManagerIdentityRef = $ManagedByADGroup.SID.Value
    $SID = New-Object System.Security.Principal.SecurityIdentifier($ManagerIdentityRef)

    $ADRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($SID, [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty, [System.Security.AccessControl.AccessControlType]::Allow,[guid]"bf9679c0-0de6-11d0-a285-00aa003049e2")
    
    $ADObject.InvokeSet("managedBy", @("$($ManagedByADGroup.DistinguishedName)"))
    $ADObject.CommitChanges()

    # Taken from here: http://blogs.msdn.com/b/dsadsi/archive/2013/07/09/setting-active-directory-object-permissions-using-powershell-and-system-directoryservices.aspx
    [System.DirectoryServices.DirectoryEntryConfiguration]$SecurityOptions = $ADObject.get_Options()
    $SecurityOptions.SecurityMasks = [System.DirectoryServices.SecurityMasks]'Dacl'

    $ADObject.get_ObjectSecurity().AddAccessRule($ADRule)
    $ADObject.CommitChanges()
}