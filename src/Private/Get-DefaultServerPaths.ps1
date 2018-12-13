# Returns the default data and log paths from the server
function Get-DefaultServerPaths {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [string]$ServerInstance
    )

    $query = "SELECT SERVERPROPERTY('instancedefaultdatapath') AS [DefaultDataPath], SERVERPROPERTY('instancedefaultlogpath') AS [DefaultLogPath]"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $result = Invoke-Sqlcmd @params

        if ($result) {
            # prepare the return object

            # make sure paths ALWAYS end with '\' (for consistency)
            if (-not $result.DefaultDataPath.Trim().EndsWith('\')) {
                $defaultDataPath = $result.DefaultDataPath.Trim() + '\'
            }
            else {
                $defaultDataPath = $result.DefaultDataPath.Trim()
            }

            if (-not $result.DefaultLogPath.Trim().EndsWith('\')) {
                $defaultLogPath = $result.DefaultLogPath.Trim() + '\'
            }
            else {
                $defaultLogPath = $result.DefaultLogPath.Trim()
            }

            $properties = @{
                DefaultDataPath = $defaultDataPath
                DefaultLogPath = $defaultLogPath
            }

            $return_object = New-Object -TypeName PSObject -Property $properties
        }

        Write-Output $return_object
    }
    catch {
        Throw "$($MyInvocation.MyCommand.Name): There was an error getting the default server paths. Error Detail: $_"
    }
}
