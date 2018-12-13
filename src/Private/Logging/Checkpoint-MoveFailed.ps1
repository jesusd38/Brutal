function Checkpoint-MoveFailed {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
            [int]$AuditRecordID,

        [Parameter(Mandatory=$true,Position=1)]
            [string]$AdminDBInstance,

        [Parameter()]
            [string]$ExceptionDetail
    )

    # need to format $ExceptionDetail to make it sql compatible
    $formatted_detail = $ExceptionDetail.Replace('''','''''').Replace("`n",'').Replace("`t",'').Replace("`r",'').Trim()

    $query = @"
        UPDATE [WORKFLOW].[DatabaseMoveAudit]
        SET [MoveStatus] = -1, [EndDate] = GETUTCDATE(), ReturnCode = 1, StackTrace = '$formatted_detail'
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
