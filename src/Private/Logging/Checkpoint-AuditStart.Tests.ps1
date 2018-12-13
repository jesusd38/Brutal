$moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Import-Module "$moduleRoot\Brutal.psm1" -Force

## SqlPs Module Needed
$current_location = (Get-Location).Path
Import-Module SqlPs -DisableNameChecking
Set-Location $current_location

InModuleScope Brutal {

  Describe 'Checkpoint-AuditStart' {
    $commonParams = @{
        DatabaseName = 'UnitTestDB'
        SourceInstance = 'Source01'
        TargetInstance = 'Dest01'
        AdminDBInstance = 'AdminDB01'
    }

    beforeEach {
        Mock Invoke-Sqlcmd {
            return @{
                AuditRecordID = 1
            }
        }
    }

    it 'returns the audit id record' {
        Checkpoint-AuditStart @commonParams | Should Be 1
    }

    it 'logs the record to the admindb database' {
        Checkpoint-AuditStart @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Database -eq 'AdminDB' } -Exactly 1 -Scope It
    }

    it 'inserts the correct information into the audit record' {
        Checkpoint-AuditStart @commonParams
        $query_assert = @"
        INSERT INTO [WORKFLOW].[DatabaseMoveAudit] (
            DatabaseName,
            SourceInstance,
            DestinationInstance
        )

        VALUES ('UnitTestDB','Source01','Dest01')

        SELECT SCOPE_IDENTITY() AS [AuditRecordID]
"@
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $query_assert } -Exactly 1 -Scope It
    }

    it 'logs the audit record to the adminDB instance specified' {
        Checkpoint-AuditStart @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'AdminDB01' } -Exactly 1 -Scope It
    }

    it 'throws an error when nothing is returned from the server' {
        Mock Invoke-Sqlcmd { return $null }
        { Checkpoint-AuditStart @commonParams } |
            Should Throw 'There was an error inserting the audit record. Error Details: Audit Record was not logged!'
    }

    it 'throws an error when something happened while executing the query' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { Checkpoint-AuditStart @commonParams } |
            Should Throw 'There was an error inserting the audit record. Error Details: Access Denied'
    }
  }
}
