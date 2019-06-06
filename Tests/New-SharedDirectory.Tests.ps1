Import-Module $PSScriptRoot\..\UMN-FileSystem.psm1 -Force

Describe "New-SharedDirectory" {
    Mock New-ADGroup { return $true }

    Context "New Folder Creation" {
        It "Should not error on a folder that doesn't exist" {
            { New-SharedDirectory -Path "TestDrive:\Blah" -Name "Test" -TraverseGroupName "Test" -TraverseGroupOU "Test" } | Should not throw
        }

        It "Should throw an error if the folder exists aldready" {
            New-Item -Path "TestDrive:\Blah" -Name "Test" -ItemType Directory -Force
            { New-SharedDirectory -Path "TestDrive:\Blah" -Name "Test" -TraverseGroupName "Test" -TraverseGroupOU "Test" } | Should throw
        }
    }
}