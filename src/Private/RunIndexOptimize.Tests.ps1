$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'RunIndexOptimize' {

    beforeEach {
        Mock Invoke-Sqlcmd { }
        RunIndexOptimize -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01'
    }

    $query_assert_full = "
            EXECUTE dbo.IndexOptimize @Databases = 'UnitTestDB'
						            , @FragmentationLow = NULL
						            , @FragmentationMedium = 'INDEX_REORGANIZE'
						            , @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
						            , @FragmentationLevel1 = 15
						            , @FragmentationLevel2 = 30
						            , @UpdateStatistics = 'ALL'
						            , @OnlyModifiedStatistics = 'Y'
						            , @Indexes = 'ALL_INDEXES'
						            , @LogToTable = 'Y';"

    $query_assert_light = "
            EXECUTE dbo.IndexOptimize @Databases = 'UnitTestDB'
						            , @FragmentationLow = NULL
						            , @FragmentationMedium = NULL
						            , @FragmentationHigh = NULL
						            , @FragmentationLevel1 = 15
						            , @FragmentationLevel2 = 30
						            , @UpdateStatistics = 'ALL'
						            , @OnlyModifiedStatistics = 'Y'
						            , @Indexes = 'ALL_INDEXES'
						            , @LogToTable = 'Y';"


    it 'runs the stats update query by default' {
       Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -contains $query_assert_light } -Exactly 1 -Scope It
    }

    it 'runs the full index rebuild when the full switch is used' {
        RunIndexOptimize -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01' -Full
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -contains $query_assert_full } -Exactly 1 -Scope It
    }

    it 'runs the procedure on the master database' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Database -eq 'master' } -Exactly 1 -Scope It
    }

    it 'runs the procedure on the right server' {
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $ServerInstance -eq 'UnitTest01' } -Exactly 1 -Scope It
    }

    it 'can handle more than the required parameters splatted in' {
        $newParams = @{
            DatabaseName = 'UnitTestDB'
            ServerInstance = 'UnitTest01'
            Full=$true
            CrapVar1 = 1
            CrapVar2 = 2
        }

        { RunIndexOptimize @newParams } | Should Not Throw
    }

    it 'throws an error when something happens with the query' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }

        { RunIndexOptimize -DatabaseName 'UnitTestDB' -ServerInstance 'UnitTest01' } |
            Should Throw 'There was an error running the index optimize scripts. Error Details: Access Denied'
    }
  }
}
