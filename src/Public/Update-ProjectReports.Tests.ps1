$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Update-ProjectReports' {

    beforeEach {
        # Generic mocks to prevent dialing out to production
        Mock Invoke-Sqlcmd { }
    }

    $project_code_assert = "DECLARE @var sql_variant = N'H00001';EXEC [SSISDB].[catalog].[set_environment_variable_value] @variable_name=N'LoadProjectCode', @environment_name=N'PROD(SingleProj)', @folder_name=N'Environments', @value=@var"
    $job_start_assert = "EXEC msdb.dbo.sp_start_job 'HL_ENG - Admin_Project_Review_DW_ETL_SingleProject'"
    $job_monitor_assert = "exec msdb.dbo.sp_help_job @job_name = 'HL_ENG - Admin_Project_Review_DW_ETL_SingleProject'"

    it 'changes the environment project code to load' {
        Update-ProjectReports -ProjectCode 'H00001'
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $project_code_assert } -Exactly 1 -Scope It
    }

    it 'starts the job' {
        Update-ProjectReports -ProjectCode 'H00001'
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $job_start_assert } -Exactly 1 -Scope It
    }

    it 'does not wait for the job to finish by default' {
        Update-ProjectReports -ProjectCode 'H00001'
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $job_monitor_assert } -Exactly 0 -Scope It
    }

    it 'will stop execution when an error occurs' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' } -ParameterFilter { $Query -eq $project_code_assert }
        { Update-ProjectReports -ProjectCode 'H00001' } | Should Throw
        Assert-MockCalled Invoke-Sqlcmd -ParameterFilter { $Query -eq $job_start_assert } -Exactly 0 -Scope It
    }

    it 'will throw an error when something bad happens' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' } -ParameterFilter { $Query -eq $project_code_assert }
        { Update-ProjectReports -ProjectCode 'H00001' } |
            Should Throw 'There was an error refreshing the reports for H00001 Error Details: Access Denied'
    }
  }
}
