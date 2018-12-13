$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {
    Describe 'Get-DefaultServerPaths' {
        beforeEach {
            Mock Invoke-Sqlcmd { return $null }
            Mock Invoke-Sqlcmd {
                return @{
                    DefaultDataPath = 'D:\Does\Not\Exist\'
                    DefaultLogPath = 'L:\Does\Not\Exist\'
                }
            } -ParameterFilter { $ServerInstance -eq 'Generic01' }

            Mock Invoke-Sqlcmd {
                return @{
                    DefaultDataPath = 'D:\Does\Not\Exist'
                    DefaultLogPath = 'L:\Does\Not\Exist'
                }
            } -ParameterFilter { $ServerInstance -eq 'NoSlashes01' }
            Mock Invoke-Sqlcmd {
                return @{
                    DefaultDataPath = '  D:\Does\Not\Exist\  '
                    DefaultLogPath = '  L:\Does\Not\Exist  '
                }
            } -ParameterFilter { $ServerInstance -eq 'Spaces01' }

        }

        it 'returns a custom object' {
            (Get-DefaultServerPaths -ServerInstance 'Generic01').GetType().Name | Should Be 'PSCustomObject'
        }

        it 'returns the default data path' {
            (Get-DefaultServerPaths -ServerInstance 'Generic01').DefaultDataPath | Should Be 'D:\Does\Not\Exist\'
        }

        it 'returns the default log path' {
            (Get-DefaultServerPaths -ServerInstance 'Generic01').DefaultLogPath | Should Be 'L:\Does\Not\Exist\'
        }

        it 'gets the default paths from the specified server' {
            Get-DefaultServerPaths -ServerInstance 'Generic01' | Out-Null
            Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'Generic01' } -Exactly 1 -Scope It
        }

        it 'returns null when no paths were returned' {
            Get-DefaultServerPaths -ServerInstance 'NotReferenced'  | Should Be $null
        }

        it 'trims the default data path when there are leading and/or trailing spaces' {
            (Get-DefaultServerPaths -ServerInstance 'Spaces01').DefaultDataPath | Should Be 'D:\Does\Not\Exist\'
        }

        it 'trims the default log path when there are leading and/or trailing spaces' {
            (Get-DefaultServerPaths -ServerInstance 'Spaces01').DefaultLogPath | Should Be 'L:\Does\Not\Exist\'
        }

        it 'adds the trailing slash to the default data path when not there' {
            (Get-DefaultServerPaths -ServerInstance 'NoSlashes01').DefaultDataPath | Should Be 'D:\Does\Not\Exist\'
        }

        it 'adds the trailing slash to the default log path when not there' {
            (Get-DefaultServerPaths -ServerInstance 'NoSlashes01').DefaultLogPath | Should Be 'L:\Does\Not\Exist\'
        }

        it 'throws an informative exception on error' {
            Mock Invoke-Sqlcmd { Throw "Access Error" }

            { Get-DefaultServerPaths -ServerInstance 'UnitTest' } | Should Throw "Get-DefaultServerPaths: There was an error getting the default server paths. Error Detail: Access Error"
        }
    }
}
