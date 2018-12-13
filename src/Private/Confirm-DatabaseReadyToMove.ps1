function Confirm-DatabaseReadyToMove {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
            [string]$DatabaseName,

        [Parameter(Mandatory=$true,Position=1)]
            [string]$SourceInstance,

        [Parameter(Mandatory=$true,Position=2)]
            [string]$AdminDBInstance,

        [Parameter(Mandatory=$true,Position=3)]
            [int]$AuditRecordID
    )

    Write-Verbose "$($MyInvocation.MyCommand.Name): Confirming database is ready to move..."

    # common parameters
    $params = @{
        ServerInstance = $SourceInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
    }

    # validation flags
    $flags = @()

    try {
        # ensure the database exists
        $databaseCount = Invoke-Sqlcmd @params -Query "SELECT COUNT(*) as [Count] FROM sys.databases WHERE name = '$DatabaseName'"

        if ($databaseCount.Count -ne 1) { Throw "There was no database to move on the server" }

        # set the exists validation flag
        $flags += 2

        # ensure no open connections exist
        $connectionCount = Invoke-Sqlcmd @params -Query "SELECT COUNT(dbid) AS [Count] FROM sys.sysprocesses WHERE DB_NAME(dbid) = '$DatabaseName'"

        if ($connectionCount.Count -ne 0) { Throw "There are connections to this database, cannot move it at this time." }

        # set the no open connections validation flag
        $flags += 4

        # ensure it's not in single_user mode
        $databaseState = Invoke-Sqlcmd @params -Query "SELECT user_access_desc AS [State] FROM sys.databases WHERE name = '$DatabaseName'"

        if ($databaseState.State -ne 'MULTI_USER') { Throw "The database is not in MULTI_USER state" }

        # set the database state validation flag
        $flags += 8

        # if we've made it this far, simply returning $true will indicate that the database is ready to move
        Write-Output $true
    }
    catch {
        Throw "There was an error confirming the database state. Error Details: $_"
    }
    finally {
        # pass or fail, set the validation flags in the audit table
        if ($flags.Count -gt 0) {
            Set-ValidationFlag -Flags $flags -AuditRecordID $AuditRecordID -AdminDBInstance $AdminDBInstance
        }
    }
}
