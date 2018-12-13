<#
  Brutal install script. this one is meant to ship with the module
  so that the repo doesn't have to  be downloaded/cloned. 

  $PWD MUST EQUAL $ModuleRoot (where Brutal.psd1 & Brutal.psm1 are)

  We don't every want to to run this from the cloned repo or we would 
  get all of the files including the tests. So if $PWD looks like the 
  repo_root (contains *tests.ps1) abort!
#>


# must be executed from the same directory as the module. this is taken care of
# in the bat file but just in case this script is run from a PowerShell session. 
if (-not (Test-Path 'Brutal.psm1') -or -not (Test-Path 'Brutal.psd1')) {
  Throw 'This does not appear to be the correct Brutal directory. Aborting'
  return # shouldn't be needed but just in case $ErrorActionPreference = 'SilentlyContinue'
}

## must not be executed from within the repo (cause we don't want the unit tests)
if (Get-ChildItem -Filter '*.tests*') {
  Throw 'This should not be run from the repo root. Aborting'
  return # shouldn't be needed but just in case $ErrorActionPreference = 'SilentlyContinue'
}

## must be in administrative mode
$current_identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
  Throw 'This MUST be ran from an administrative session'
  return # shouldn't be needed but just in case $ErrorActionPreference = 'SilentlyContinue'
}

$source_dir = (Get-Location).Path
$destination_dir = 'C:\Program Files\WindowsPowerShell\Modules\Brutal'

# if the Brutal module is there, remove the contents
if (Test-Path $destination_dir) {
  Write-Output "An existing module Brutal module found. Removing it"
  Remove-Item $destination_dir -Recurse -Force 
  Write-Output "Old module removed"
}

# create the Brutal folder in the destination
New-Item -ItemType Container -Path $destination_dir | Out-Null

Write-Output 'Copying the contents of this directory to the module folder...'

# copy everything pver to this directory
Robocopy $source_dir $destination_dir /E | Out-Null

Write-Output 'Copy Complete!'

## also need to cleanup the old path!
$old_install_path = "$($env:USERPROFILE)\documents\windowspowershell\modules\Brutal"

if (Test-Path $old_install_path) {
  Write-Output "Found Brutal in the version 1.X path. $old_install_path `n Removing it..."
  Remove-Item $old_install_path -Recurse -Force
}

Write-Output 'Done!'
