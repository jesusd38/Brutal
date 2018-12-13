function Set-ValidationFlag {
<#
    Internal LOGGING function that sets any flag value
    you want on an audit record. Accepts multiple values

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0, ValueFromPipeline=$true)]
            [int[]]$Flags,

        [Parameter(Mandatory=$true,Position=1)]
            [int]$AuditRecordID,

        [Parameter(Mandatory=$true,Position=2)]
            [string]$AdminDBInstance
    )

    begin {
        $query = ""
    }

    process {
        foreach ($flag in $Flags) {
            $query += "UPDATE [WORKFLOW].[DatabaseMoveAudit] SET [ValidationChecks] = [ValidationChecks] ^ $flag WHERE [ID] = $AuditRecordID AND [ValidationChecks] & $flag = 0;`n"
        }
    }

    end {

        Write-Verbose "$($MyInvocation.MyCommand.Name): Updating the validation flags for ID:$AuditRecordID..."

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
            Throw "There was an error setting the validation flags. Error Details: $_"
        }
    }
}
