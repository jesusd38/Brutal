function Checkpoint-AuditStart {
<#
    Internal function to log the audit start record
    to AdminDB.
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
            [string]$DatabaseName,

        [Parameter(Mandatory=$true,Position=1)]
            [string]$SourceInstance,

        [Parameter(Mandatory=$true,Position=2)]
            [string]$TargetInstance,

        [Parameter(Mandatory=$true,Position=3)]
            [string]$AdminDBInstance
    )

    $query = @"
        INSERT INTO [WORKFLOW].[DatabaseMoveAudit] (
            DatabaseName,
            SourceInstance,
            DestinationInstance
        )

        VALUES ('$DatabaseName','$SourceInstance','$TargetInstance')

        SELECT SCOPE_IDENTITY() AS [AuditRecordID]
"@

    $params = @{
        ServerInstance = $AdminDBInstance
        Database = 'AdminDB'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $result = Invoke-Sqlcmd @params

        if (-not $result) {
            Throw 'Audit Record was not logged!'
        }

        Write-Output $result.AuditRecordID
    }
    catch {
        Throw "There was an error inserting the audit record. Error Details: $_"
    }
}
