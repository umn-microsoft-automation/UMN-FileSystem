Import-Module $PSScriptRoot\..\UMN-FileSystem.psm1 -Force

Describe "Import-Module UMN-FileSystem.psm1" {
    Context "Module Exports" {
        It "Should export at least one function" {
            @(Get-Command -Module UMN-FileSystem).Count | Should BeGreaterThan 0
        }
    }
}