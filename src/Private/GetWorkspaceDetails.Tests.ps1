$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

  Describe 'GetWorkspaceDetails' {

    # There's something weird going on where the mocked command is tripping the warning
    # in the procedure. Can't seem to resolve it.

    $WarningPreference = 'SilentlyContinue'

    beforeEach {
        Mock Invoke-Sqlcmd {
            $custom_props = @{WorkspaceServer = 'UnitTest01';WorkspaceDatabase='UnitTestDB';}
            return New-Object -TypeName PSCustomObject -Property $custom_props
        }
    }

    it 'returns an object' {
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22').GetType().Name | Should Be 'PSCustomObject'
    }

    it 'returns the WorkspaceServer' {
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22').WorkspaceServer | Should Be 'UnitTest01'
    }

    it 'returns the WorkspaceDatabase' {
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22').WorkspaceDatabase | Should Be 'UnitTestDB'
    }

    it 'returns emptry strings when the workspace was not found' {
        Mock Invoke-Sqlcmd { return $null }
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22').WorkspaceServer | Should Be ''
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22').WorkspaceDatabase | Should Be ''
    }

    it 'throws an error when something happens with the query' {
        Mock Invoke-Sqlcmd { Throw 'Access Denied' }

        { GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22' } |
            Should Throw 'There was an error getting the workspace details for H00001 Error Details: Access Denied'
    }

    it 'writes a warning when more than 1 workspace is found' {
        $WarningPreference = 'Continue'
        Mock Invoke-Sqlcmd {
            $custom_props1 = @{WorkspaceServer = 'UnitTest01';WorkspaceDatabase='UnitTestDB';}
            $custom_obj1 = New-Object -TypeName PSCustomObject -Property $custom_props1
            $custom_props2 = @{ WorkspaceServer = 'UnitTest02';WorkspaceDatabase='UnitTestDB2'; }
            $custom_obj2 = New-Object -TypeName PSCustomObject -Property $custom_props1

            return @($custom_obj1, $custom_obj2)
        }
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22' 3>&1) -match 'There were 2 workspaces found. Choosing the first one returned, the results may not be accurate!!' | Should Be $true
    }

    it 'chooses the first workspace returned when more than one are found' {
        $WarningPreference = 'Continue'
        Mock Invoke-Sqlcmd {
            $custom_props1 = @{WorkspaceServer = 'UnitTest01';WorkspaceDatabase='UnitTestDB';}
            $custom_obj1 = New-Object -TypeName PSCustomObject -Property $custom_props1
            $custom_props2 = @{ WorkspaceServer = 'UnitTest02';WorkspaceDatabase='UnitTestDB2'; }
            $custom_obj2 = New-Object -TypeName PSCustomObject -Property $custom_props1

            return @($custom_obj1, $custom_obj2)
        }
        (GetWorkspaceDetails -ProjectCode 'H00001' -EDDSInstance 'UnitTest22' 3>&1).WorkspaceDatabase | Should Be 'UnitTestDB'
    }
  }
}
