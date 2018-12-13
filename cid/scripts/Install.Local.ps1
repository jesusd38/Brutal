<#
  local install Brutal script

  this is meant to be run from the repo root and will package up
  the current /src directory and deploy it to the machine's PSModulePath

  Requirements: 
    * Install Brutal to the MACHINE's PSModulePath
    * Allow for a specific version to be installed, default latest
    * Check old install directory, in $user: documents. Make sure it doesn't exist
    * Clean out module directory before moving new files over
#>

## must be in administrative mode
$current_identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
  Throw 'This MUST be ran from an administrative session'
  return # shouldn't be needed but just in case $ErrorActionPreference = 'SilentlyContinue'
}

# Run the Package script
.\cid\scripts\Package.ps1

# that will place a .zip file .\.Brutal\build_artifact\Brutal-version.zip
$brutal_package = Get-ChildItem -Path '.\.cider\build_artifact' -Filter *.zip | Sort-Object LastAccessTime -Descending | Select-Object -First 1

Write-Output "Attempting to install $($brutal_package.FullName)..."

# create a temporary folder to unzip the package to
do {
  $tempLocation = Join-Path -Path $env:TEMP -ChildPath ('cider-' + [Guid]::NewGuid())
} until (-not (  Test-Path -Path $tempLocation ))

New-Item -ItemType Container -Path $tempLocation | Out-Null

# copy the .zip file from the network to the temp location
Copy-Item -Path $brutal_package.FullName -Destination $tempLocation

$target_path = 'C:\Program Files\WindowsPowerShell\Modules\Brutal'

# if the Brutal module is there, remove the contents
if (Test-Path $target_path) {
  Write-Output "An existing module Brutal module found. Removing it"
  Remove-Item $target_path -Recurse -Force 
  Write-Output "Old module removed"
}

# unzip the package
Write-Output 'Installing Brutal to the machines module root path'
& 7z x "$tempLocation\$($brutal_package.BaseName).zip" -o"$target_path" | Out-Null

# and remove it (so it doesn't copy itself over to the module directory)
# sure beats creating two temp directories!
#Remove-Item -Path "$tempLocation\$($brutal_package.BaseName).zip" -Force

# clean up after ourselves!
Write-Output 'Done. Cleaning up the temporary files'
Remove-Item $tempLocation -Recurse -Force

## also need to cleanup the old path!
$old_install_path = "$($env:USERPROFILE)\documents\windowspowershell\modules\Brutal"

if (Test-Path $old_install_path) {
  Write-Output "Found Brutal in the version 2.X path. $old_install_path `n Removing it..."
  Remove-Item $old_install_path -Recurse -Force
}

Write-Output 'Done!'
