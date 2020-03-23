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

        Describe "Find-TraverseGroups" {
            It "Should return multiple values if given AD traverse groups in the path (with domain)." {
                Mock -CommandName Get-Acl -MockWith { return $TraverseOnlyACL }
                Mock -CommandName Get-ADGroup -MockWith { return $FakeADTraverseGroupWithDomain }

                Find-TraverseGroups -Path "TestDrive:\First\Second\ThirdFakeDirectories" | Should -Not -BeNullOrEmpty
            }

            It "Should return multiple values if given AD traverse groups in the path (without domain)." {
                Mock -CommandName Get-Acl -MockWith { return $TraverseOnlyACL }
                Mock -CommandName Get-ADGroup -MockWith { return $FakeLocalTraverseGroupWithoutDomain }

                Find-TraverseGroups -Path "TestDrive:\First\Second\ThirdFakeDirectories" | Should -Not -BeNullOrEmpty
            }

            It "Should return nothing if given no traverse groups in the path." {
                Mock -CommandName Get-Acl -MockWith { return $SharePermsACL }
                Mock -CommandName Get-ADGroup -MockWith { return $FakeADTraverseGroup }

                Find-TraverseGroups -Path "\\Not\a\real\fileshare" | Should -BeNullOrEmpty
            }
        }
    }
} catch {
    $Error[0]
}
