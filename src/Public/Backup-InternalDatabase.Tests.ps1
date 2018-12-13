$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Backup-InternalDatabase' {

    beforeEach {
        # generic mock
        Mock Invoke-Sqlcmd { }

        Mock Get-LastBackupPath {
            return @{
                DatabaseName='UnitTestDB'
                BackupFiles=@('\\UnitTest01\sqlbk\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160414_095925_1.bak','\\UnitTest01\sqlbk\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160414_095925_2.bak','\\UnitTest01\sqlbk\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160414_095925_3.bak','\\UnitTest01\sqlbk\UnitTest01\UnitTestDB\FULL\UnitTest01_UnitTestDB_FULL_20160414_095925_4.bak')
            }
        }

        Mock Get-LastBackupPath -ParameterFilter { $DatabaseName -eq 'Clusters' } {
            return @{
                DatabaseName='Clusters'
                BackupFiles=@('\\UnitTest01$Instance\sqlbk\UnitTest01$Instance\Clusters\FULL\UnitTest01_Clusters_FULL_20160414_095925_1.bak','\\UnitTest01$Instance\sqlbk\UnitTest01$Instance\Clusters\FULL\UnitTest01_Clusters_FULL_20160414_095925_2.bak')
            }
        }
    }

    $backup_assert = "EXECUTE [master].[dbo].[DatabaseBackup]
	                @Databases = 'UnitTestDB',
	                @Directory = N'\\UnitTest01\sqlbk',
	                @BackupType = 'FULL',
	                @CleanupTime = 168,
	                @CheckSum = 'Y',
	                @NumberOfFiles = 4,
	                @ChangeBackupType = 'Y',
	                @BufferCount = 512,
	                @MaxTransferSize = 2097152,
                    @CopyOnly= 'Y',
	                @Compress = 'Y',
	                @LogToTable = 'Y'".Replace("`n",'').Replace("`t",'').Replace("`r",'').Replace(' ','').Trim()

    it 'correctly parses out the last command record' {
        Backup-InternalDatabase -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01'
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query.Replace("`n",'').Replace("`t",'').Replace("`r",'').Replace(' ','').Trim() -eq $backup_assert } -Exactly 1 -Scope It
    }

    # this test is specifically for MTPVPDSQLP06\PROJP11 where Ola's scripts automatically replace the backslash with a $
    it 'correctly parses out the last command record for clustered servers' {

        $backup_assert = "EXECUTE [master].[dbo].[DatabaseBackup]
	                @Databases = 'Clusters',
	                @Directory = N'\\UnitTest01`$Instance\sqlbk',
	                @BackupType = 'FULL',
	                @CleanupTime = 168,
	                @CheckSum = 'Y',
	                @NumberOfFiles = 2,
	                @ChangeBackupType = 'Y',
	                @BufferCount = 512,
	                @MaxTransferSize = 2097152,
                    @CopyOnly = 'Y',
	                @Compress = 'Y',
	                @LogToTable = 'Y'"

        Backup-InternalDatabase -DatabaseName 'Clusters' -ServerInstance 'UnitTest01\Instance'
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $backup_assert } -Exactly 1 -Scope It
    }

    it 'throws an error when the database was never backed up using Ola''s scripts' {
        Mock Get-LastBackupPath { return $null }

        { Backup-InternalDatabase -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01' } |
            Should Throw 'There was an error getting the prior backup information on the database. Error Details: No commandLog record found for this database. Don''t know where to backup to'
    }

    it 'throws an error when the regex doesn''t match an expected format' {
        Mock Get-LastBackupPath {
            return @{
                DatabaseName='Clusters'
                BackupFiles=@('C:\Temp\backup1.bak')
            }
        }

        { Backup-InternalDatabase -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01' } |
            Should Throw 'There was an error getting the prior backup information on the database. Error Details: commandLog record WAS returned but couldn''t parse the network location'
    }

    it 'throws an error when the backup fails' {
        Mock Invoke-SqlCmd { Throw 'Access Denied' }

        { Backup-InternalDatabase -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01' } |
            Should Throw 'There was an error backing up the database. Error Details: Access Denied'
    }
  }
}
