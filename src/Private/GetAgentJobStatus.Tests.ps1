$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'GetAgentJobStatus' {

    $commonParams = @{
        SSISInstance = 'UnitTest01'
        JobName = 'UnitTestJob'
    }

    beforeEach {
        Mock Invoke-Sqlcmd { return @{StepName='UnitStep';ExecutionStatus='UnitStatus';} }
    }

    it 'executes the server on the target instance' {
        GetAgentJobStatus @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'returns Step name' {
        $testO = GetAgentJobStatus @commonParams
        $testO.StepName | Should Be 'UnitStep'
    }

    it 'returns Execution Status' {
        $testO = GetAgentJobStatus @commonParams
        $testO.ExecutionStatus | Should Be 'UnitStatus'
    }

    it 'returns $null when nothing is returned from the server' {
        Mock Invoke-Sqlcmd { return $null }
        GetAgentJobStatus @commonParams | Should Be $null
    }

    it 'returns a HashTable' {
        (GetAgentJobStatus @commonParams).GetType().Name | Should Be 'HashTable'
    }
  }
}
