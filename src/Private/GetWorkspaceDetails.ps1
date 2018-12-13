<#
    Internal function to get WorkspaceServer & Workspace Database Name from EDDS

    Returns WorkspaceServer & WorkspaceDatabase
#>
function GetWorkspaceDetails {
    [CmdletBinding()]
    param(
        # Project Code to get details for
        [Parameter(Mandatory=$true,Position=0)]
            [string]$ProjectCode,

        # The EDDS Instance to pull from
        [Parameter(Mandatory=$true,Position=1)]
            [string]$EDDSInstance
    )

    Write-Verbose "Getting the workspace details for $ProjectCode from $EDDSInstance"

    $query = "
        SELECT [WorkspaceServer] = art.[TextIdentifier]
	          ,[WorkspaceDatabase]	= 'EDDS' + CAST(cas.ArtifactId AS VARCHAR(25))
        FROM [EDDSDBO].[Case]			cas
        INNER JOIN [EDDSDBO].[Matter]	mat ON cas.MatterArtifactID = mat.ArtifactID
        INNER JOIN [EDDSDBO].[Artifact] art ON cas.ServerID			= art.ArtifactID
        WHERE LTRIM(RTRIM(mat.Number)) = '$ProjectCode'
    "

    $params = @{
        ServerInstance = $EDDSInstance
        Database = 'EDDS'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
    }

    try {
        $result = Invoke-Sqlcmd @params

        if ($result) {

            # if more than 1 workspace is found, throw an error. Results will not be reliable
            if ($result.Count -gt 1) {
                Write-Warning "There were $($result.Count) workspaces found. Choosing the first one returned, the results may not be accurate!!"
                $result = $result[0]
            }

            $workspaceServer = $result.WorkspaceServer
            $workspaceDatabase = $result.WorkspaceDatabase
        }
        else {
            $workspaceServer = ''
            $workspaceDatabase = ''
        }

        $properties = [ordered]@{
            WorkspaceServer = $workspaceServer
            WorkspaceDatabase = $workspaceDatabase
        }

        $return_object = New-Object –typename PSObject -Property $properties

        Write-Output $return_object
    }
    catch {
        Throw "There was an error getting the workspace details for $ProjectCode Error Details: $_"
    }
}
