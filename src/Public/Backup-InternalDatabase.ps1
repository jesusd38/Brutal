<#
    .SYNOPSIS
    Backs up a database (COPY ONLY) using ola hallengren's scripts (http://ola.hallengren.com)

    .DESCRIPTION
    This will use Ola's scripts to backup a database to a network share. The network
    share is determined by looking for the last backup record for the database and then
    parsing out where that was told to go. The idea is that the DBA team has agent jobs
    to do the normal backup schedules and most of the time, any out-of-band backups should
    go there.

    .EXAMPLE
    Backup-InternalDatabase -DatabaseName 'AdminDB' -ServerInstance 'nhudacin160401'

    Backs up the AdminDB on my local machine to a network path. This is of course since I have Ola's stuff
    installed and I have backed up AdminDB using it before.

    .PARAMETER DatabaseName
    The name of the database to backup.


    .PARAMETER ServerInstance
    The server instance of the database to backup.
#>
function Backup-InternalDatabase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
            [string]$DatabaseName,

        [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
            [string]$ServerInstance
    )

    try {
        # need to get the backup path of the last back up in order to know which network share to put this backup
        $lastBackupPaths = Get-LastBackupPath -ServerInstance $ServerInstance -DatabaseName $DatabaseName

        # if nothing was returned, then the database wasn't backed up before. cannot move on
        if (-not $lastBackupPaths.BackupFiles) { Throw 'No commandLog record found for this database. Don''t know where to backup to' }

        $regex = ("(\\\\.*)\\$($ServerInstance.Replace('\','\$'))\\") # had to manually replace the $ sign for our cluster instances

        # make sure the network path parses out correctly
        if (-not ($lastBackupPaths.BackupFiles[0] -match $regex)) { Throw 'commandLog record WAS returned but couldn''t parse the network location' }

        $lastNetworkBackupLocation = $Matches[1]
    }
    catch {
        $msg = "There was an error getting the prior backup information on the database. Error Details: $_"
        SendLoggingEvent -EventName 'BackupInternalDatabase' -Message $msg -LogLevel 'Error'
        Throw $msg
    }

    # now it's time to backup the database
    $backupQuery = "EXECUTE [master].[dbo].[DatabaseBackup]
	                @Databases = '$DatabaseName',
	                @Directory = N'$lastNetworkBackupLocation',
	                @BackupType = 'FULL',
	                @CleanupTime = 168,
	                @CheckSum = 'Y',
	                @NumberOfFiles = $($lastBackupPaths.BackupFiles.Count),
	                @ChangeBackupType = 'Y',
	                @BufferCount = 512,
	                @MaxTransferSize = 2097152,
                    @CopyOnly = 'Y',
	                @Compress = 'Y',
	                @LogToTable = 'Y'"

    # no timeout since backups can take a LONG time
    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $backupQuery
        QueryTimeout = 0
    }

    try {
        Invoke-Sqlcmd @params
    }
    catch {
        Throw "There was an error backing up the database. Error Details: $_"
    }
}
