<#
    .SYNOPSIS
    Sets a database to read-only mode

    .DESCRIPTION
    Use this function to set a database to read only mode.

    .EXAMPLE
    Set-DatabaseReadOnly -DatabaseName 'TestDB' -ServerInstance '(local)'

    Will set the database named 'TestDB' on your local host to read only mode.

    .PARAMETER DatabaseName
    The name of the database to set to read only

    .PARAMETER ServerInstance
    The server instance where the database resides.
#>
function Set-DatabaseReadOnly {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
            [string]$DatabaseName,

        [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
            [string]$ServerInstance
    )

    # build the query
    $query = "ALTER DATABASE [$DatabaseName] SET READ_ONLY WITH NO_WAIT"

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
        $msg = "$($MyInvocation.MyCommand.Name): There was a problem setting the database to read only. Error Details: $_"
        SendLoggingEvent -EventName 'SetDatabaseReadOnly' -Message $msg -LogLevel 'Error'
        Throw $msg
    }
}
