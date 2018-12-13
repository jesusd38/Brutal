function DropDatabase {
<#
    Internal function to drop a database

    VERY DANGEROUS COMMAND!!!
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
            [string]$ServerInstance,

        [Parameter(Mandatory=$true)]
            [string]$DatabaseName
    )

    $query = "DROP DATABASE [$DatabaseName]"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        Invoke-Sqlcmd @params
    }
    catch {
        Throw "$($MyInvocation.MyCommand.Name): There was a problem dropping the database. Error Details: $_"
    }
}
