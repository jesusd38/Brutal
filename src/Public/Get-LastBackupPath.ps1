<#
    .SYNOPSIS
    Retrieves a databases last backup file(s)

    .DESCRIPTION
    Use this function to retrieve a database's last backup set, containing 1 - n files. The last backup set is pulled from
    Ola's command log table in the master database, so you must have read access to that.

    .EXAMPLE
    Get-LastBackupPath -ServerInstance 'MTPVPDSQLP06\PROJP11' -DatabaseName 'AdminDB'

    Will return the last backup path from AdminDB:

    DatabaseName BackupFiles
    ------------ -----------
    AdminDB      {\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\AdminDB\FULL\MTPVPDSQLP06$PROJP11_AdminDB_FULL_...

    .PARAMETER ServerInstance
    The server to query the command log on

    .PARAMETER DatabaseName
    The database name to lookup in the command log
#>
function Get-LastBackupPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
            [string]$ServerInstance,

        [Parameter(Mandatory=$true)]
            [string]$DatabaseName
    )

    $query = "
        SELECT TOP 1 Command
        FROM CommandLog
        WHERE   DatabaseName = '$DatabaseName' AND
                CommandType = 'BACKUP_DATABASE' AND
                ErrorNumber = 0 AND
                Command LIKE '%\FULL%'
        ORDER BY ID DESC"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $results = Invoke-Sqlcmd @params

        # output file(s) object
        $outputFiles = @()

        # now need to parse out the backup command
        [regex]::Matches($($results.Command),"DISK = N'(\S*)[']") |
            %{
                $outputFiles += $_.Groups[1].Value
            }

        # create the return object
        $properties = @{
            DatabaseName = $DatabaseName
            BackupFiles = $outputFiles
        }

        $return_object = New-Object -TypeName PSObject -Property $properties

        Write-Output $return_object
    }
    catch {
        $msg = "$($MyInvocation.MyCommand.Name): Could not retrieve backup files. Error Details: $_"
        SendLoggingEvent -EventName 'Get-LastBackupPath' -Message $msg -LogLevel 'Error'
        Throw $msg
    }
}
