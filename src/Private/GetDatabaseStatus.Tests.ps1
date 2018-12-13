$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'GetDatabaseStatus' {

    $commonParams = @{
        ServerInstance = 'UnitTest01'
        DatabaseName = 'UnitTestDB'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { return @{user_access_desc='MULTI_USER';state_desc='ONLINE';is_read_only=$false;} }
    }

    it 'builds the correct query' {
        $query_assert = "
        SELECT
            user_access_desc,
            is_read_only,
            state_desc
        FROM sys.databases
        WHERE name = 'UnitTestDB'"

        GetDatabaseStatus @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq$query_assert } -Exactly 1 -Scope It
    }

    it 'executes the server on the target instance' {
        GetDatabaseStatus @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'returns a state property' {
        $testO = GetDatabaseStatus @commonParams
        $testO.State | Should Be 'Online'
    }

    it 'returns a database name property' {
        $testO = GetDatabaseStatus @commonParams
        $testO.DatabaseName | Should Be 'UnitTestDB'
    }

    it 'returns a server instance property' {
        $testO = GetDatabaseStatus @commonParams
        $testO.ServerInstance | Should Be 'UnitTest01'
    }

    it 'returns a readonly property' {
        $testO = GetDatabaseStatus @commonParams
        $testO.ReadOnly | Should Be $false
    }

    it 'returns a user access property' {
        $testO = GetDatabaseStatus @commonParams
        $testO.UserAccess | Should Be 'MULTI_USER'
    }

    it 'returns $null when nothing is returned from the server' {
        Mock Invoke-Sqlcmd { return $null }
        GetDatabaseStatus @commonParams | Should Be $null
    }

    it 'returns a custom object' {
        (GetDatabaseStatus @commonParams).GetType().Name | Should Be 'PSCustomObject'
    }
  }
}
