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
        Describe "Help tests for $moduleName" -Tags 'Build' {
    
            $functions = Get-Command -Module $moduleName -CommandType Function
            foreach ($Function in $Functions) {
                $help = Get-Help $Function.name
                Context $help.name {
                    #it "Has a HelpUri" {
                    #    $Function.HelpUri | Should Not BeNullOrEmpty
                    #}
                    #It "Has related Links" {
                    #    $help.relatedLinks.navigationLink.uri.count | Should BeGreaterThan 0
                    #}
                    it "Has a description" {
                        $help.description | Should Not BeNullOrEmpty
                    }
                    it "Has an example" {
                        $help.examples | Should Not BeNullOrEmpty
                    }
                    foreach ($parameter in $help.parameters.parameter) {
                        if ($parameter -notmatch 'whatif|confirm') {
                            it "Has a Parameter description for '$($parameter.name)'" {
                                $parameter.Description.text | Should Not BeNullOrEmpty
                            }
                        }
                    }
                }
            }
        }
    }
}
catch {
    $Error[0]
}
