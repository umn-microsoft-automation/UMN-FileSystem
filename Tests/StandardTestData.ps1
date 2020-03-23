$MockACETraverse = @{
    "IdentityReference" = "TraverseUser"
    "FileSystemRights" = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute,Synchronize"
	"InheritanceFlags" = [System.Security.AccessControl.InheritanceFlags]::None
	"PropagationFlags" = [System.Security.AccessControl.PropagationFlags]::None
    "AccessControlType" = [System.Security.AccessControl.AccessControlType]::Allow
    "IsInherited" = $false
}

$MockACESecondTraverse = @{
    "IdentityReference" = "SecondTraverseUser"
    "FileSystemRights" = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute,Synchronize"
    "InheritanceFlags" = [System.Security.AccessControl.InheritanceFlags]::None
    "PropagationFlags" = [System.Security.AccessControl.PropagationFlags]::None
    "AccessControlType" = [System.Security.AccessControl.AccessControlType]::Allow
    "IsInherited" = $false
}

$MockACEModify = @{
    "IdentityReference" = "ModifyUser"
    "FileSystemRights" = [System.Security.AccessControl.FileSystemRights]::Modify
	"InheritanceFlags" = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
	"PropagationFlags" = [System.Security.AccessControl.PropagationFlags]::None
	"AccessControlType" = [System.Security.AccessControl.AccessControlType]::Allow
}

$MockACEDenyDelete = @{
    "IdentityReference" = "ModifyUser"
    "FileSystemRights" = [System.Security.AccessControl.FileSystemRights]::Delete
    "InheritanceFlags" = [System.Security.AccessControl.InheritanceFlags]::None
    "PropagationFlags" = [System.Security.AccessControl.PropagationFlags]::None
    "AccessControlType" = [System.Security.AccessControl.AccessControlType]::Deny
}

$MockACERead = @{
    "IdentityReference" = "ReadUser"
    "FileSystemRights" = [System.Security.AccessControl.FileSystemRights]"ReadAndExecute,Synchronize"
	"InheritanceFlags" = [System.Security.AccessControl.InheritanceFlags]::None
	"PropagationFlags" = [System.Security.AccessControl.PropagationFlags]::None
	"AccessControlType" = [System.Security.AccessControl.AccessControlType]::Allow
}


$TraverseOnlyACL = @{
    "Access" = @($MockACETraverse)
}

$MultiTraverseACL = @{
    "Access" = @($MockACETraverse, $MockACESecondTraverse)
}

$ModifyOnlyACL = @{
    "Access" = $MockACEModify
}

$ModifyWithDeleteACL = @{
    "Access" = @($MockACEModify, $MockACEDenyDelete)
}

$ReadOnlyACL = @{
    "Access" = $MockACERead
}

$SharePermsACL = @{
    "Access" = @($MockACEModify, $MockACEDenyDelete, $MockACERead)
}
