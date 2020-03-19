@{
    RootModule        = 'UMN-FileSystem.psm1'
    ModuleVersion     = '0.0.1'
    GUID              = 'bd4390dc-a8ad-4bce-8d69-f53ccf8e4163'
    Author            = 'Jeff Bolduan'
    CompanyName       = 'University of Minnesota'
    Copyright         = '(c) 2016 University of Minnesota. All rights reserved.'
    Description       = 'Window FileSystem functions'
    PowerShellVersion = '5.0'
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        Tags                       = @("Automation", "Windows", "Active Directory", "Fileshare", "AD", "UMN")
        LicenseUri                 = 'https://github.com/umn-microsoft-automation/UMN-FileSystem/blob/master/LICENSE'
        ProjectUri                 = 'https://github.com/umn-microsoft-automation/UMN-FileSystem'
        # IconUri = ''
        ReleaseNotes               = 'https://github.com/umn-microsoft-automation/UMN-FileSystem/releases/latest'
        ExternalModuleDependencies = @("ActiveDirectory", "NTFSSecurity", "UMN-ActiveDirectory")
    }
}
