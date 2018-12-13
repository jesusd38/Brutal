$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Confirm-DatabaseReadyToMove' {

    $commonParams = @{
        SourceInstance = 'UnitTest01'
        DatabaseName = 'UnitTestDB_EDD'
        AdminDBInstance = 'AdminDBInstance'
        AuditRecordID = 1
    }

    $exists_assert = 'SELECT COUNT(*) as [Count] FROM sys.databases WHERE name = ''UnitTestDB_EDD'''
    $connection_assert = 'SELECT COUNT(dbid) AS [Count] FROM sys.sysprocesses WHERE DB_NAME(dbid) = ''UnitTestDB_EDD'''
    $state_assert = 'SELECT user_access_desc AS [State] FROM sys.databases WHERE name = ''UnitTestDB_EDD'''

    Mock Set-ValidationFlag { }

    context 'database is ready to move' {
        beforeEach {
           Confirm-DatabaseReadyToMove @commonParams | Should Be $true
        }

        # exists mock
        Mock Invoke-Sqlcmd { return @{count=1;} } -ParameterFilter { $Query -eq $exists_assert }

        # connection mock
        Mock Invoke-Sqlcmd { return @{count=0;} } -ParameterFilter { $Query -eq $connection_assert }

        # state mock
        Mock Invoke-Sqlcmd { return @{State='MULTI_USER';} } -ParameterFilter { $Query -eq $state_assert }

        it 'checks that the database exists' {
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $exists_assert } -Exactly 1 -Scope It
        }

        it 'checks that there are no open connections to the database' {
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $connection_assert } -Exactly 1 -Scope It
        }

        it 'checks that the database is in the correct state' {
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $state_assert } -Exactly 1 -Scope It
        }

        it 'sets the correct validation flags' {
            Assert-MockCalled Set-ValidationFlag  -Exactly 1 -Scope It -ParameterFilter { $Flags -contains 2 -and $Flags -contains 4 -and $Flags -contains 8}
        }
    }

    context 'database is not ready to move' {
        beforeEach {
            # exists mock
            Mock Invoke-Sqlcmd { return @{count=1;} } -ParameterFilter { $Query -eq $exists_assert }

            # connection mock
            Mock Invoke-Sqlcmd { return @{count=0;} } -ParameterFilter { $Query -eq $connection_assert }

            # state mock
            Mock Invoke-Sqlcmd { return @{State='MULTI_USER';} } -ParameterFilter { $Query -eq $state_assert }
        }

        it 'throw an error and stops when the database does not exist' {
            Mock Invoke-Sqlcmd { return @{count=0;} } -ParameterFilter { $Query -eq $exists_assert }

            { Confirm-DatabaseReadyToMove @commonParams  } | Should Throw 'There was an error confirming the database state. Error Details: There was no database to move on the server'

            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $connection_assert } -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $state_assert } -Exactly 0 -Scope It
            Assert-MockCalled Set-ValidationFlag -Exactly 0 -Scope It
        }

        it 'throws an error when there are active connections to the database' {
            # there are 64 connections open. :)
            Mock Invoke-Sqlcmd { return @{count=64;} } -ParameterFilter { $Query -eq $connection_assert }

            { Confirm-DatabaseReadyToMove @commonParams  } | Should Throw 'There was an error confirming the database state. Error Details: There are connections to this database, cannot move it at this time.'

            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $state_assert } -Exactly 0 -Scope It
            Assert-MockCalled Set-ValidationFlag -ParameterFilter { $Flags -eq 2 } -Exactly 1 -Scope It
            Assert-MockCalled Set-ValidationFlag  -Exactly 1 -Scope It -ParameterFilter { $Flags -contains 2}
        }

        it 'throws an error when the database is not in MULTI_USER state' {
            Mock Invoke-Sqlcmd { return @{State='SINGLE_USER';} } -ParameterFilter { $Query -eq $state_assert }
            { Confirm-DatabaseReadyToMove @commonParams  } | Should Throw 'The database is not in MULTI_USER state'
            Assert-MockCalled Set-ValidationFlag  -Exactly 1 -Scope It -ParameterFilter { $Flags -contains 2 -and $Flags -contains 4}
        }
    }

    context 'invoke-sql havoc' {
        beforeEach {
            # exists mock
            Mock Invoke-Sqlcmd { return @{count=1;} } -ParameterFilter { $Query -eq $exists_assert }

            # connection mock
            Mock Invoke-Sqlcmd { return @{count=0;} } -ParameterFilter { $Query -eq $connection_assert }

            # state mock
            Mock Invoke-Sqlcmd { return @{State='MULTI_USER';} } -ParameterFilter { $Query -eq $state_assert }
        }

        it 'throw an error and stops when the database existance check fails' {
            Mock Invoke-Sqlcmd { Throw 'Access Denied' } -ParameterFilter { $Query -eq $exists_assert }

            { Confirm-DatabaseReadyToMove @commonParams  } | Should Throw 'There was an error confirming the database state. Error Details: Access Denied'

            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $connection_assert } -Exactly 0 -Scope It
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $state_assert } -Exactly 0 -Scope It
        }

        it 'throws an error and stops when the active connections check fails' {
            Mock Invoke-Sqlcmd { Throw 'Access Denied' } -ParameterFilter { $Query -eq $connection_assert }

            { Confirm-DatabaseReadyToMove @commonParams  } | Should Throw 'There was an error confirming the database state. Error Details: Access Denied'

            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $exists_assert } -Exactly 1 -Scope It
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $state_assert } -Exactly 0 -Scope It
        }

        it 'throws an error when the database state check fails' {
            Mock Invoke-Sqlcmd { Throw 'Access Denied' } -ParameterFilter { $Query -eq $state_assert }
            { Confirm-DatabaseReadyToMove @commonParams } | Should Throw 'There was an error confirming the database state. Error Details: Access Denied'
        }
    }
  }
}
