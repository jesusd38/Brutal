$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'GetSSISInstanceByProjectCode' {

    $commonParams = @{
        AdminDBInstance = 'AdminDbInstance01'
        ProjectCode = 'H00001'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { return @{SSISInstance='UnitTest01';} }
    }

    it 'executes the server on the target instance' {
        GetSSISInstanceByProjectCode @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'AdminDbInstance01' } -Exactly 1 -Scope It
    }

    it 'returns default when nothing is returned from the server' {
        Mock Invoke-Sqlcmd { return 'HLSSISP01' }
        GetSSISInstanceByProjectCode @commonParams | Should Be 'HLSSISP01'
    }

    it 'returns a String' {
        (GetSSISInstanceByProjectCode @commonParams).GetType().Name | Should Be 'String'
    }
  }
}
