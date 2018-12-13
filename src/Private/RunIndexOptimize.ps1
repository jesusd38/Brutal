<#
    Internal function to run the IndexOptimize script on a database
#>
function RunIndexOptimize {
    [CmdletBinding()]
    param(
        # The database name
        [Parameter(Mandatory=$true,Position=0)]
            [string]$DatabaseName,

        # The server instance of the database
        [Parameter(Mandatory=$true,Position=1)]
            [string]$ServerInstance,

        # Rebuild the indexes or only run stats update??
        [Parameter()]
            [switch]$Full,

        [Parameter(ValueFromRemainingArguments=$true)]
            $dumpVar
    )

    if ($Full) {
        Write-Verbose "Running the full index optimize scripts on $ServerInstance..$DatabaseName"
        $query = "
            EXECUTE dbo.IndexOptimize @Databases = '$DatabaseName'
						            , @FragmentationLow = NULL
						            , @FragmentationMedium = 'INDEX_REORGANIZE'
						            , @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
						            , @FragmentationLevel1 = 15
						            , @FragmentationLevel2 = 30
						            , @UpdateStatistics = 'ALL'
						            , @OnlyModifiedStatistics = 'Y'
						            , @Indexes = 'ALL_INDEXES'
						            , @LogToTable = 'Y';"
    }
    else {
        Write-Verbose "Running the statistics update scripts on $ServerInstance..$DatabaseName"
        $query = "
            EXECUTE dbo.IndexOptimize @Databases = '$DatabaseName'
						            , @FragmentationLow = NULL
						            , @FragmentationMedium = NULL
						            , @FragmentationHigh = NULL
						            , @FragmentationLevel1 = 15
						            , @FragmentationLevel2 = 30
						            , @UpdateStatistics = 'ALL'
						            , @OnlyModifiedStatistics = 'Y'
						            , @Indexes = 'ALL_INDEXES'
						            , @LogToTable = 'Y';"
    }

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
        QueryTimeout = 0
    }

    try {
        Invoke-Sqlcmd @params
    }
    catch {
        Throw "There was an error running the index optimize scripts. Error Details: $_"
    }
}
