$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Restore-InternalDatabase' {
    $commonParams = @{
        DatabaseName = 'UnitTestDB'
        ServerInstance = 'UnitTest01'
        BackupFiles = @(
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_1.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_2.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_3.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_4.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_5.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_6.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_7.bak',
            '\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_8.bak')
    }

    beforeEach {
        Mock Invoke-Sqlcmd { }
        Mock RestoreFileListOnly {
            $props1 = @{
                LogicalName = 'H00000_ETL'
                PhysicalName = 'D:\USER_DATA\DATA_02\H00000_ETL.mdf'
                Type = 'D'
            }

            $props2 = @{
                LogicalName = 'H00000_ETL_log'
                PhysicalName = 'D:\TLOG\TLOG_02\H00000_ETL_log.ldf'
                Type = 'L'
            }

            $ob1 = New-Object -TypeName PSObject -Property $props1
            $ob2 = New-Object -TypeName PSObject -Property $props2

            return @($ob1,$ob2)
        }

        Mock GetRestoreTargetPaths {
            return @{ TargetDataPath = 'D:\USER_DATA\TARGET\';TargetLogPath = 'D:\TLOG\TARGET' }
        }
    }

    it 'executes the query on the specified server instance' {
        Restore-InternalDatabase @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'executes the query against the master database' {
        Restore-InternalDatabase @commonParams
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Database -eq 'master' } -Exactly 1 -Scope It
    }

    it 'builds the correct query' {
        Mock Invoke-Sqlcmd { return $Query }
        $compiledQuery = Restore-InternalDatabase @commonParams
        $queryAssert = "RESTOREDATABASE[UnitTestDB]FROMDISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_1.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_2.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_3.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_4.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_5.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_6.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_7.bak',DISK=N'\\hlnas10\sqlbk_fprojp11\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160630_235021_8.bak'WITHFILE=1,MOVEN'H00000_ETL'TON'D:\USER_DATA\TARGET\H00000_ETL.mdf',MOVEN'H00000_ETL_log'TON'D:\TLOG\TARGETH00000_ETL_log.ldf',NOUNLOAD,STATS=5"
        $compiledQuery.Replace("`n",'').Replace(' ','').Replace("`t",'').Replace("`r",'').Trim() | Should Be $queryAssert
    }

    it 'throws an error when something occurs' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { Restore-InternalDatabase @commonParams } |
            Should Throw 'Restore-InternalDatabase: There was an error restoring the database. Error Details: Access Denied'
    }
  }
}
