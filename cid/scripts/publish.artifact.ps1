<#
  Just a quick script to publish the artifact 
  to the nas share
#>

$PackagesRoot =  '\\hlnas00\tech\Packages\Brutal'

$currentVersion = Get-Content '.cider/build_artifact/VERSION'

$target_folder = Join-Path $PackagesRoot "v$currentVersion"

# if the folder does not exist, create it
if (-not (Test-Path $target_folder)) { 
  New-Item -ItemType Container -Path $target_folder | Out-Null
}

# move the build artifact to the target folder
Copy-Item '.cider/build_artifact/Brutal.zip' -Destination $target_folder -Force

# copy the version artifact to the target folder
Copy-Item '.cider/build_artifact/VERSION' -Destination $target_folder -Force
