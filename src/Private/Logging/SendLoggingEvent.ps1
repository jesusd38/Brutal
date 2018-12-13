function SendLoggingEvent {
<#
  Simple internal function to log to the REST Service
#>
  [CmdletBinding()]
  param(
    [Parameter()]
      [String]$ProjectCode,

    [Parameter(Mandatory=$true)]
      [String]$EventName,

    [Parameter(Mandatory=$true)]
      [String]$Message,

    [Parameter()]
      [String]$LogLevel = 'Info'
  )

  $logging_url = 'https://centralizedlogging.consilio.com/LoggingService/v1/api/LogEntry'

  $base_message = @{
    host = $env:COMPUTERNAME
    app_name = "Brutal"
    app_version = "$([string](Get-Module Brutal).Version)"
    app_campus = "Chicago"
    app_env = "Prod"
    process_user = $env:USERNAME
    log_level = $LogLevel
    event_name = $EventName
    message = $Message
    extended_properties = @{
      Brutal = @{
        run_guid = [guid]::NewGuid().ToString()
      }
    }
  }

  if ($ProjectCode) {
    $base_message.extended_properties.Brutal.Add('ProjectCode', $ProjectCode)
  }

  Invoke-RestMethod -Method Post -UseDefaultCredentials -Uri $logging_url -Body $($base_message | ConvertTo-Json -Depth 99) -ContentType 'text/json'
}
