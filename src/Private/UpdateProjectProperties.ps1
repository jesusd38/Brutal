# Function to update the AdminDB.Project Properties
function UpdateProjectProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
            [string]$AdminDBInstance,

        [Parameter(Mandatory=$true, Position=1)]
            [int]$ProjectID,

        [Parameter(Mandatory=$true, Position=2)]
            [string]$DatabaseServer,

        [Parameter(Mandatory=$true, Position=3)]
        [ValidateSet('EDD','ETL','FR')]
            [string]$ProjectType
    )

    # if $ProjectID is -1, don't update the project properties
    if ($ProjectID -eq -1) {
        return
    }

    # FR databases pass different parameters in
    if ($ProjectType -eq 'FR') {
        $query = "EXEC [ADMIN].[ForensicServiceResourceUpdate] @ProjectID = $ProjectID, @DatabaseServer = '$DatabaseServer', @DatabaseName = null, @ServiceResourceID = null"
    }
    else {
        $query = "EXEC [ADMIN].[ProjectUpdate] @ID= $ProjectID, @DatabaseServer = '$DatabaseServer', @DatabaseName = null"
    }

    $params = @{
        ServerInstance = $AdminDBInstance
        Database = 'AdminDB'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        Invoke-Sqlcmd @params
    }
    catch {
        Throw "There was an error updating project properties. Error Details: $_"
    }
}
