$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'FindProjectDatabases' {
    beforeEach {
        Mock Invoke-Sqlcmd { return @{ name = @('H00001_EDD','H00001_ETL','H00001_FR');} }
    }

    it 'returns the right values' {
        FindProjectDatabases -ProjectCode 'H00001' -ServerInstance 'UnitTest01' | Should Be @('H00001_EDD','H00001_ETL','H00001_FR')
    }

    it 'returns an array' {
        (FindProjectDatabases -ProjectCode 'H00001' -ServerInstance 'UnitTest01').GetType().BaseType | Should Be 'Array'
    }

    it 'throws an error when something happens with the query' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }

        { FindProjectDatabases -ProjectCode 'H00001' -ServerInstance 'UnitTest01' } |
            Should Throw 'There was an error finding project databases for H00001 on UnitTest01 Error Details: Access Denied'
    }
  }
}
