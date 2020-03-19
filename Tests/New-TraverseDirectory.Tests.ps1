$TestConfig = @{
    "TestModuleName" = "UMN-FileSystem"
}

try {
    if ($ModuleRoot) {
        Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force
    }
    else {
        if (Test-Path -Path ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force    
        }
        elseif (Test-Path -Path .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force
        }
    }

    # Module scope fixes problems with AD mocking.  It needs to be here to fix issues with running
    # tests on devices without AD module installed.
    InModuleScope -ModuleName $TestConfig.TestModuleName {
        if ($ModuleRoot) {
            . "$ModuleRoot..\Tests\StandardTestData.ps1"
        }
        else {
            if (Test-Path -Path "StandardTestData.ps1") {
                . .\StandardTestData.ps1
            }
            elseif (Test-Path -Path "Tests\StandardTestData.ps1") {
                . .\Tests\StandardTestData.ps1
            }
            else {
                throw "Error importing StandardTestData.ps1"
            }
        }
        Describe "New-TraverseFolder" {
            Mock New-ADGroup { return $true }

            Context "New Folder Creation" {
                It "Should not error on a folder that doesn't exist" {
                    { New-TraverseDirectory -Path "TestDrive:\Blah" -Name "Test" -TraverseGroupName "Test" -TraverseGroupOU "Test" } | Should not throw
                }

                It "Should throw an error if the folder exists aldready" {
                    New-Item -Path "TestDrive:\Blah" -Name "Test" -ItemType Directory -Force
                    { New-TraverseDirectory -Path "TestDrive:\Blah" -Name "Test" -TraverseGroupName "Test" -TraverseGroupOU "Test" } | Should throw
                }
            }
        }
    }
}
catch {
    $Error[0]
}
