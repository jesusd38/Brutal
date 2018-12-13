$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Get-ProjectProperties' {
    beforeEach {
        # Generic Mocks (To prevent dialing out to production)
        Mock GetProjectDetailsFromAdminDB { }
        Mock FindProjectDatabases { }
        MOck GetWorkspaceDetails { }

        Mock GetProjectDetailsFromAdminDB { return @{ ProjectID = -1;ProjectServer='UnitTest02';EDDSInstance='UnitTest07';ReviewCampus='UnitTest08'; } } -ParameterFilter { $ProjectCode -eq 'H00001' }
        Mock GetProjectDetailsFromAdminDB { return @{ ProjectID = -2;ProjectServer='UnitTest03';EDDSInstance='UnitTest09';ReviewCampus='UnitTest10'; } } -ParameterFilter { $ProjectCode -eq 'H00002' }
        Mock GetProjectDetailsFromAdminDB { return @{ ProjectID = -3;ProjectServer='UnitTest04';EDDSInstance='';ReviewCampus=''; } } -ParameterFilter { $ProjectCode -eq 'H00003' }

        Mock FindProjectDatabases { return @('H00001_EDD','H00001_ETL','H00001_FR') } -ParameterFilter { $ProjectCode -eq 'H00001' }
        Mock FindProjectDatabases { return @('H00002_EDD','H00002_ETL','H00002_FR') } -ParameterFilter { $ProjectCode -eq 'H00002' }
        Mock FindProjectDatabases { return @('H00003_EDD','H00003_ETL','H00003_FR') } -ParameterFilter { $ProjectCode -eq 'H00003' }

        Mock GetWorkspaceDetails { return @{ WorkspaceServer = 'UnitTest05';WorkspaceDatabase='UnitTestDB99'; } } -ParameterFilter { $ProjectCode -eq 'H00001' }
        Mock GetWorkspaceDetails { return @{ WorkspaceServer = 'UnitTest06';WorkspaceDatabase='UnitTestDB100'; } } -ParameterFilter { $ProjectCode -eq 'H00002' }
    }

    it 'returns an object' {
        (Get-ProjectProperties -ProjectCode 'H00001').GetType().Name | Should Be 'PSCustomObject'
    }

    it 'returns an array of objects when multiple projects are put in' {
        (Get-ProjectProperties -ProjectCode 'H00001','H00002').GetType().BaseType | Should Be 'Array'
    }

    it 'returns the projectID' {
        ('H00001' | Get-ProjectProperties).ProjectID | Should Be -1
    }

    it 'returns the ProjectServer' {
        ('H00001' | Get-ProjectProperties).ProjectServer | Should Be 'UnitTest02'
    }

    it 'returns the ProjectDatabases' {
        ('H00001' | Get-ProjectProperties).ProjectDatabases | Should Be @('H00001_EDD','H00001_ETL','H00001_FR')
    }

    it 'returns the Review Campus' {
        ('H00001' | Get-ProjectProperties).ReviewCampus | Should Be 'UnitTest08'
    }

    it 'returns the Workspace Server' {
        ('H00001' | Get-ProjectProperties).WorkspaceServer | Should Be 'UnitTest05'
    }

    it 'returns the Workspace Database' {
        ('H00001' | Get-ProjectProperties).WorkspaceDatabase | Should Be 'UnitTestDB99'
    }

    it 'processes one project code' {
        # from the pipeline
        ('H00001' | Get-ProjectProperties).ProjectID | Should Be -1

        # normal call
        (Get-ProjectProperties -ProjectCode H00001).ProjectID | Should Be -1
    }

    it 'processes multiple project codes' {
        # from the pipeline
        'H00001', 'H00002' | Get-ProjectProperties | %{ $_.ProjectServer | Should Match 'UnitTest' }

        # normal call
        Get-ProjectProperties -ProjectCode 'H00001', 'H00002' | %{ $_.ProjectServer | Should Match 'UnitTest' }
    }

    it 'returns an array of project databases' {
        ((Get-ProjectProperties -ProjectCode 'H00001').ProjectDatabases).GetType().BaseType | Should Be 'Array'
    }

    it 'returns an array of project databases when there is only 1 found' {
        Mock Invoke-Sqlcmd { return @{ name = @('H00001_EDD');} } -ParameterFilter { $ServerInstance -eq 'UnitTest02' }
        ((Get-ProjectProperties -ProjectCode 'H00001').ProjectDatabases).GetType().BaseType | Should Be 'Array'
    }

    it 'throws an error and stops when a project code wasn''t found in AdminDB' {
        Mock GetProjectDetailsFromAdminDB { Throw 'AdminDB did not return a server for this project' } -ParameterFilter { $ProjectCode -eq 'H00001' }

        { Get-ProjectProperties -ProjectCode H00001,H00002 } |
            Should Throw 'There was an error getting the project properties for H00001 Error Details: AdminDB did not return a server for this project'

        # make sure database list query wasn't executed
        Assert-MockCalled FindProjectDatabases -Exactly 0 -Scope It

        # should NOT process H00002
        Assert-MockCalled GetProjectDetailsFromAdminDB -ParameterFilter { $ProjectCode -eq 'H00002' } -Exactly 0 -Scope It
    }

    it 'allows AdminDBInstance parameter to be overrode' {
        Get-ProjectProperties -ProjectCode 'H00001', 'H00002' -AdminDBInstance 'UnitTest08' | %{ $_.ProjectServer | Should Match 'UnitTest' }

        Assert-MockCalled GetProjectDetailsFromAdminDB -ParameterFilter { $AdminDBInstance -eq 'UnitTest08' } -Exactly 2 -Scope It
    }

    it 'returns projects that do not have review data' {
        ('H00003' | Get-ProjectProperties).WorkspaceServer | Should Be $null
        ('H00003' | Get-ProjectProperties).WorkspaceDatabase | Should Be $null
    }
  }
}
