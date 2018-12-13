<#
  reads the psd1 file for a version number
#>

function _getVersion {
  [CmdletBinding()]
  param()

  # could be run from repo-root 
  # or from src

  if (Test-Path 'Brutal.psd1') {
    $version = [string](Test-ModuleManifest -Path 'Brutal.psd1').Version
  }

  if (Test-Path 'src/Brutal.psd1') {
    $version = [string](Test-ModuleManifest -Path 'src/Brutal.psd1').Version
  }

  if (-not $version) { Throw "Could not find Brutal.psd1 from this path $PWD" }
  else {
    Write-Output $version
  }
}