$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'GetProjectDetailsFromAdminDB' {
    beforeEach {
        # AdminDB Mock 1
        Mock Invoke-Sqlcmd { return @{ pkProjectID = -1;DatabaseServer='UnitTest02';EDDSInstance='UnitTest03';ReviewCampus='UnitTest04'; } }
    }

    it 'returns an object' {
        (GetProjectDetailsFromAdminDB -ProjectCode 'H00001').GetType().Name | Should Be 'PSCustomObject'
    }

    it 'returns the projectID' {
        ('H00001' |GetProjectDetailsFromAdminDB).ProjectID | Should Be -1
    }

    it 'returns the ProjectServer' {
        ('H00001' | GetProjectDetailsFromAdminDB).ProjectServer | Should Be 'UnitTest02'
    }

    it 'returns the EDDSInstance' {
        ('H00001' | GetProjectDetailsFromAdminDB).EDDSInstance | Should Be 'UnitTest03'
    }

    it 'returns the ReviewCampus' {
        ('H00001' | GetProjectDetailsFromAdminDB).ReviewCampus | Should Be 'UnitTest04'
    }

    it 'throws an error when a project code wasn''t found in AdminDB' {
        Mock Invoke-Sqlcmd { return $null }

        { GetProjectDetailsFromAdminDB -ProjectCode H00001 } |
            Should Throw 'There was an error getting the project properties for H00001 Error Details: AdminDB did not return details for this project'
    }

    it 'throws an error when something happens with the query' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }

        { GetProjectDetailsFromAdminDB -ProjectCode H00001 } |
            Should Throw 'There was an error getting the project properties for H00001 Error Details: Access Denied'
    }
  }
}
