Import-Module $PSScriptRoot\..\UMN-FileSystem.psm1 -Force

Describe "Import-Module UMN-FileSystem.psm1" {
    It "Should export at least one function" {
        @(Get-Command -Module UMN-FileSystem).Count | Should BeGreaterThan 0
    }
}

Describe "General project validation" {
 
    $scripts = Get-ChildItem ..\ -Include *.ps1, *.psm1, *.psd1 -Recurse
    $predicate = {
        param ( $ast )
 
        if ($ast -is [System.Management.Automation.Language.BinaryExpressionAst] -or
            $ast -is [System.Management.Automation.Language.CommandParameterAst] -or
            $ast -is [System.Management.Automation.Language.AssignmentStatementAst]) {
 
            if ($ast.ErrorPosition.Text[0] -in 0x2013, 0x2014, 0x2015) { return $true }
             
        }
        if ($ast -is [System.Management.Automation.Language.CommandAst] -and
            $ast.GetCommandName() -match '\u2013|\u2014|\u2015') { return $true }
 
        if (($ast -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                $ast -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) -and
            $ast.Parent -is [System.Management.Automation.Language.CommandExpressionAst]) {
            if ($ast.Parent -match '^[\u2018-\u201e]|[\u2018-\u201e]$') { return $true }
        }
    }
 
    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object { @{file = $_ } }         
    It "Script <file> should be valid powershell" -TestCases $testCase {
        param (
            $file
        )
        $script = Get-Content -Raw -Encoding UTF8 -Path $file
        $tokens = $errors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Script, [Ref]$tokens, [Ref]$errors)
        $elements = $ast.FindAll($predicate, $true)
 
        $elements | Should -BeNullOrEmpty -Because $elements
    }
}