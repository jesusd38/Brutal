<#
    .SYNOPSIS
    This script finds the most recent full backup of a database and restores it to another server.

    .DESCRIPTION
    With user provided source and target server and database information, this script leverages SMO
    and sqlps to query MSDB on the source instance for the database of interest's most recent full
    backup. This file is copied to the default backup directory of the target server to insure the
    service account has access. Then, SMO's Restore class and SqlRestore method are used to read
    the backup file list, move the files to the appropriate default data and log paths for the target
    server, and then execute the restore. If the target database already exists, it is set to single
    user mode before the restore operation. After the restore, the backup file is deleted.

    .NOTES
    This script makes the follow assumptions:
    - The assemblies Microsoft.SqlServer.Smo and Microsoft.SqlServer.SmoExtended are available.
    - The sqlps module is available.
    - The executor has read permissions for MSDB backup information on the source server.
    - The executor has admin access to the target server (for admin drive access during file copy).
    - The executor has RESTORE permissions on the target server.
    - Automatic target instance identification assumes the project is using Cider.

    .PARAMETER SourceServerInstanceName
    The name of the SQL Server instance hosting the database to be copied.

    .PARAMETER SourceDatabaseName
    The name of the SQL Server database to be copied.

    .PARAMETER TargetServerInstanceName
    The name of the SQL Server instance to which the database should be copied.

    .PARAMETER TargetDatabaseName
    The name to be given to the copy of the source database.

    .EXAMPLE
    Invoke-SeekAndRestore -SourceServerInstanceName 'SQLSERVER\SQLINSTANCE1' -SourceDatabaseName 'Database' -TargetServerInstanceName 'SQLSERVER2' -TargetDatabaseName 'Database_Copy'
    This finds the most recent full database backup of database Database on SQLSERVER\SQLINSTANCE1 and restores
    it to SQLSERVER2's default instance as Database_Copy with named parameters.

    .EXAMPLE
    Invoke-SeekAndRestore -SourceServerInstanceName 'SQLSERVER\SQLINSTANCE1' -SourceDatabaseName 'Database'
    This finds the most recent full database backup of database Database on SQLSERVER\SQLINSTANCE1 and restores
    it to the default instance of the host most recently provisioned by Cider with the name 'Database'.

    .EXAMPLE
    Invoke-SeekAndRestore -SourceServerInstanceName 'SQLSERVER\SQLINSTANCE1' -SourceDatabaseName 'Database' -TargetDatabaseName 'Database_Copy'
    This finds the most recent full database backup of database Database on SQLSERVER\SQLINSTANCE1 and restores
    it to the default instance of the host most recently provisioned by Cider with the name 'Database_Copy'.

    .EXAMPLE
    $parms = @{ SourceServerInstanceName = 'SQLSERVER\SQLINSTANCE1'
                SourceDatabaseName = 'Database'
                TargetServerInstanceName = 'SQLSERVER2'
                TargetDatabaseName = 'Database_Copy'
                }
    Invoke-SeekAndRestore @parms
    This finds the most recent full database backup of database Database on SQLSERVER\SQLINSTANCE1 and restores
    it to SQLSERVER2's default instance as Database_Copy with "splatted" parameters.
#>
function Invoke-SeekAndRestore
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string] $SourceServerInstanceName,

        [Parameter(Mandatory=$true, Position=1)]
        [string] $SourceDatabaseName,

        [Parameter(Position=2)]
        [string] $TargetServerInstanceName,

        [Parameter(Position=3)]
        [string] $TargetDatabaseName = $SourceDatabaseName
    ) # end parameters
    
    begin {
        $currentLocation = (Get-Location).Path

        # Load required components
        Write-Verbose "Loading sqlps, Microsoft.SqlServer.Smo, Microsoft.SqlServer.SmoExtended..."
        try {
            Import-Module "sqlps" -DisableNameChecking | Write-Verbose
        }
        catch {
            Throw
        }
        finally {
            Set-Location $currentLocation
        }
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Write-Verbose
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Write-Verbose
    } # end begin
    
    process {

        # If $TargetServerInstanceName is not filled in, grab it from the provision_artifact folder
        if ( -not ($TargetServerInstanceName)) {

            $ProvisionDrop = ".cider\provision_artifact", "provision_artifact" | Where-Object { $_ | Test-Path } | Select-Object -First 1

            # If $ProvisionDrop still isn't set, throw an error
            if ( -not ($ProvisionDrop)) { Throw '$TargetServerInstanceName was not set and this could not locate a provision artifact to use' }
            
            # Try to find some json files in the provisionDrop folder
            $TargetServerInstanceName = Get-ChildItem -Path $ProvisionDrop -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

            # If target server is still not set, throw an error!
            if ( -not ($TargetServerInstanceName)) { Throw '$TargetServerInstanceName was not set and we may have found the wrong provision_artifact folder, try specifying the correct one using $ProvisionDrop' }

            # $TargetServerInstanceName looks like this: C:\_SourceControl\HLTFS\Tools\Release Tracker\Main\Database\.cider\provision_artifact\MLVDAC08.json
            # Fix it to look like this: MLVDAC08
            $TargetServerInstanceName = $TargetServerInstanceName.Substring($TargetServerInstanceName.LastIndexOf('\') + 1).Replace('.json','')
        }

        $TargetServer = New-Object Microsoft.SqlServer.Management.Smo.Server $TargetServerInstanceName

        If ( -not $TargetServer.Databases.Contains($TargetDatabaseName)) {
            Write-Verbose "Retrieving necessary data..."
            
            # This query retrieves the full path of the most recently completed full database backup
            $RetrieveBackupPathQuery = @"
            SELECT TOP 1 [backupmediafamily].[physical_device_name]
            FROM        [msdb].[dbo].[backupset]
                        INNER JOIN
                        [msdb].[dbo].[backupmediafamily] ON [backupmediafamily].[media_set_id] = [backupset].[media_set_id]
            WHERE       [backupset].[database_name] = N'$SourceDatabaseName'
                        AND
                        [backupset].[type] = 'D' -- we only want full database backups
            ORDER BY    [backupset].[backup_finish_date] DESC;
"@
            <#
                We execute against MSDB because that is the database containing our data and because it will
                surface lack of permissions as a connection error instead of a T-SQL error (Emil hopes...)
            #>
            $QueryResults = Invoke-Sqlcmd -ServerInstance $SourceServerInstanceName -Database msdb -Query $RetrieveBackupPathQuery -OutputSqlErrors $true
            $mostRecentBackupPath = $QueryResults[0].ToString()
            
            # Make sure we have a UNC backup path to copy from
            If (-not $mostRecentBackupPath.StartsWith('\\')) {
                $SourceServer = New-Object Microsoft.SqlServer.Management.Smo.Server $SourceServerInstanceName
            
                $SourceHostName = "\\{0}" -f $SourceServer.ComputerNamePhysicalNetBIOS
                $SourceDriveName = "{0}{1}" -f $mostRecentBackupPath.Substring(0, $mostRecentBackupPath.IndexOf(':')), "$"
                $SourcePath = $mostRecentBackupPath.Substring($mostRecentBackupPath.IndexOf('\')+1)
                $mostRecentBackupPathUNC = Join-Path -Path $(Join-Path -Path $SourceHostName -ChildPath $SourceDriveName) -ChildPath $SourcePath
            } # end set source backup admin UNC
            Else {
                $mostRecentBackupPathUNC = $mostRecentBackupPath
            } # end source backup is UNC
            
            Write-Verbose "Most recent UNC backup path: $mostRecentBackupPathUNC"
            
            $TargetBackupDirectory = $TargetServer.BackupDirectory
            
            # Make sure we have a UNC directory to target when copying the backup
            If (-not $TargetServer.BackupDirectory.StartsWith('\\')) {
                $TargetHostName = "\\{0}" -f $TargetServer.ComputerNamePhysicalNetBIOS
                $TargetDriveName = "{0}{1}" -f $TargetBackupDirectory.Substring(0, $TargetBackupDirectory.IndexOf(':')), "$"
                $TargetDirectoryNames = $TargetBackupDirectory.Substring($TargetBackupDirectory.IndexOf('\')+1)
                $TargetBackupDirectoryUNC = Join-Path -Path $(Join-Path -Path $TargetHostName -ChildPath $TargetDriveName) -ChildPath $TargetDirectoryNames
            } # end set target backup admin UNC
            Else {
                $TargetBackupDirectoryUNC = $TargetBackupDirectory
            } # end target backup is UNC
            
            $BackupFileName = [System.IO.Path]::GetFileName($mostRecentBackupPath)
            # Because the script may not be running on the target server, we need a UNC name to check after the file copy
            $TargetBackupPathUNC = Join-Path -Path $TargetBackupDirectoryUNC -ChildPath $BackupFileName
            # SMO wraps T-SQL commands, and the restore is happening locally as far as SQL Server is concerned
            $TargetBackupPath = Join-Path -Path $TargetBackupDirectory -ChildPath $BackupFileName
            
            Write-Verbose "TargetBackupPathUNC: $TargetBackupPathUNC"
            Write-Verbose "TargetBackupPath: $TargetBackupPath"
            
            Write-Host "Starting file copy of backup... (this may take quite some time)" | Write-Verbose
            Try {
                Copy-Item -Path $mostRecentBackupPathUNC -Destination $TargetBackupDirectoryUNC
            }
            Catch {
                Write-Verbose "Access to target UNC backup directory? $(Test-Path -Path $TargetBackupDirectoryUNC)"
                Throw
            } # end backup copy Try...Catch
            
            If ((Test-Path $TargetBackupPathUNC) -eq $true) {
                $backupDevice = New-Object("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($TargetBackupPath, "File")
                $smoRestore = New-Object("Microsoft.SqlServer.Management.Smo.Restore")
            
                Write-Verbose "Setting restore parameters..."
                $smoRestore.NoRecovery = $false
                $smoRestore.ReplaceDatabase = $true
                $smoRestore.Action = "Database"
                $smoRestore.Database = $TargetDatabaseName
                $smoRestore.Devices.Add($backupDevice)
            
                Write-Verbose "Setting new file locations..."
                Try {
                    $smoRestore.ReadFileList($TargetServer) |
                        ForEach-Object {
                        $relocatedBackupFile = New-Object -TypeName Microsoft.SqlServer.Management.Smo.RelocateFile
                        $relocatedBackupFile.LogicalFileName = $_.LogicalName
            
                        If ($_.Type -eq "D") {
                            $newPhysicalPath = Join-Path -Path $TargetServer.DefaultFile -ChildPath $([System.Io.Path]::GetFileName($_.PhysicalName))
                        } # end if D
                        ElseIf ($_.Type -eq "L") {
                            $newPhysicalPath = Join-Path -Path $TargetServer.DefaultLog -ChildPath $([System.Io.Path]::GetFileName($_.PhysicalName))
                        } # end if L
            
                        $relocatedBackupFile.PhysicalFileName = $newPhysicalPath
            
                        # This function returns the index of the added file, about which we don't care
                        $smoRestore.RelocateFiles.Add($relocatedBackupFile) | Out-Null
                    } # end foreach backup file
                }
                Catch {
                    Throw
                } # end Try...Catch ReadFileList
            
            
                Write-Verbose "Starting restore..."
                Try {
                    $smoRestore.SqlRestore($TargetServer)
                }
                Catch {
                    $Error[0] | Format-Wide -Property Exception -Force
                    Throw
                } # end restore
            
                Write-Host "Database restored! Removing backup file..."
                Remove-Item -Path $TargetBackupPathUNC -Force
            } # end if restore file exists
            Else {
                Throw "The expected backup file ($BackupFileName) does not exist in the expected location ($TargetBackupDirectoryUNC). Aborting..."
            } # end if restore file does not exist
        } # end if target db does not exist
        Else {
            Write-Verbose "Target database ($TargetDatabaseName) already exists on target server ($TargetServerInstanceName). We assume whatever's there is recent enough. No action taken."
            <#
                We do this because copying backup files adds significant time to deployments, and a fresher
                copy can be gotten by spinning up a new instance.
                TODO: Enable forced database overwrite.
            #>
        } # end if target db exists
    } # end process
} # end function

$TargetDatabaseName = 'RegulatoryResearch'

Invoke-SeekAndRestore -SourceServerInstanceName 'MPLSQLV03\INSTANCE3' -SourceDatabaseName 'RegulatoryResearch_Prod' -TargetDatabaseName $TargetDatabaseName -Verbose

# If we have a post-restore script, run it
$ProvisionDrop = ".cider\provision_artifact", "provision_artifact" | Where-Object { $_ | Test-Path } | Select-Object -First 1

if ($ProvisionDrop) {
    
    <#
        We are pushing US19580 automatically to the test environment via this hack, but it puts RegResearch into the necessary state to
        complete the final pieces of its integration with RRS (until we can split them again...).

        Note that this script MUST be safe to rerun if anyone every borrows this code.
    #>
    $PostRestoreScript = Get-ChildItem -Path $ProvisionDrop -Filter US19580_deployment.sql | Select-Object -First 1 -ExpandProperty FullName
    
    if ($PostRestoreScript) {
        <#
            We need to determine where to deploy these changes. The default expectation while using this hack-y
            script is that we're deploying to the most recently provisioned instance - just as implied by our
            Invoke-SeekAndRestore call above. Using the same logic from the function to get the target server.
        #>
        # Try to find some json files in the provisionDrop folder
        $TargetServerInstanceName = Get-ChildItem -Path $ProvisionDrop -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

        # If target server is still not set, throw an error!
        if ( -not ($TargetServerInstanceName)) { Throw '$TargetServerInstanceName was not set for post-restore and we may have found the wrong provision_artifact folder. Emil or Nick need to get in here and fix something, poor chaps.' }

        # $TargetServerInstanceName looks like this: C:\_SourceControl\HLTFS\Tools\Release Tracker\Main\Database\.cider\provision_artifact\MLVDAC08.json
        # Fix it to look like this: MLVDAC08
        $TargetServerInstanceName = $TargetServerInstanceName.Substring($TargetServerInstanceName.LastIndexOf('\') + 1).Replace('.json','')

        # Run our post-restore script
        Invoke-Sqlcmd -ServerInstance $TargetServerInstanceName -Database $TargetDatabaseName -InputFile $PostRestoreScript -OutputSqlErrors $true
    }
    else {
        Write-Verbose "No post-restore script found."
    }
}
else {
    Throw 'Could not access provision artifact path to check for post-restore script.'
} # end if...else $ProvisionDrop