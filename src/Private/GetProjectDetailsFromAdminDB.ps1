<#
    Internal function to get pkProjectId & DatabaseServer from ADMIN.Project

    Returns ProjectID, ProjectServer
#>
function GetProjectDetailsFromAdminDB {
    param(
        # Project Code to get details for
        [string]$ProjectCode,

        # The AdminDB Instance to pull from
        [string]$AdminDBInstance
    )

    Write-Verbose "Getting the project details for $ProjectCode from $AdminDBInstance..AdminDB"

    $query = "SELECT
                p.pkProjectID
                , p.DatabaseServer
                , ri.DatabaseServer AS EDDSInstance
                , dc.Name AS ReviewCampus
            FROM
                ADMIN.Project p
                LEFT OUTER JOIN ADMIN.GetProjectHostingDetailsTable(NULL) AS hd ON hd.ProjectID = p.pkProjectID
                LEFT OUTER JOIN ADMIN.RelativityInstance ri ON hd.RelativityServiceResourceDomainCampusID = ri.DomainCampusID
                LEFT OUTER JOIN dbo.DomainCampus dc ON ri.DomainCampusID = dc.ID
              WHERE
                ProjectCode = '$ProjectCode'"

    $params = @{
        ServerInstance = $AdminDBInstance
        Database = 'AdminDB'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $result = Invoke-Sqlcmd @params

        if (-not $result) { Throw 'AdminDB did not return details for this project' }

        $properties = [ordered]@{
            ProjectID = $($result.pkProjectID)
            ProjectServer = $($result.DatabaseServer)
            EDDSInstance = $($result.EDDSInstance)
            ReviewCampus = $($result.ReviewCampus)
        }

        $return_object = New-Object –typename PSObject -Property $properties

        Write-Output $return_object
    }
    catch {
        Throw "There was an error getting the project properties for $ProjectCode Error Details: $_"
    }
}
