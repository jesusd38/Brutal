<#
    Internal function that queries the database server specified ($ServerInstance)
    for the lun information. The LUN with the lowest total space is returned for both
    data & log files.
#>
function GetRestoreTargetPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position = 0, ValueFromPipeline=$true)]
            [string]$ServerInstance
    )

    $query = "
        ;WITH luns AS (
            SELECT
                lunPath   =  CASE WHEN [type]  = 1
                                  THEN SUBSTRING(physical_name,0,PATINDEX('%TLOG_[0-9][0-9]\%',physical_name) + 7)
                              ELSE
                                  SUBSTRING(physical_name,0,PATINDEX('%DATA_[0-9][0-9]\%',physical_name) + 7)
                              END
                ,lunNumber=  CASE WHEN [type]  = 1
                                  THEN  CAST (SUBSTRING(physical_name,PATINDEX('%TLOG_[0-9][0-9]\%',physical_name) + 5,2) AS INT)
                             ELSE
                                  CAST( SUBSTRING(physical_name,PATINDEX('%DATA_[0-9][0-9]\%',physical_name) + 5,2) AS INT )
                             END
                ,size
                ,[type] --1 = LOG 0 = ROWS
            FROM sys.master_files
            WHERE  PATINDEX('%TLOG_[0-9][0-9]\%',physical_name) > 0 OR PATINDEX('%DATA_[0-9][0-9]\%',physical_name) > 0
        )
        SELECT
             logPaths.lunNumber as [LogLunNumber]
            ,logPaths.lunPath as [LogLunPath]
            ,logPaths.Size as [LogLunSize]
            ,logPaths.SizeGB AS [LogLunSizeGB]
            ,logPaths.FileCount AS [LogLunFileCount]
            ,dataPaths.lunNumber as [DataLunNumber]
            ,dataPaths.lunPath as [DataLunPath]
            ,dataPaths.Size as [DataLunSize]
            ,dataPaths.SizeGB AS [DataLunSizeGB]
            ,dataPaths.FileCount AS [DataLunFileCount]
        FROM (
            SELECT TOP 1 lunPath, lunNumber, SUM([size]) AS [Size], CAST((SUM(size) / POWER(2.0,20.0)) AS DECIMAL(10,2)) AS [SizeGB], COUNT(*) AS [FileCount]
            FROM luns
            WHERE [Type] = 1
            GROUP BY lunPath, lunNumber
            ORDER BY SUM([size])
        ) AS logPaths
        CROSS JOIN (
            SELECT TOP 1 lunPath, lunNumber, SUM([size]) AS [Size], CAST((SUM(size) / POWER(2.0,20.0)) AS DECIMAL(10,2)) AS [SizeGB], COUNT(*) AS [FileCount]
            FROM luns
            WHERE [Type] <> 1
            GROUP BY lunPath, lunNumber
            ORDER BY SUM([size])
        ) AS dataPaths; "

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $result = Invoke-Sqlcmd @params

        if ($result.DataLunPath) {

            # always add a trailing backslash for consistency
            if(-not ($result.DataLunPath.Trim().EndsWith('\'))) {
                $targetDataPath = $result.DataLunPath.Trim() + '\'
            }
            else {
                $targetDataPath = $result.DataLunPath.Trim()
            }
        }

        if ($result.LogLunPath) {

            # always add a trailing backslash for consistency
            if(-not ($result.LogLunPath.Trim().EndsWith('\'))) {
                $targetLogPath = $result.LogLunPath.Trim() + '\'
            }
            else {
                $targetLogPath = $result.LogLunPath.Trim()
            }
        }

        # if either target paths have not been set, get the server default paths
        if( (-not $targetDataPath) -or (-not $targetLogPath) ) {
            $defaultPaths = Get-DefaultServerPaths -ServerInstance $ServerInstance

            if(-not $targetDataPath) {
                $targetDataPath = $defaultPaths.DefaultDataPath
            }

            if(-not $targetLogPath) {
                $targetLogPath = $defaultPaths.DefaultLogPath
            }
        }

        # format the return object
        $properties = [Ordered]@{
            TargetDataPath = $targetDataPath
            TargetLogPath = $targetLogPath
            DataPathSizeGB = $result.DataLunSizeGB
            DataPathDBCount = $result.DataLunFileCount
            LogPathSizeGB = $result.LogLunSizeGB
            LogPathDBCount = $result.LogLunFileCount
        }

        $return_object = New-Object -TypeName PSObject -Property $properties

        Write-Output $return_object
    }
    catch {
        Throw "$($MyInvocation.MyCommand.Name): There was an error getting the lun information. Error details: $_"
    }
}
