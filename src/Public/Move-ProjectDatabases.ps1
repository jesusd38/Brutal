<#
    .SYNOPSIS
    Moves all databases connected to a project to a different server

    .DESCRIPTION
    Use this function to move all project databases (EDD, ETL, & FR if exists) to another project server. IMPORTANT - THIS IS A MOVE, NOT A
    COPY!! This will relocate project databases permanently.

    .EXAMPLE
    Move-ProjectDatabases -ProjectCode H11824 -TargetInstance 'MLVPDPRJ01' -AdminDBInstance 'MTPVPDSQLP06\PROJP11' -Verbose

    Will move project databases for H11824 from the instance reported in the AdminDB on 'MTPVPDSQLP06\PROJP11' to 'MLVPDPRJ01' and update
    the project references in AdminDB to 'MLVPDPRJ01'.

    .PARAMETER ProjectCode
    The project code to relocate.

    .PARAMETER TargetInstance
    The target instance of the project databases.

    .PARAMETER AdminDBInstance
    The AdminDB Server Instance that is used to lookup the project information.
#>
function Move-ProjectDatabases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
            [string[]]$ProjectCode,

        [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
            [string]$TargetInstance,

        [Parameter(Position=2,ValueFromPipelineByPropertyName=$true)]
            [string]$AdminDBInstance = 'MTPVPDSQLP06\PROJP11'
    )

    process {
        foreach($pc in $ProjectCode) {

            # this is an all-or-nothing move. Store the number of databases successfully moved to make
            # sure it matches the total number of project databases. If not, don't update anything!
            $completedCount = 0

            try {

                # Get the project properties
                $projectProperties = Get-ProjectProperties $pc

                # if a forensics database is found, need to update adminDB differently
                $frProject = $false

                # for each of the project databases, backup & restore them to the target instance
                foreach($db in $($projectProperties.ProjectDatabases)) {

                    # check to see if it's an FR project
                    if ($db.EndsWith('_FR')) {
                        $frProject = $true
                    }

                    # log the audit start record
                    $auditRecordId = Checkpoint-AuditStart -DatabaseName $db -SourceInstance $projectProperties.ProjectServer -TargetInstance $TargetInstance -AdminDBInstance $AdminDBInstance

                    try {
                        # ensure database is ready to roll
                        # this procedure will throw an exception if the database is not ready.
                        Confirm-DatabaseReadyToMove -DatabaseName $db -SourceInstance $projectProperties.ProjectServer -AdminDBInstance $AdminDBInstance -AuditRecordID $auditRecordId | Out-Null

                        # log that the backup process is starting
                        Checkpoint-BackupStart -AuditRecordID $AuditRecordID -AdminDBInstance $AdminDBInstance

                        # Set database to read-only to prevent writes during the move
                        Set-DatabaseReadOnly -DatabaseName $db -ServerInstance $projectProperties.ProjectServer

                        # cut the final full backup
                        Backup-InternalDatabase -DatabaseName $db -ServerInstance $projectProperties.ProjectServer

                        # get those backup paths to restore from
                        $lastBackupPaths = Get-LastBackupPath -ServerInstance $projectProperties.ProjectServer -DatabaseName $db

                        # log the restore process is starting
                        Checkpoint-RestoreStart -AuditRecordID $auditRecordID -AdminDBInstance $AdminDBInstance

                        # restore the database from the last known backup
                        Restore-InternalDatabase -DatabaseName $db -ServerInstance $TargetInstance -BackupFiles $lastBackupPaths.BackupFiles

                        # set the database to read/write
                        Set-DatabaseReadWrite -DatabaseName $db -ServerInstance $TargetInstance

                        # log that the move process has completed succesfully
                        Checkpoint-MoveComplete -AuditRecordID $auditRecordId -AdminDBInstance $AdminDBInstance

                        # up the completed counter
                        $completedCount = $completedCount + 1
                    }

                    catch {
                        # log the the move process failed
                        SendLoggingEvent -EventName 'MoveProjectDatabases' -Message $_ -LogLevel 'Error'
                        Checkpoint-MoveFailed -AuditRecordID $AuditRecordID -AdminDBInstance $AdminDBInstance -ExceptionDetail $_
                        Throw
                    }
                }

                if ($frProject) {
                    UpdateProjectProperties -AdminDBInstance $AdminDBInstance -ProjectID $projectProperties.ProjectID -DatabaseServer $TargetInstance -ProjectType FR
                }
                else {
                    UpdateProjectProperties -AdminDBInstance $AdminDBInstance -ProjectID $projectProperties.ProjectID -DatabaseServer $TargetInstance -ProjectType EDD
                }

                # verify the AdminDB connection string
                $newProjectProperties = Get-ProjectProperties $pc

                if ($newProjectProperties.ProjectServer -ne $TargetInstance) {
                    Throw "There is a very random error where adminDB isn't returning the expected server."
                }

                # verify the databases are up and online
                foreach($db in $projectProperties.ProjectDatabases) {
                    $dbState = GetDatabaseStatus -ServerInstance $TargetInstance -DatabaseName $db

                    if (($dbState.UserAccess -ne 'MULTI_USER') -or ($dbState.ReadOnly) -or ($dbState.State -ne 'ONLINE')) {
                        Throw "The database is not in the correct state. Rolling back..."
                    }
                }

                # remove the database from the source server
                # verify the databases are up and online
                foreach($db in $projectProperties.ProjectDatabases) {
                    DropDatabase -ServerInstance $projectProperties.ProjectServer -DatabaseName $db
                }
            }
            catch {
                # if more than one databases were moved, set the ORIGINAL database to read-write, cleanup the TARGET instance databases
                if ($completedCount -gt 0) {
                    foreach($db in $($projectProperties.ProjectDatabases)) {
                         $dbState = GetDatabaseStatus -ServerInstance $projectProperties.ProjectServer -DatabaseName $db

                         if ($dbState.ReadOnly) {
                            Set-DatabaseReadWrite -ServerInstance $projectProperties.ProjectServer -DatabaseName $db
                         }

                         # if exists on the target, drop it
                         $targetDBState = GetDatabaseStatus -ServerInstance $TargetInstance -DatabaseName $db

                         if ($targetDBState) {
                            DropDatabase -ServerInstance $TargetInstance -DatabaseName $db
                         }
                    }

                    # update the adminDB connection string
                    if ($frProject) {
                        UpdateProjectProperties -AdminDBInstance $AdminDBInstance -ProjectID $projectProperties.ProjectID -DatabaseServer $projectProperties.ProjectServer -ProjectType FR
                    }
                    else {
                        UpdateProjectProperties -AdminDBInstance $AdminDBInstance -ProjectID $projectProperties.ProjectID -DatabaseServer $projectProperties.ProjectServer -ProjectType EDD
                    }
                }
                Throw
            }
        }
    }
}
