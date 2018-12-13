<#
    .SYNOPSIS
    Runs the index optimize scripts on a project database, a workspace database, or both.

    .DESCRIPTION
    Use this function to run the index optimize scripts on a project database, a workspace database, or
    both. This is helpful for when we get tickets saying that a report won't load.

    .EXAMPLE
    Update-DatabaseIndexes -ProjectCode 'H10220'

    Run the optimization scripts on JUST the project database ("H10220_EDD")

    .EXAMPLE
    Update-DatabaseIndexes -ProjectCode 'H10220' -UpdateIndexes Workspace

    Run the optimization scripts on JUST the project's workspace database

    .EXAMPLE
    Update-DatabaseIndexes -ProjectCode 'H10220' -UpdateIndexes Both

    Will run the optimization scripts for Project "H10220" on both the H10220_EDD database as well as
    the H10220 workspace database.

    .EXAMPLE
    Get-ProjectProperties H11824 | Update-DatabaseIndexes -Full

    Shows the ability to pipe the output from Get-ProjectProperties into the update-databaseindexes command. The full switch is
    a complete index rebuild (online).

    .PARAMETER ProjectCode
    The project codes to pull details for.

    .PARAMETER Project
    This accepts the output from the Get-ProjectProperties command.

    .PARAMETER ServerInstance
    Can be used in combination with the $DatabaseName parameter to run the index optimization scripts on any database

    .PARAMETER DatabaseName
    Can be used in combination with the $ServerInstance parameter to run the index optimization scripts on any database

    .PARAMETER UpdateIndexes
    When the command is used in the context of a project ($ProjectCode or $Project), can specify which database to update indexes on (Project, Workspace, or Both)

    .PARAMETER Full
    By default, the command only does a stats update but using this switch will make the update a full index rebuild
#>
function Update-DatabaseIndexes {
    [CmdletBinding(DefaultParameterSetName='Project')]
    param(
        [Parameter(Position=0,ValueFromPipeline=$true,ParameterSetName = 'Project')]
            [string[]]$ProjectCode,

        [Parameter(ValueFromPipeline=$true,ParameterSetName='Pipeline')]
            [object[]]$Project,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Manual')]
            [string]$ServerInstance,

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='Manual')]
            [string]$DatabaseName,

        [Parameter(ParameterSetName='Project')]
        [Parameter(ParameterSetName='Pipeline')]
        [ValidateSet('Project','Workspace','Both')]
            [string]$UpdateIndexes = 'Project',

        [Parameter()]
            [switch]$Full
    )

    process {

        # if a project code is passed in, we'll need to get more information
        if ($PSCmdlet.ParameterSetName -eq 'Project') {
            Write-Verbose "Getting some more information for project $ProjectCode..."
            $Project = Get-ProjectProperties $ProjectCode
        }

        # Manual is super easy cause we can just pass the parameters to the RunIndexOptimize function
        if ($PSCmdlet.ParameterSetName -eq 'Manual') {
            RunIndexOptimize @PsBoundParameters
        }
        else {

            # parse the project object for either the projectDB or workspaceDB connections (or both)
            # depending on the $UpdateIndexes parameter

            if (($UpdateIndexes -eq 'Project') -or ($UpdateIndexes -eq 'Both')) {
                $DatabaseName = $Project.ProjectDatabases | Where-Object { $_ -like '*_EDD' }
                RunIndexOptimize @PsBoundParameters -ServerInstance $($Project.ProjectServer) -DatabaseName $DatabaseName
            }

            if (($UpdateIndexes -eq 'Workspace') -or ($UpdateIndexes -eq 'Both')) {
                RunIndexOptimize @PsBoundParameters -ServerInstance $($Project.WorkspaceServer) -DatabaseName $($Project.WorkspaceDatabase)
            }
        }
    }
}
