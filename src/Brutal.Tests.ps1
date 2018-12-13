$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

$manifestPath   = "$moduleRoot\Brutal.psd1"
$changeLogPath = "$($PWD.Path)\CHANGELOG.md" # this works too: "$PWD\CHANGELOG.md"

Import-Module "$moduleRoot\Brutal.psm1" -Force

Describe 'Version Checks' {

    $script:manifest = $null
    It "has a valid manifest" {
        {$script:manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop -WarningAction SilentlyContinue } | Should Not Throw
    }

    It "has a valid name in the manifest" {
        $script:manifest.Name | Should Be Brutal
    }

    It "has a valid guid in the manifest" {
        $script:manifest.Guid | Should Be '42b82da3-f6c7-411e-b680-9d4df385a67a'
    }

    It "has a valid version in the manifest" {
        $script:manifest.Version -as [Version] | Should Not BeNullOrEmpty
    }

    $script:changelogVersion = $null
    It "has a valid version in the changelog" {

        foreach ($line in (Get-Content $changeLogPath))
        {
            if ($line -match "^\D*(?<Version>(\d+\.){1,3}\d+)")
            {
                $script:changelogVersion = $matches.Version
                break
            }
        }
        $script:changelogVersion                | Should Not BeNullOrEmpty
        $script:changelogVersion -as [Version]  | Should Not BeNullOrEmpty
    }

    It "changelog and manifest versions are the same" {
        $script:changelogVersion -as [Version] | Should be ( $script:manifest.Version -as [Version] )
    }

    <# One day maybe getting this working
    if (Get-Command git.exe -ErrorAction SilentlyContinue)
    {
        $skipVersionTest = -not [bool]((git remote -v 2>&1) -match "github.consilio.com/CID/Brutal")
        $script:tagVersion = $null
        It "is tagged with a valid version" -skip:$skipVersionTest {
            $thisCommit = git.exe log --decorate --oneline HEAD~1..HEAD

            if ($thisCommit -match 'tag:\s*(\d+(?:\.\d+)*)')
            {
                $script:tagVersion = $matches[1]
            }

            $script:tagVersion                  | Should Not BeNullOrEmpty
            $script:tagVersion -as [Version]    | Should Not BeNullOrEmpty
        }

        It "all versions are the same" -skip:$skipVersionTest {
            $script:changelogVersion -as [Version] | Should be ( $script:manifest.Version -as [Version] )
            $script:manifest.Version -as [Version] | Should be ( $script:tagVersion -as [Version] )
        }

    }
    #>

}

Describe 'Style rules' {
    $brutalRoot = (Get-Module Brutal).ModuleBase

    $files = @(
        Get-ChildItem $brutalRoot -Include *.ps1,*.psm1
        Get-ChildItem $brutalRoot\Private -Include *.ps1,*.psm1 -Recurse
        Get-ChildItem $brutalRoot\Public -Include *.ps1,*.psm1 -Recurse
    )

    <# Not working at the moment
    It 'Brutal source files contain no formatting lines with blank charaters' {
        $badLines = @(
            foreach ($file in $files)
            {
                $lines = [System.IO.File]::ReadAllLines($file.FullName)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++)
                {
                    if ([string]::IsNullOrWhiteSpace($lines[$i])) {
                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0)
        {
            throw "The following $($badLines.Count) lines contain only whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }

    }
    #>

    It 'Brutal source files contain no trailing whitespace' {
        $badLines = @(
            foreach ($file in $files)
            {
                $lines = [System.IO.File]::ReadAllLines($file.FullName)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++)
                {
                    if ($lines[$i] -match '\s+$')
                    {
                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0)
        {
            throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }
    }

    It 'Brutal Source Files all end with a newline' {
        $badFiles = @(
            foreach ($file in $files)
            {
                $string = [System.IO.File]::ReadAllText($file.FullName)
                if ($string.Length -gt 0 -and $string[-1] -ne "`n")
                {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0)
        {
            throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }
}

Describe 'General Rules' {
    InModuleScope Brutal {
        
        $commands = @(
            Get-Command -Module Brutal
        )

        It 'All Brutal functions have a corresponding unit test' {
            $UnitTestFiles = @(
                Get-ChildItem $moduleRoot -Include *.Tests.ps1 -Recurse | %{ $_.Name.Replace('.Tests.ps1','').Trim() }
            )

            $noTests = @(
                foreach($command in $commands) {
                    if($command -notin $UnitTestFiles) {
                        $command
                    }
                }   
            )

            if ($noTests.Count -gt 0) {            
                throw "the following commands had no unit tests found: $($noTests -join "`r`n")"
            }
        }
    }
}
