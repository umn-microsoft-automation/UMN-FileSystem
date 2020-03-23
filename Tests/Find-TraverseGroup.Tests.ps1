$TestConfig = @{
    "TestModuleName" = "UMN-FileSystem"
}

try {
    if($ModuleRoot) {
        Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force
    } else {
        if(Test-Path -Path ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force
        } elseif(Test-Path -Path .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force
        }
    }

    InModuleScope -ModuleName $TestConfig.TestModuleName {
        if($ModuleRoot) {
            . "$ModuleRoot..\Tests\StandardTestData.ps1"
        } else {
            if(Test-Path -Path "StandardTestData.ps1") {
                . .\StandardTestData.ps1
            } elseif(Test-Path -Path "Tests\StandardTestData.ps1") {
                . .\Tests\StandardTestData.ps1
            } else {
                throw "Error importing StandardTestData.ps1"
            }
        }

        Describe "Find-TraverseGroup" {
            It "Should return a traverse group when provided with a directory that has a traverse group permission" {
                Mock -CommandName Get-Acl -MockWith { return $TraverseOnlyACL }

                Find-TraverseGroup -Path "TestDrive:\FakeDirectory" | Should -Be $MockACETraverse.IdentityReference
            }

            It "Should return null if given a directory without a traverse group" {
                Mock -CommandName Get-Acl -MockWith { return $ModifyOnlyACL }

                Find-TraverseGroup -Path "TestDrive:\FakeDirectory" | Should -BeNullOrEmpty
            }

            It "Should return an error if given a directory with multiple traverse groups" {
                Mock -CommandName Get-Acl -MockWith { return $MultiTraverseACL }

                { Find-TraverseGroup -Path "TestDrive:\FakeDirectory" } | Should -Throw
            }
        }
    }
} catch {
    $Error[0]
}
