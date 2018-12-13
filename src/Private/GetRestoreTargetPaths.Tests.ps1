$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'GetRestoreTargetPaths' {

    $commonParams = @{
        ServerInstance = 'UnitTest01'
    }

    beforeEach {
        Mock Get-DefaultServerPaths { return @{DefaultLogPath='D:\DEFAULT\TLOG_01\';DefaultDataPath='D:\DEFAULT\DATA_02\';} }

        Mock Invoke-Sqlcmd {
            return @{
                LogLunNumber     = 1
                LogLunPath       = 'D:\CALCULATED\TLOG_01'
                LogLunSize       = 18804728
                LogLunSizeGB     = 17.93
                LogLunFileCount  = 829
                DataLunNumber    = 1
                DataLunPath      = 'D:\CALCULATED\DATA_01'
                DataLunSize      = 451647840
                DataLunSizeGB    = 430.72
                DataLunFileCount = 543
            }
        }
    }

    it 'throws an error when something happens' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { GetRestoreTargetPaths @commonParams } |
            Should Throw 'GetRestoreTargetPaths: There was an error getting the lun information. Error details: Access Denied'
    }

    it 'returns a custom object' {
        (GetRestoreTargetPaths @commonParams).GetType().Name | Should Be 'PSCustomObject'
    }

    it 'runs the query on the specified server instance' {
        GetRestoreTargetPaths @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'gets the default paths when there are no luns returned' {
        Mock Invoke-Sqlcmd { return $null }
        GetRestoreTargetPaths @commonParams
        Assert-MockCalled Get-DefaultServerPaths -Exactly 1 -Scope It
    }

    it 'gets the default data path when no data lun is returned' {
        Mock Invoke-Sqlcmd { return @{ LogLunPath='D:\TEMP\TLOG_01' } }
        $paths = GetRestoreTargetPaths @commonParams
        $paths.TargetDataPath | Should Be 'D:\DEFAULT\DATA_02\'
        $paths.TargetLogPath | Should Be 'D:\TEMP\TLOG_01\'
        Assert-MockCalled Get-DefaultServerPaths -Exactly 1 -Scope It
    }

    it 'gets the default log path when no log lun is returned' {
        Mock Invoke-Sqlcmd { return @{ DataLunPath='D:\TEMP\DATA_01' } }
        $paths = GetRestoreTargetPaths @commonParams
        $paths.TargetDataPath | Should Be 'D:\TEMP\DATA_01\'
        $paths.TargetLogPath | Should Be 'D:\DEFAULT\TLOG_01\'
        Assert-MockCalled Get-DefaultServerPaths -Exactly 1 -Scope It
    }

    it 'trims the leading and trailing spaces from the paths returned' {
        Mock Invoke-Sqlcmd { return @{ DataLunPath='   D:\TEMP\DATA_01   '; LogLunPath = '   D:\TEMP\TLOG_01   ' } }
        $paths = GetRestoreTargetPaths @commonParams
        $paths.TargetDataPath | Should Be 'D:\TEMP\DATA_01\'
        $paths.TargetLogPath | Should Be 'D:\TEMP\TLOG_01\'
    }

    it 'adds the trailing slash when not present' {
        Mock Invoke-Sqlcmd { return @{ DataLunPath='   D:\TEMP\DATA_01   '; LogLunPath = '   D:\TEMP\TLOG_01   ' } }
        $paths = GetRestoreTargetPaths @commonParams
        $paths.TargetDataPath | Should Be 'D:\TEMP\DATA_01\'
        $paths.TargetLogPath | Should Be 'D:\TEMP\TLOG_01\'
    }
  }
}
