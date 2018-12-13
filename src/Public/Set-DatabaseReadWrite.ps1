<#
    .SYNOPSIS
    Sets a database to read/write mode

    .DESCRIPTION
    Use this function to set a database to read/write mode. This is the corresponding function to
    Set-DatabaseReadOnly.

    .EXAMPLE
    Set-DatabaseReadWrite -DatabaseName 'TestDB' -ServerInstance '(local)'

    Will set the database named 'TestDB' on your local host to read write mode.

    .PARAMETER DatabaseName
    The name of the database to set to read write

    .PARAMETER ServerInstance
    The server instance where the database resides.
#>
function Set-DatabaseReadWrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
            [string]$DatabaseName,

        [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
            [string]$ServerInstance
    )

    # build the query
    $query = "ALTER DATABASE [$DatabaseName] SET READ_WRITE WITH NO_WAIT"

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
        $msg = "$($MyInvocation.MyCommand.Name): There was a problem setting the database to read/write. Error Details: $_"
        SendLoggingEvent -EventName 'SetDatabaseReadWrite' -Message $msg -LogLevel 'Error'
        Throw $msg
    }
}
