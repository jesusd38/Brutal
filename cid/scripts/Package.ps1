# this script will package Brutal up. It's used by the workflow
# be mindful what directory you run this from. this EXPECTS to be
# run from the repo root!

# load helpers
"cid\helpers\*.ps1" |
    Resolve-Path |
        Where-Object { -not ($_.ProviderPath.ToLower().Contains('.tests.')) } |
            ForEach-Object { . $_.ProviderPath }

# create a temporary folder to hold the files
do {
  $tempLocation = Join-Path -Path $env:TEMP -ChildPath ('cider-' + [Guid]::NewGuid())
} until (-not (  Test-Path -Path $tempLocation ))

New-Item -ItemType Container -Path $tempLocation | Out-Null

# holding the full path to ./src as it's being referenced everywhere
$src_path = "$((Get-Location).Path)\src"

# these are all the files that should not be packaged. 
# we should be able to go back thru and combine some of these entries
$exclude_from_package = @(
  'Private/*.tests.ps1',
  'Public/*.tests.ps1',
  '*.tests.ps1'
)

# Compare-Directory comes from Cider; Cider is a dependency
$files = Compare-Directory -Source $src_path -Target $tempLocation -Exclude $exclude_from_package

# move the new files over to the tempLocation
# parent directories must be created in the tempLocation
# if they do not exist
foreach($file in $files) {
  
  $source_path = Join-Path $src_path $file.RelativePath
  $target_path = Join-Path $tempLocation $file.RelativePath

  # if parent path not exists, create it!
  if (-not ( Test-Path $(Split-Path $target_path -parent))) {
    New-Item -ItemType Container -Path $(Split-Path $target_path -parent) | Out-Null
  }

  # copy the file over
  Copy-Item -Path $source_path -Destination $target_path  
}

# make sure the build_artifact path exists
if(-not (Test-Path .cider\build_artifact)) { New-Item -ItemType Container -Path .cider\build_artifact | Out-Null }
else {
  # remove everything from the path
  Get-ChildItem -Path '.cider\build_artifact' | Remove-Item -Recurse -Force
}

$build_package = ".cider\build_artifact\Brutal.zip"
$version_artifact = '.cider\build_artifact\VERSION'

# cleanup the prior runs
if (Test-Path $build_package) { Remove-Item $build_package }
if (Test-path $version_artifact) { Remove-Item $version_artifact }

$version = _getVersion
$build_package = ".cider\build_artifact\Brutal.zip"

# zip up the artifact
7z @('a',$build_package,'-tzip',"-i!$tempLocation\*" ) | Write-Verbose

# write out the version 
$version | Out-File -FilePath $version_artifact -Encoding ascii -NoNewline

# let's cleanup after ourselves
Remove-Item $tempLocation -Recurse -Force
