<#
    Script to move all US projects marked with a status of 9 (data disp)
    to our data disp server (MLVPDPRJ01) if they haven't already been moved.
#>

$AdminDBInstance = 'MTPVPDSQLP06\PROJP11'

# requires Brutal Module
Import-Module Brutal

# find any data disp projects that have not been moved over to the data disp server. 
# criteria = Project.DomainProjectStatusID = 9; Project.ServerName NOT IN ('MLVPDPRJ01','HLUKSQLENGP11\PROJP11')
# have to ignore data disp projects in the UK for now. 
$query = "
    SELECT p.ProjectCode
    FROM ADMIN.Project p
    WHERE p.DomainProjectStatusID = 9 AND p.DatabaseServer NOT IN ('MLVPDPRJ01','HLUKSQLENGP11\PROJP11')"

$params = @{
    ServerInstance = $AdminDBInstance
    Database = 'AdminDB'
    OutputSqlErrors = $true
    ErrorAction = 'Stop'
    Query = $query
}

$dispProjects_notMoved = Invoke-Sqlcmd @params

# now we iterate over them and move each to the data disp server
foreach($Project in $dispProjects_notMoved) { 
    
    try {
        # Move the project databases
        Move-ProjectDatabases -ProjectCode $Project.ProjectCode -TargetInstance 'MLVPDPRJ01' -AdminDBInstance 'MTPVPDSQLP06\PROJP11' -Verbose

        # Need to set the databases to read only - Get the project properties which should say the 
        # new location and for each of the databases, set them to read-only
        $_props = Get-ProjectProperties $Project.ProjectCode

        foreach($db in $_props.ProjectDatabases) {
            Set-DatabaseReadOnly -DatabaseName $db -ServerInstance $_props.ProjectServer
        }
    }
    catch {
        Throw
    }
}
