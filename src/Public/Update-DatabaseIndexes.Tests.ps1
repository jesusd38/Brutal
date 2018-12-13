$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'Update-DatabaseIndexes' {

    beforeEach {
        $customProps = @{
                ProjectCode = 'UTPROJ01'
                ProjectID = 1
                ProjectServer = 'PROJSERVER01'
                ProjectDatabases = @('UTPROJ01_EDD', 'UTPROJ01_ETL')
                WorkspaceServer = 'RELSERVER01'
                WorkspaceDatabase = 'RELDB01'
            }
        $myProjectObject = New-Object -TypeName PSCustomObject -Property $customProps

        Mock Get-ProjectProperties {
            return $myProjectObject
        }

        Mock RunIndexOptimize { }
    }

    it 'looks up the project code when passed in as a parameter' {
        Update-DatabaseIndexes 'UTPROJ01'
        Assert-MockCalled Get-ProjectProperties -Exactly 1 -Scope It
    }

    it 'looks up the project code when passed thru the pipeline' {
        'UTPROJ01' | Update-DatabaseIndexes
        Assert-MockCalled Get-ProjectProperties -Exactly 1 -Scope It
    }

    it 'skips the project lookup when a project object is passed in as a parameter' {
        Update-DatabaseIndexes -Project $myProjectObject
        Assert-MockCalled Get-ProjectProperties -Exactly 0 -Scope It
    }

    it 'skips the project lookup when a project object is passed in thru the pipeline' {
        $myProjectObject | Update-DatabaseIndexes
        Assert-MockCalled Get-ProjectProperties -Exactly 0 -Scope It
    }

    it 'runs the index optimize when passing in a server and database' {
        Update-DatabaseIndexes -ServerInstance 'UT01' -DatabaseName 'DB01'

        # Make sure project wasn't looked up
        Assert-MockCalled Get-ProjectProperties -Exactly 0 -Scope It

        # Generic Assert - Make sure it's only called once
        Assert-MockCalled RunIndexOptimize -Exactly 1 -Scope It

        # Specific Assert - Make sure the correct properties are passed thru
        Assert-MockCalled RunIndexOptimize -ParameterFilter { ($DatabaseName -eq 'DB01') -and ($ServerInstance -eq 'UT01') } -Exactly 1 -Scope It
    }

    it 'only runs the indexes on the _EDD database' {
        $myProjectObject | Update-DatabaseIndexes
        Assert-MockCalled RunIndexOptimize -ParameterFilter { $DatabaseName -eq 'UTPROJ01_EDD' } -Exactly 1 -Scope It
    }

    it 'runs the index optimize on the correct project server' {
        $myProjectObject | Update-DatabaseIndexes
        Assert-MockCalled RunIndexOptimize -ParameterFilter { $ServerInstance -eq 'PROJSERVER01' } -Exactly 1 -Scope It
    }

    it 'runs the index optimize on the correct workspace database' {
        $myProjectObject | Update-DatabaseIndexes -UpdateIndexes 'Workspace'
        Assert-MockCalled RunIndexOptimize -ParameterFilter { $ServerInstance -eq 'RELSERVER01' } -Exactly 1 -Scope It
    }

    it 'runs the index optimize on the correct workspace server' {
        $myProjectObject | Update-DatabaseIndexes -UpdateIndexes 'Workspace'
        Assert-MockCalled RunIndexOptimize -ParameterFilter { $DatabaseName -eq 'RELDB01' } -Exactly 1 -Scope It
    }

    it 'runs the index optimize on both databases when specified' {
        $myProjectObject | Update-DatabaseIndexes -UpdateIndexes 'Both'
        Assert-MockCalled RunIndexOptimize -Exactly 2 -Scope It
    }

    it 'runs the full index rebuild when specified' {
        $myProjectObject | Update-DatabaseIndexes -Full
        Assert-MockCalled RunIndexOptimize -ParameterFilter { $Full -eq $true } -Exactly 1 -Scope It
    }
  }
}
