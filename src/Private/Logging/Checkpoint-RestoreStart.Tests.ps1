$moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Checkpoint-RestoreStart' {

    $commonParameters = @{
        AuditRecordID = 1
        AdminDBInstance = 'AdminDB01'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { }

        Checkpoint-RestoreStart @commonParameters
    }

    it 'updates the record on the admindb database' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Database -eq 'AdminDB' } -Exactly 1 -Scope It
    }

    it 'executes the correct update query' {
        $query_assert = @"
        UPDATE [WORKFLOW].[DatabaseMoveAudit]
        SET [MoveStatus] = 2
        WHERE [ID] = 1
"@
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $query_assert } -Exactly 1 -Scope It
    }

    it 'updates the audit record on the adminDB instance specified' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'AdminDB01' } -Exactly 1 -Scope It
    }

    it 'throws an error when something happened while executing the query' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { Checkpoint-RestoreStart @commonParameters} |
            Should Throw 'There was an error updating the audit record. Error Details: Access Denied'
    }
  }
}
