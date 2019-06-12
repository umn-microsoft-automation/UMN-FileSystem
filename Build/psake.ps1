# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $Env:BHProjectPath
    $ModuleRoot = $Env:BHModulePath
    $ModuleName = $Env:BHProjectName

    if(-not $ProjectRoot) {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
    }

    $Timestamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$Timestamp.xml"
    $CodeCoverageFile = "CodeCoverage_PS$PSVersion`_$Timestamp.xml"
    $Lines = '----------------------------------------------------------------------'

    [hashtable]$Verbose = @{}
    if($Env:BHCommitMessage -match "!verbose") {
        $Verbose = @{Verbose = $true}
    }
}

Task Default -Depends Test

Task Init {
    $Lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item Env:BH*
    "`n"
}

Task Test -Depends Init {
    $Lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Testing links on GitHub requires tls >= 1.2
    $SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Warning "Project Root: $ProjectRoot"
    Write-Warning "Module Root: $ModuleRoot"
    Write-Warning "Module Name: $ModuleName"

    if($Env:BHCommitMessage -notmatch "!skipcodecoverage") {
        $CodeToCheck = Get-ChildItem $ModuleRoot -Include *.ps1, *.psm1 -Recurse
        $CodeCoverageParams = @{
            CodeCoverageOutputFile = "$ProjectRoot\Build\$CodeCoverageFile"
            CodeCoverage = $CodeToCheck
        }
    } else {
        $CodeCoverageParams = @{}
    }

    Import-Module $ModuleRoot

    # Gather test results. Store them in a variable and file
    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\Build\$TestFile" @CodeCoverageParams @Verbose
    [Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

    # In Appveyor? Upload our tests!
    if($Env:BHBuildSystem -eq 'AppVeyor') {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($Env.APPVEYOR_JOB_ID)",
            "$ProjectRoot\Build\$TestFile"
        )
    }

    # Failed Tests?
    # Need to tell psake or it will proceed to the deployment.  Danger!
    if($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed."
    }
    "`n"
}

Task Build -Depends Test {

}