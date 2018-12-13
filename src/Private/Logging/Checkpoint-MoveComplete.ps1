function Checkpoint-MoveComplete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
            [int]$AuditRecordID,
        [Parameter(Mandatory=$true,Position=1)]
            [string]$AdminDBInstance
    )

    $query = @"
        UPDATE [WORKFLOW].[DatabaseMoveAudit]
        SET [MoveStatus] = 3, [EndDate] = GETUTCDATE(), ReturnCode = 0
        WHERE [ID] = $AuditRecordID
"@

    $params = @{
        ServerInstance = $AdminDBInstance
        Database = 'AdminDB'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        Invoke-Sqlcmd @params
    }
    catch {
        Throw "There was an error updating the audit record. Error Details: $_"
    }
}
