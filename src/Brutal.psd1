@{

# Script module or binary module file associated with this manifest.
ModuleToProcess = 'Brutal.psm1'

# Version number of this module.
ModuleVersion = '2.0.5'

# ID used to uniquely identify this module
GUID = '42b82da3-f6c7-411e-b680-9d4df385a67a'

# Author of this module
Author = 'Nick Hudacin'

# Company or vendor of this module
CompanyName = 'Consilio, LLC'

# Copyright statement for this module
Copyright = 'Copyright (c) 2015 by Huron Legal Team, licensed under Apache 2.0 License.'

# Description of the functionality provided by this module
Description = 'The Brutal module automates some of the most brutal tasks managing sql server'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Functions to export from this module
FunctionsToExport = @(
    'Get-ProjectProperties',
    'Update-DatabaseIndexes',
    'Backup-InternalDatabase',
    'Update-ProjectReports',
    'Get-LastBackupPath',
    'Move-ProjectDatabases',
    'Restore-InternalDatabase',
    'Set-DatabaseReadOnly',
    'Set-DatabaseReadWrite'
)

# # Cmdlets to export from this module
# CmdletsToExport = '*'

# Variables to export from this module
#VariablesToExport = @(
#    'var1',
#    'var2'
#)

# # Aliases to export from this module
# AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

PrivateData = @{
    # PSData is module packaging and gallery metadata embedded in PrivateData
    # It's for rebuilding PowerShellGet (and PoshCode) NuGet-style packages
    # We had to do this because it's the only place we're allowed to extend the manifest
    # https://connect.microsoft.com/PowerShell/feedback/details/421837
    PSData = @{
        # The primary categorization of this module (from the TechNet Gallery tech tree).
        Category = 'Scripting Techniques'

        # Keyword tags to help users find this module via navigations and search.
        Tags = @('powershell','SQL','SQLServer','Database','Server')

        # The web address of an icon which can be used in galleries to represent this module
        #IconUri = "http://pesterbdd.com/images/Pester.png"

        # The web address of this module's project or support homepage.
        ProjectUri = 'https://github.consilio.com/CID/Brutal'

        # The web address of this module's license. Points to a page that's embeddable and linkable.
        LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0.html'

        # Release notes for this particular version of the module
        # ReleaseNotes = False

        # If true, the LicenseUrl points to an end-user license (not just a source license) which requires the user agreement before use.
        # RequireLicenseAcceptance = ""

        # Indicates this is a pre-release/testing version of the module.
        IsPrerelease = 'False'
    }
}

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}