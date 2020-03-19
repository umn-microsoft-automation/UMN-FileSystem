param ($task = "Default")

# Grab nuget buits, install modules, set build variables, start build.

# Make sure package provider is installed (required for Docker support)
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.201" -Force

# Pester is already installed, need to skip this check.
Install-Module -Name "Pester" -Force -SkipPublisherCheck

Install-Module -Name "Psake", "PSDeploy", "BuildHelpers" -Force
Import-Module "Psake", "BuildHelpers" -Force

# Write out directory files.
(Get-ChildItem).FullName | Write-Warning

Set-BuildEnvironment
Invoke-Psake -buildFile .\Build\psake.ps1 -taskList $task -nologo

exit([int](-not $psake.build_success))
