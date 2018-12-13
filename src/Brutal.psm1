# Brutal
# Version: $version$
# Changeset: $sha$

## SqlPs Module Needed
$current_location = (Get-Location).Path
Import-Module SqlPs -DisableNameChecking
Set-Location $current_location

# if debugging, set moduleRoot to current directory
if ($MyInvocation.MyCommand.Path) {
    $moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
}else {
    $moduleRoot = $PWD.Path
}

# Load up the dependent functions
"$moduleRoot\Public\*.ps1", 
"$moduleRoot\Private\*.ps1",
"$moduleRoot\Private\Logging\*.ps1" |
    Resolve-Path |
        Where-Object { -not ($_.ProviderPath.ToLower().Contains('.tests.')) } |
            ForEach-Object { . $_.ProviderPath }

# Export the public functions
Export-ModuleMember Backup-InternalDatabase, Get-ProjectProperties, Update-DatabaseIndexes, Update-ProjectReports
Export-ModuleMember Get-LastBackupPath, Move-ProjectDatabases, Restore-InternalDatabase
Export-ModuleMember Set-DatabaseReadOnly, Set-DatabaseReadWrite