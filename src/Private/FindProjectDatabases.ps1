<#
    Internal function to find project databases on a server.

    Returns list of project database names
#>
function FindProjectDatabases {
    param(
        [string]$ProjectCode,

        # The server instance to look for project databases on
        [string]$ServerInstance
    )

    Write-Verbose "Finding project databases for $ProjectCode on $ServerInstance"

    $query = "SELECT name FROM sys.databases WHERE LEFT(name,6) = '$ProjectCode'"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $result = Invoke-Sqlcmd @params

        # format the result as an array
        $formattedServerResult = @()

        foreach($server in $result) {
            $formattedServerResult += $($server.name)
        }

        Write-Output $formattedServerResult
    }
    catch {
        Throw "There was an error finding project databases for $ProjectCode on $ServerInstance Error Details: $_"
    }
}
