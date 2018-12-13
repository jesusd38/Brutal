$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'DropDatabase' {

    $commonParams = @{
        ServerInstance = 'UnitTest01'
        DatabaseName = 'UnitTestDB'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { }
    }

    it 'builds the correct query' {
        DropDatabase @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq 'DROP DATABASE [UnitTestDB]' } -Exactly 1 -Scope It
    }

    it 'executes the server on the target instance' {
        DropDatabase @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'throws an error when something happens' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { DropDatabase @commonParams } |
            Should Throw 'DropDatabase: There was a problem dropping the database. Error Details: Access Denied'
    }
  }
}
