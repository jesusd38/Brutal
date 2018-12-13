<#
    .SYNOPSIS
    Restores a database to a server

    .DESCRIPTION
    Use this function to restore a database from the backup files returned in Get-LastBackupPath. This function will try to determine
    which lun to place the database files on by querying the server for the least amount of spaced used, partitioned by luns. If no data
    or log luns are returned, then the server default paths are used.

    .EXAMPLE
    $lastBackupPaths = Get-LastBackupPath -ServerInstance 'Test' -DatabaseName 'TestDB'
    Restore-InternalDatabase -DatabaseName 'TestDB' -ServerInstance 'Target' -BackupFiles $lastBackupPaths.BackupFiles

    Will restore database 'TestDB' from the last backups found on server 'Test' to the new target server 'Target'

    .PARAMETER DatabaseName
    The name of the database to restore

    .PARAMETER ServerInstance
    The server instance to restore the database to.

    .PARAMETER BackupFiles
    The backup files associated with the last backup.
#>
function Restore-InternalDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
            [string]$DatabaseName,

        [Parameter(Mandatory=$true,Position=1)]
            [string]$ServerInstance,

        [Parameter(Mandatory=$true,Position=2,ValueFromPipelineByPropertyName=$true)]
            [string[]]$BackupFiles
    )

    # get the file list from the backup files
    $fileList = RestoreFileListOnly -ServerInstance $ServerInstance -BackupFiles $BackupFiles

    # get the target restore paths
    $targetRestorePaths = GetRestoreTargetPaths -ServerInstance $ServerInstance

    # build the restore query
    $query = "RESTORE DATABASE [$DatabaseName] FROM`n"

    foreach($file in $BackupFiles) {
        $query += "DISK = N'$file'"

        # skip the comma on the last one
        if ($BackupFiles.IndexOf($file) -eq ($BackupFiles.Count -1)) {
            $query += "`n"
        }
        else {
            $query += ",`n"
        }
    }

    $query += "WITH FILE = 1,"

    foreach($physicalFile in $fileList) {

        # get the file name
        $fileName = Split-Path $physicalFile.PhysicalName -Leaf

        # set the new logical paths
        if ($physicalFile.Type -eq 'L') {
            $newPath = $targetRestorePaths.TargetLogPath + $fileName
        }
        else {
            $newPath = $targetRestorePaths.TargetDataPath + $fileName
        }

        $query += "MOVE N'$($physicalFile.LogicalName)' TO N'$newPath',`n"
    }

    $query += "NOUNLOAD, STATS = 5"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
        QueryTimeout = 0
    }

    try {
        Invoke-Sqlcmd @params
    }
    catch {
        $msg = "$($MyInvocation.MyCommand.Name): There was an error restoring the database. Error Details: $_"
        SendLoggingEvent -EventName 'RestoreInternalDatabase' -Message $msg -LogLevel 'Error'
        Throw $msg
    }
}
