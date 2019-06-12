param ($Task = 'Default')

# Grab nuget bits, install modules, set build variables, start build.

Install-Module Psake, PSDeploy, BuildHelpers, Pester -Force
Import-Module Psake, BuildHelpers

Set-BuildEnvironment

Invoke-Psake -BuildFile .\Build\psake.ps1 -TaskList $Task -NoLogo

exit ([int]( -not $psake.build_success))