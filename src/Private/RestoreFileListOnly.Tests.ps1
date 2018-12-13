$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {
  Describe 'RestoreFileListOnly' {

    $commonParameters = @{
        ServerInstance = 'ServerInstance01'
        BackupFiles = @('\\testdir\subdir1\serverinstance01\unittestdb_1.bak','\\testdir\subdir1\serverinstance01\unittestdb_2.bak')
    }

    beforeEach {
        Mock Invoke-Sqlcmd {
            $props1 = @{
                LogicalName          = 'H00000_ETL'
                PhysicalName         = 'D:\USER_DATA\DATA_02\H13239_ETL.mdf'
                Type                 = 'D'
                FileGroupName        = 'PRIMARY'
                Size                 = 539754496
                MaxSize              = 35184372080640
                FileId               = 1
                CreateLSN            = 0
                DropLSN              = 0
                UniqueId             = 'eb8e6d81-8d74-4ce2-b5da-ab9b7d085b41'
                ReadOnlyLSN          = 0
                ReadWriteLSN         = 0
                BackupSizeInBytes    = 4194304
                SourceBlockSize      = 512
                FileGroupId          = 1
                LogGroupGUID         = $null
                DifferentialBaseLSN  = 253000005983300037
                DifferentialBaseGUID = '819c4eb3-b59a-4070-a7bb-6e54ffbf572b'
                IsReadOnly           = $false
                IsPresent            = $false
                TDEThumbprint        = $null
            }

            $props2 = @{
                LogicalName          = 'H00000_ETL_log'
                PhysicalName         = 'D:\TLOG\TLOG_02\H13239_ETL_log.ldf'
                Type                 = 'L'
                FileGroupName        = $null
                Size                 = 269746176
                MaxSize              = 2199023255552
                FileId               = 2
                CreateLSN            = 0
                DropLSN              = 0
                UniqueId             = 'eddd059c-8089-4242-ad7b-f72f4ee1b2a5'
                ReadOnlyLSN          = 0
                ReadWriteLSN         = 0
                BackupSizeInBytes    = 0
                SourceBlockSize      = 512
                FileGroupId          = 0
                LogGroupGUID         = $null
                DifferentialBaseLSN  = 0
                DifferentialBaseGUID = 00000000-0000-0000-0000-000000000000
                IsReadOnly           = $false
                IsPresent            = $true
                TDEThumbprint        = $null
            }

            $customObj1 = New-Object -TypeName PSObject -Property $props1
            $customObj2 = New-Object -TypeName PSObject -Property $props2

            return @($customObj1,$customObj2)
        }
    }

    it 'returns an array of objects' {
        (RestoreFileListOnly @commonParameters).GetType().BaseType | Should Be 'Array'
    }

    it 'builds the correct query based on the parameters' {
        $queryAssert = "RESTORE FILELISTONLY FROM`nDISK = N'\\testdir\subdir1\serverinstance01\unittestdb_1.bak',`nDISK = N'\\testdir\subdir1\serverinstance01\unittestdb_2.bak'`nWITH FILE = 1"
        RestoreFileListOnly @commonParameters
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $queryAssert } -Scope It -Exactly 1
    }

    it 'executes the query on the server instance specified' {
        RestoreFileListOnly @commonParameters
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'ServerInstance01' } -Scope It -Exactly 1
    }

    it 'formats and returns the data file correctly' {
        $testObject = RestoreFileListOnly @commonParameters | Where-Object { $_.Type -eq 'D' }
        $testObject.LogicalName | Should Be 'H00000_ETL'
        $testObject.PhysicalName | Should Be 'D:\USER_DATA\DATA_02\H13239_ETL.mdf'
    }

    it 'formats and returns the log file correctly' {
        $testObject = RestoreFileListOnly @commonParameters | Where-Object { $_.Type -eq 'L' }
        $testObject.LogicalName | Should Be 'H00000_ETL_log'
        $testObject.PhysicalName | Should Be 'D:\TLOG\TLOG_02\H13239_ETL_log.ldf'
    }

    it 'binds to the correct variables in the pipeline' {
        $params = New-Object -TypeName PSObject -Property $commonParameters
        $testObject = $params | RestoreFileListOnly
        $testObject.Count | Should Be 2
    }

    it 'throws an error when something bad happens' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }
        { RestoreFileListOnly @commonParameters } |
            Should Throw 'RestoreFileListOnly: There was an error restoring the file list. Error Details: Access Denied'
    }
  }
}
