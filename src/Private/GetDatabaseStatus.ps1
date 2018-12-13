function GetDatabaseStatus {
<#
    External Function to get the status of a database
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
            [string]$ServerInstance,

        [Parameter(Mandatory=$true)]
            [string]$DatabaseName
    )

    $query = "
        SELECT
            user_access_desc,
            is_read_only,
            state_desc
        FROM sys.databases
        WHERE name = '$DatabaseName'"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    $databaseState = Invoke-Sqlcmd @params

    # only return an object if the database exists
    if ($databaseState) {
        # format the return object
        $properties = [ordered]@{
            DatabaseName = $DatabaseName
            ServerInstance = $ServerInstance
            State = $databaseState.state_desc
            ReadOnly = $databaseState.is_read_only
            UserAccess = $databaseState.user_access_desc
        }

        $return_object = New-Object -TypeName PSObject -Property $properties
    }

    Write-Output $return_object
}
