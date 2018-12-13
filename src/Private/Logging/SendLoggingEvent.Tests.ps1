$script_dir =  Split-Path -Parent $MyInvocation.MyCommand.Path

# Load Testing Function
. "$script_dir\sendLoggingEvent.ps1"

Describe 'sendLoggingEvent' {
  BeforeEach {
    Mock Invoke-RestMethod { return $body }
  }

  it 'formats and sends over the base properties' {
    $body = sendLoggingEvent -EventName 'UpdateProjectReports' -Message 'UnitTest' | ConvertFrom-Json

    $body.app_name | Should Be 'Brutal'
    $body.host | Should Be $env:COMPUTERNAME
    $body.process_user | Should Be $env:USERNAME
    $body.message | Should Be 'UnitTest'
  }

  it 'defaults the log level to info' {
    $body = sendLoggingEvent -EventName 'UpdateProjectReports' -Message 'UnitTest' | ConvertFrom-Json
    $body.log_level | Should Be 'Info'
  }

  it 'allows the log level to be changed' {
    $body = sendLoggingEvent -EventName 'UpdateProjectReports' -LogLevel 'Warn' -Message 'UnitTest' | ConvertFrom-Json
    $body.log_level | Should Be 'Warn'
  }

  it 'formats and sends the project code as an extended property' {
    $body = sendLoggingEvent -EventName 'UpdateProjectReports' -ProjectCode 'H00000' -LogLevel 'Warn' -Message 'UnitTest' | ConvertFrom-Json
    $body.extended_properties.Brutal.ProjectCode | Should Be 'H00000'
  }
}
