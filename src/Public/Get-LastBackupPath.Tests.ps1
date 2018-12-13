$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Get-LastBackupPath' {
    beforeEach {
        Mock Invoke-Sqlcmd -ParameterFilter { $DatabaseName -eq 'UnitTestDB' } {
            return @{ command = "BACKUP DATABASE [UnitTestDB] TO DISK = N'\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06`$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06`$PROJP11_UnitTestDB_FULL_20160616_231500_1.bak', DISK = N'\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06`$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06`$PROJP11_UnitTestDB_FULL_20160616_231500_2.bak', DISK = N'\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06`$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06`$PROJP11_UnitTestDB_FULL_20160616_231500_3.bak', DISK = N'\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06`$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06`$PROJP11_UnitTestDB_FULL_20160616_231500_4.bak' WITH CHECKSUM, COMPRESSION";  }
        }

        Mock Invoke-Sqlcmd -ParameterFilter { $DatabaseName -eq 'UnitTestDB1' } {
            return @{ command = "BACKUP DATABASE [UnitTestDB] TO DISK = N'\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06`$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06`$PROJP11_UnitTestDB_FULL_20160616_231500_1.bak' WITH CHECKSUM, COMPRESSION";  }
        }

         Mock Invoke-Sqlcmd -ParameterFilter { $DatabaseName -eq 'UnitTestDB2' } {
            return @{ command = "BACKUP DATABASE [UnitTestDB] TO DISK = N'\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06`$PROJP11\UnitTestDB\FULL_COPY_ONLY\MTPVPDSQLP06`$PROJP11_UnitTestDB_FULL_COPY_ONLY_20160616_231500_1.bak' WITH CHECKSUM, COMPRESSION";  }
        }
    }

    it 'returns an object' {
        (Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB').GetType().Name | Should Be 'PSCustomObject'
    }

    it 'returns the database name as a property' {
        (Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB').DatabaseName | Should Be 'UnitTestDB'
    }

    it 'returns the backups paths as an array' {
        (Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB').BackupFiles.GetType().BaseType.Name | Should Be 'Array'
    }

    it 'returns the backups paths as an array even if only one path exists' {
        (Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB1').BackupFiles.GetType().BaseType.Name | Should Be 'Array'
    }

    it 'returns the backups paths correctly even if only one path exists' {
        (Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB1').BackupFiles | Should Be '\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06$PROJP11_UnitTestDB_FULL_20160616_231500_1.bak'
    }

    it 'returns the backups path for a copy only backup' {
        (Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB2').BackupFiles | Should Be '\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\UnitTestDB\FULL_COPY_ONLY\MTPVPDSQLP06$PROJP11_UnitTestDB_FULL_COPY_ONLY_20160616_231500_1.bak'
    }

    it 'returns the backup paths' {
        $ut_object = Get-LastBackupPath -ServerInstance 'UnitTest01' -DatabaseName 'UnitTestDB'
        $ut_object.BackupFiles -contains '\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06$PROJP11_UnitTestDB_FULL_20160616_231500_1.bak' | Should Be $true
        $ut_object.BackupFiles -contains '\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06$PROJP11_UnitTestDB_FULL_20160616_231500_2.bak' | Should Be $true
        $ut_object.BackupFiles -contains '\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06$PROJP11_UnitTestDB_FULL_20160616_231500_3.bak' | Should Be $true
        $ut_object.BackupFiles -contains '\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP06$PROJP11\UnitTestDB\FULL\MTPVPDSQLP06$PROJP11_UnitTestDB_FULL_20160616_231500_4.bak' | Should Be $true
    }

    it 'throws an error when something bad happened' {
        Mock Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest02'} { Throw 'Access Denied' }
        { Get-LastBackupPath -ServerInstance 'UnitTest02' -DatabaseName 'UnitTestDB' } |
            Should Throw 'Get-LastBackupPath: Could not retrieve backup files. Error Details: Access Denied'
    }
  }
}
