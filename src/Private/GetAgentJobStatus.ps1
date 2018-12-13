# Function to create sql query for retrieving SQL Agent Job Info
function GetAgentJobStatus {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$JobName,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$SSISInstance
  )

  $jobQuery = "WITH    job_stats
          AS ( SELECT TOP 1
                        activity.job_id ,
                        activity.start_execution_date ,
                        activity.stop_execution_date
               FROM     msdb.dbo.sysjobactivity activity
                        INNER JOIN msdb.dbo.sysjobs jobs ON activity.job_id = jobs.job_id
               WHERE    jobs.[name] = '$JobName'
               ORDER BY activity.last_executed_step_date DESC
             )
    SELECT  StepName = jobHistory.step_name ,
            ExecutionStatus = CASE jobHistory.run_status
                                WHEN 0 THEN 'Failed'
                                WHEN 1 THEN 'Succeeded'
                                WHEN 2 THEN 'Retry'
                                WHEN 3 THEN 'Cancelled'
                                WHEN 4 THEN 'In Progress'
                              END
    FROM    msdb.dbo.sysjobs jobs
            INNER JOIN msdb.dbo.sysjobhistory jobHistory ON jobs.job_id = jobHistory.job_id
            INNER JOIN job_stats ON job_stats.job_id = jobs.job_id
                                    AND CONVERT(DATETIME, CONVERT(CHAR(8), jobHistory.run_date, 112)
                                    + ' ' + STUFF(STUFF(RIGHT('000000'
                                                              + CONVERT(VARCHAR(8), jobHistory.run_time),
                                                              6), 5, 0, ':'),
                                                  3, 0, ':'), 121) BETWEEN job_stats.start_execution_date
                                                              AND
                                                              job_stats.stop_execution_date;"

  $params = @{
                ServerInstance = $SSISInstance
                Database = 'master'
                OutputSqlErrors = $true
                ErrorAction = 'Stop'
            }

  $results = Invoke-Sqlcmd @params -Query $jobQuery
  $results
}
