$moduleRoot = Split-Path -Parent ( Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
Import-Module "$moduleRoot\src\Brutal.psd1" -Force

InModuleScope Brutal {
  describe 'Get-ProjectProperties Integration Tests' -Tags 'Integration'  {
    $currentLocation = (Get-Location).Path

    # This test might start failing if this project gets a review workspace
    it 'should return projects without review workspaces' {
      $results = Get-ProjectProperties -ProjectCode 'H10219'      
      $results.ProjectCode | should not be $null
      $results.ProjectID | should not be $null
      $results.ProjectServer | should not be $null
      $results.ReviewCampus | should be ''
      $results.WorkspaceServer | should be $null
      $results.WorkspaceDatabase | should be $null
    }
  }
}