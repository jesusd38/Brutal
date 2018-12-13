$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {
  Describe 'UpdateProjectProperties' {

    beforeEach {
        Mock Invoke-Sqlcmd { return $query }
    }

     # generic params to cut down on copy/paste
    $params = @{
        AdminDBInstance = 'UTAdminDB01'
        ProjectID = 1
        DatabaseServer = 'UTServer01'
    }

    it 'correctly updates the project properties for ETL/EDD projects' {
        $shouldBe = "EXEC [ADMIN].[ProjectUpdate] @ID= 1, @DatabaseServer = 'UTServer01', @DatabaseName = null"
        UpdateProjectProperties @params -ProjectType EDD | Should Be $shouldBe
    }

    it 'correctly update the project properties for FR projects' {
        $shouldBe = "EXEC [ADMIN].[ForensicServiceResourceUpdate] @ProjectID = 1, @DatabaseServer = 'UTServer01', @DatabaseName = null, @ServiceResourceID = null"
        UpdateProjectProperties @params -ProjectType FR | Should Be $shouldBe
    }

    it 'does not do anything when the projectID is -1' {
        UpdateProjectProperties -AdminDBInstance 'UTAdminDB01' -ProjectId -1 -DatabaseServer 'UTServer01' -ProjectType FR
        Assert-MockCalled Invoke-Sqlcmd -Exactly 0 -Scope It
    }

    it 'throws an informative exception on error' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { UpdateProjectProperties @params -ProjectType EDD } |
            Should Throw 'There was an error updating project properties. Error Details: Access Denied'
    }
  }
}
