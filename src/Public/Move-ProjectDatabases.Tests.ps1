$moduleRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Import-Module "$moduleRoot\Brutal.psm1" -Force

InModuleScope Brutal {

    Describe 'Move-ProjectDatabases' {

        $commonParams = @{
            ProjectCode = 'H99999'
            TargetInstance = 'UTTarget01'
            AdminDBInstance = 'AdminDB01'
        }

        beforeEach {
            Mock Get-ProjectProperties { }
            Mock Checkpoint-AuditStart { }
            Mock Confirm-DatabaseReadyToMove { }
            Mock Checkpoint-BackupStart { }
            Mock Set-DatabaseReadOnly { }
            Mock Backup-InternalDatabase { }
            Mock Get-LastBackupPath { }
            Mock Checkpoint-RestoreStart { }
            Mock Restore-InternalDatabase { }
            Mock Set-DatabaseReadWrite { }
            Mock Checkpoint-MoveComplete { }
            Mock Checkpoint-MoveFailed { }
            Mock UpdateProjectProperties { }
            Mock GetDatabaseStatus { }
            Mock DropDatabase { }

        }

        it 'does nothing' {
            1 | Should Be 1
        }
    }
}
