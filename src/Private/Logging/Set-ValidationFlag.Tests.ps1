$moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {
  Describe 'Set-ValidationFlag' {

    beforeEach {
        Mock Invoke-Sqlcmd { }
    }

    $commonParameters = @{
        AdminDBInstance = 'AdminDB01'
        AuditRecordID = 1
    }

    it 'accepts 1 flag as input' {
        Set-ValidationFlag -Flags 2 @commonParameters
        2 | Set-ValidationFlag  @commonParameters
        Assert-MockCalled Invoke-Sqlcmd -Exactly 2 -Scope It
    }

    it 'accepts multiple flags as input' {
        Set-ValidationFlag -Flags 2,3,4 @commonParameters
        2,3,4 | Set-ValidationFlag @commonParameters

        Assert-MockCalled Invoke-Sqlcmd -Exactly 2 -Scope It
    }

    it 'builds the correct query for one flag' {
        Set-ValidationFlag -Flags 2 @commonParameters
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $('UPDATE [WORKFLOW].[DatabaseMoveAudit] SET [ValidationChecks] = [ValidationChecks] ^ 2 WHERE [ID] = 1 AND [ValidationChecks] & 2 = 0;' + "`n") } -Exactly 1 -Scope It
    }

    it 'builds the correct query for multiple flags' {
        $query_assert = 'UPDATE [WORKFLOW].[DatabaseMoveAudit] SET [ValidationChecks] = [ValidationChecks] ^ 2 WHERE [ID] = 1 AND [ValidationChecks] & 2 = 0;' + "`n"
        $query_assert += 'UPDATE [WORKFLOW].[DatabaseMoveAudit] SET [ValidationChecks] = [ValidationChecks] ^ 3 WHERE [ID] = 1 AND [ValidationChecks] & 3 = 0;' + "`n"
        $query_assert += 'UPDATE [WORKFLOW].[DatabaseMoveAudit] SET [ValidationChecks] = [ValidationChecks] ^ 4 WHERE [ID] = 1 AND [ValidationChecks] & 4 = 0;' + "`n"

        2,3,4 | Set-ValidationFlag @commonParameters

        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $query_assert } -Exactly 1 -Scope It
    }

    it 'updates the admindb database' {
        2,3,4 | Set-ValidationFlag @commonParameters
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Database -eq 'AdminDB' } -Exactly 1 -Scope It
    }

    it 'updates the admindb server' {
        2,3,4 | Set-ValidationFlag @commonParameters
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'AdminDB01' } -Exactly 1 -Scope It
    }

    it 'throws an error when something goes wrong' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { 2,3,4 | Set-ValidationFlag @commonParameters } |
            Should Throw 'There was an error setting the validation flags. Error Details: Access Denied'
    }
  }
}
