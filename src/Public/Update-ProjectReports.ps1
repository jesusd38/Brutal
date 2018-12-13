<#
    .SYNOPSIS
    Updates a project's reports by running the DW ETL load for one project

    .DESCRIPTION
    Use this function to to run the single project agent job to refresh the overnight load
    for one project.

    .EXAMPLE
    Update-ProjectReports -ProjectCode "H10220"

    Will refresh project code "H10220"

    .EXAMPLE
    Update-ProjectReports -ProjectCode "H10220" -Wait

    Will refresh project code "H10220" and not return the session back until the job is done

    .PARAMETER ProjectCode
    The project codes to refresh

    .PARAMETER SSISInstance
    The SSIS Instance to use. Defaults to production (US) ssis

    .PARAMETER AdminDBInstance
    The Admin Db Instance to use. Defaults to production (US)

    .PARAMETER Wait
    Will not return the session until the job completes when used
#>
function Update-ProjectReports {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
            [string]$ProjectCode,

        [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
            [string]$SSISInstance = 'HLSSISP01',

        [Parameter(Position=2,ValueFromPipelineByPropertyName=$true)]
            [string]$AdminDBInstance = 'MTPVPDSQLP06\PROJP11',

        [Parameter()]
            [switch]$Wait
    )

    process {
        try {
            # Log Update Attempt
            SendLoggingEvent -EventName 'UpdateProjectReports' -Message 'Update Initiated' -LogLevel 'Info' -ProjectCode $ProjectCode

            $SSISInstance = GetSSISInstanceByProjectCode $ProjectCode

            # If this ever changes in production, we'll have issues!
            $jobName = 'HL_ENG - Admin_Project_Review_DW_ETL_SingleProject'

            # Set the LoadProjectCode variable in the PROD(SingleProd) Environment
            $query = "DECLARE @var sql_variant = N'$ProjectCode';EXEC [SSISDB].[catalog].[set_environment_variable_value] @variable_name=N'LoadProjectCode', @environment_name=N'PROD(SingleProj)', @folder_name=N'Environments', @value=@var"

            $params = @{
                ServerInstance = $SSISInstance
                Database = 'master'
                OutputSqlErrors = $true
                ErrorAction = 'Stop'
            }

            Invoke-Sqlcmd @params -Query $query

            # Start the job
            $query = "EXEC msdb.dbo.sp_start_job '$jobName'"
            Invoke-Sqlcmd @params -Query $query

            # Monitor the job (only if -wait was used)
            if ($wait) {
                While(1) {
                    # Sleep 5 sec so job can start up.
                    Start-Sleep -s 5
                    $query = "exec msdb.dbo.sp_help_job @job_name = '$jobName'"
                    $results = Invoke-Sqlcmd @params -Query $query
                    $status = $results[0].current_execution_status

                    # status 1 = running
                    if (($status -eq 4) -or ($status -eq 5)) {

                        # Get Agent Job Info
                        $jobResults = GetAgentJobStatus -JobName $jobName -SSISInstance $SSISInstance
                        Write-Output $jobResults | Format-Table -AutoSize
                        break;
                    }
                    else {
                        # Sleep for 30 seconds
                        Write-Output "Waiting for job to complete. Will check again in 30 seconds"
                        Start-Sleep -s 30
                    }
                }
            }
        }
        catch {
            $msg = "There was an error refreshing the reports for $ProjectCode Error Details: $_"
            SendLoggingEvent -EventName 'UpdateProjectReports' -Message $msg -LogLevel 'Error' -ProjectCode $ProjectCode
            Throw $msg
        }
    }
}
