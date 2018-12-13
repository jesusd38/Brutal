$moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Checkpoint-MoveFailed' {

    $commonParameters = @{
        AuditRecordID = 1
        AdminDBInstance = 'AdminDB01'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { }
        Checkpoint-MoveFailed @commonParameters -ExceptionDetail 'Test'
    }

    $Query_Assert = @"
        UPDATE [WORKFLOW].[DatabaseMoveAudit]
        SET [MoveStatus] = -1, [EndDate] = GETUTCDATE(), ReturnCode = 1, StackTrace = 'Test'
        WHERE [ID] = 1
"@

    it 'updates the audit record correctly' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $Query_Assert } -Exactly 1 -Scope It
    }

    it 'updates the admindb instance' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'AdminDB01' } -Exactly 1 -Scope It
    }

    it 'updates the admindb database' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Database -eq 'AdminDB' } -Exactly 1 -Scope It
    }

    it 'throws an error when something happens' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }

        { Checkpoint-MoveFailed @commonParameters -ExceptionDetail 'Test' } |
            Should Throw 'There was an error updating the audit record. Error Details: Access Denied'
    }

    it 'accepts exception data types' {

        Mock Invoke-Sqlcmd { return $Query }

        $Query_Assert2 = @"
        UPDATE [WORKFLOW].[DatabaseMoveAudit]
        SET [MoveStatus] = -1, [EndDate] = GETUTCDATE(), ReturnCode = 1, StackTrace = 'This is an exception'
        WHERE [ID] = 1
"@

        try {
            Throw "This is an exception"
        }
        catch {
            Checkpoint-MoveFailed @commonParameters -ExceptionDetail $_ | Should Be $Query_Assert2
        }
    }
  }
}
