$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Set-DatabaseReadWrite' {

    $commonParams = @{
        ServerInstance = 'UnitTest01'
        DatabaseName = 'UnitTestDB'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { }
    }

    it 'builds the correct query' {
        Set-DatabaseReadWrite @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq 'ALTER DATABASE [UnitTestDB] SET READ_WRITE WITH NO_WAIT' } -Exactly 1 -Scope It
    }

    it 'executes the server on the target instance' {
        Set-DatabaseReadWrite @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'throws an error when something happens' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { Set-DatabaseReadWrite @commonParams } |
            Should Throw 'Set-DatabaseReadWrite: There was a problem setting the database to read/write. Error Details: Access Denied'
    }
  }
}
