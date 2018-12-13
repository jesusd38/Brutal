<#
    .SYNOPSIS
    Retrieves project details from AdminDB

    .DESCRIPTION
    Use this function to retrieve important information about projects from AdminDB, the project server (returned from
    AdminDB), and from EDDS.

    Defaults to use AdminDB in production environment (US) but this can be changed to use another AdminDB using the $AdminDBInstance parameter.

    Defaults to use EDDS in production environment (US) but this can be changed to use another EDDS Instance using the $EDDSInstance parameter.

    .EXAMPLE
    Get-ProjectProperties -ProjectCode 'H11824'

    Will return the properties for project code H11824

    .EXAMPLE
    Get-ProjectProperties -ProjectCode 'H11824','H10220'

    Get multiple projects' properties at once

    .EXAMPLE
    Get-ProjectProperties -ProjectCode 'H11824' -AdminDBInstance 'MLVUDPRJ01' -EDDSInstance 'QAInstance'

    Get project properties from another environment (QA)

    .PARAMETER ProjectCode
    The project codes to pull details for.


    .PARAMETER AdminDBInstance
    The AdminDB Server Instance that is used to lookup the project information.

    .PARAMETER EDDSInstance
    The EDDS Server Instance that is used to lookup the workspace information.
#>
function Get-ProjectProperties {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
            [string[]]$ProjectCode,

        [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
            [string]$AdminDBInstance = 'MTPVPDSQLP06\PROJP11'
    )

    process {

        foreach($Project in $ProjectCode) {

            try {
                $projectDetails = GetProjectDetailsFromAdminDB -ProjectCode $Project -AdminDBInstance $AdminDBInstance
                $projectDatabases = FindProjectDatabases -ProjectCode $Project -ServerInstance $($projectDetails.ProjectServer)
                if (!([string]::IsNullOrWhiteSpace($projectDetails.EDDSInstance))) {
                    $workspaceDetails = GetWorkspaceDetails -ProjectCode $Project -EDDSInstance $($projectDetails.EDDSInstance)
                }
            }
            catch {
                $msg = "There was an error getting the project properties for $Project Error Details: $_"
                SendLoggingEvent -EventName 'GetProjectProperties' -Message $msg -ProjectCode $Project -LogLevel 'Error'
                Throw $msg
            }

            # format the return object
            $properties = [ordered]@{
                ProjectCode = $Project
                ProjectID = $($projectDetails.ProjectID)
                ProjectServer = $($projectDetails.ProjectServer)
                ProjectDatabases = $projectDatabases
                ReviewCampus = $($projectDetails.ReviewCampus)
                WorkspaceServer = $($workspaceDetails.WorkspaceServer)
                WorkspaceDatabase = $($workspaceDetails.WorkspaceDatabase)
            }

            $return_object = New-Object –typename PSObject -Property $properties

            Write-Output $return_object
        }
    }
}
