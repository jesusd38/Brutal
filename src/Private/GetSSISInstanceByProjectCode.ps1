# Function to get SSISInstance from Project Code
function GetSSISInstanceByProjectCode {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ProjectCode,

    [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
    [string]$AdminDBInstance = 'MTPVPDSQLP06\PROJP11'
  )

  $query = "
  SELECT  ss.DatabaseServer
  FROM    [AdminDB].[ADMIN].[vProjectOperationalControl] poc
          INNER JOIN dbo.SsisServersXref ss ON ss.fkCampusId = COALESCE(HostingDomainCampusID, ProcessingDomainCampusID)
  WHERE   ProjectCode = '$ProjectCode';"

  $params = @{
    ServerInstance = $AdminDBInstance
    Database = 'AdminDB'
    OutputSqlErrors = $true
    ErrorAction = 'Stop'
    Query = $query
  }

  $result = Invoke-Sqlcmd @params

  if ($result.DatabaseServer -eq $Null -Or $result.DatabaseServer -eq '') {
    $Server = 'HLSSISP01'
  }
  else {
    $Server = $result.DatabaseServer
  }

  $Server
}
