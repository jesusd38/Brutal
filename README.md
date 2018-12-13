# Brutal
A powershell module for automating some of the most brutal sql server tasks. 

[![Build Status](https://jenkins.consilio.com/buildStatus/icon?job=CID/workflows/Brutal/master)](https://jenkins.consilio.com/job/CID/job/workflows/job/Brutal/job/master/)

### Important!
Use caution when using these functions in the pipeline. I've tried to add all the pipeline support required, 
but there could be some gaps. If you notice something odd or not functioning as expected, please log an issue!

## Functions
- ### Backup-InternalDatabase (**BETA**)
	- Get's the last backup location from CommandLog and then cuts a new full backup to that network share.

- ### Restore-InternalDatabase (**BETA**) (**NEW-1.4.0**)
	- The corresponding function to `Backup-InternalDatabase`, this function will restore a database based on the last
	restored path returned in `Get-LastBackupPath`
	
- ### Get-ProjectProperties
	- Returns a project object containing connection information to the project databases, workspace databases, etc. 
	Really helpful with the distributed project model - In one command, I can get both the projectDB & WorkspaceDB connections.
	
- ### Update-DatabaseIndexes (**BETA**)
	- A newer function to execute Ola's index optimize scripts against a database. This is extremely helpful when working on tickets
	reporting slow portal executions.
	
- ### Update-ProjectReports (**BETA**)
	- A newer function to manually refresh all of the reports for any single project. This basically just tweaks the SSIS environment variables, 
	specifically the loadProjectCode variable and then executes the single_project stored procedure. This one requries special permission on our SSIS
	box and should only be used by people familiar with the manual process.
    - New output to show job status!
    ![Update-ProjectReports output](docs/images/UpdateProjectReports.png?raw=true)

- ### Get-LastBackupPath
	- Gets a database's last backup path from Ola's commandLog table. This is helpful when trying to restore from a copy of production. Use
	this command to get any database's last backup path from the network.

- ### Move-ProjectDatabase (**BETA**) (**NEW-1.4.0**)
	- **Please do not use unless you're absolutely sure you know what you're doing!** This function will move (**NOT COPY**) a project database
	from one server to another. This is useful for rebalancing project servers as well as moving old projects off after they've been disposed. 

- ### Set-DatabaseReadOnly (**NEW-1.4.0**)
	- New function to set a database to read-only mode.

- ### Set-DatabaseReadWrite (**NEW-1.4.0**)
	- New functoin to set a database to read-write mode.

## Install

#### Pre-Reqs
1. SqlPs module (installed by default with a SQL Server install, otherwise need to get it online if possible)

#### Step-by-Step
Option 1:

Get the latest package from the build drop \\hlnas00\tech\Packages\Brutal
Extract it to a temp folder
Right-Click "install.bat" and choose "Run as Administrator"
Option 2:

Clone/Pull the repo
Right-Click 'install.bat' and choose "Run as Administrator"

If the steps do not error, then you should be good to use the functions in the module without importing them first. For example, 
I could just open up a powershell window and type `Get-ProjectProperties H11824` and that projects information would be returned back to me.

## Examples

### Move a single project to the data disp server when status in AdminDB changed to 9

```posh
<#
    Script to move just one US projects marked with a status of 9 (data disp)
    to our data disp server (MLVPDPRJ01) if it hasn't already been moved.
#>

$AdminDBInstance = 'MTPVPDSQLP06\PROJP11'

# requires Brutal Module
Import-Module Brutal

# find any data disp projects that have not been moved over to the data disp server. 
# criteria = Project.DomainProjectStatusID = 9; Project.ServerName NOT IN ('MLVPDPRJ01','HLUKSQLENGP11\PROJP11')
# have to ignore data disp projects in the UK for now. 
$query = "
    SELECT p.ProjectCode
    FROM ADMIN.Project p
    WHERE p.DomainProjectStatusID = 9 AND p.DatabaseServer NOT IN ('MLVPDPRJ01','HLUKSQLENGP11\PROJP11')"

$params = @{
    ServerInstance = $AdminDBInstance
    Database = 'AdminDB'
    OutputSqlErrors = $true
    ErrorAction = 'Stop'
    Query = $query
}

$dispProjects_notMoved = Invoke-Sqlcmd @params

# as a test, we'll only run 1
$Project = $dispProjects_notMoved | Where-Object { $_.ProjectCode -eq 'H11565' }
    
try {
    # Move the project databases
    Move-ProjectDatabases -ProjectCode $Project.ProjectCode -TargetInstance 'MLVPDPRJ01' -AdminDBInstance 'MTPVPDSQLP06\PROJP11' -Verbose

    # Need to set the databases to read only - Get the project properties which should say the 
    # new location and for each of the databases, set them to read-only
    $_props = Get-ProjectProperties $Project.ProjectCode

    foreach($db in $_props.ProjectDatabases) {
        Set-DatabaseReadOnly -DatabaseName $db -ServerInstance $_props.ProjectServer
    }
}
catch {
    Throw
}

```

### Move all of the newly dispose projects to the data disp server

Under the brutal installation folder there should be a script: `docs/examples/Move-DataDispProjects.ps1` containing the logic.
You should be able to just call it from any cmd or powershell session

```posh
Set-Location $BrutalDirectory
. ./docs/examples/Move-DataDispProjects.ps1
```

```
cd path\to\brutal
powershell.exe & ". ./docs/examples/Move-DataDispProjects.ps1; exit $LastExitCode"
```


Get project properties for a project.

```posh
PS C:\_source\git> Get-ProjectProperties H12722


ProjectCode       : H12722
ProjectID         : 7689
ProjectServer     : MTPVPDSQLP02
ProjectDatabases  : {H12722_EDD, H12722_ETL}
ReviewCampus      : Chicago
WorkspaceServer   : HLSQLDRELP03\DRELP03
WorkspaceDatabase : EDDS3541698
```

Update a project's Relativity workspace index statistics - 
* SearchHitReports
	
```posh
PS C:\_source\git> Get-ProjectProperties H11824 | Update-DatabaseIndexes -UpdateIndexes Workspace
```

Update a project's processing index statistics
* Exceptions Report
* Suppression Report
* File Type Report
* Nuix Export Summary
* Processing Export Set
* Source Media Report
	
```posh
PS C:\_source\git> Get-ProjectProperties H11824 | Update-DatabaseIndexes -UpdateIndexes Project
```

Set a database to read-only mode and then back to read-write again - 

```posh
PS C:\_source\git\Brutal> Set-DatabaseReadOnly -DatabaseName 'H00000_EDD' -ServerInstance '(local)'

PS C:\_source\git\Brutal> Set-DatabaseReadWrite -DatabaseName 'H00000_EDD' -ServerInstance '(local)'
```

Move a project database from the source instance (pulled from AdminDB) to MLVPDPRJ01 - 

```posh
PS C:\_source\git\Brutal> Move-ProjectDatabases -ProjectCode H11824 -TargetInstance 'MLVPDPRJ01' -AdminDBInstance 'MTPVPDSQLP06\PROJP11' -Verbose
```

Make a copy-only backup of a database - 

```posh
PS C:\_source\git\Brutal> Backup-InternalDatabase -DatabaseName 'H11824_EDD' -ServerInstance 'MTPVPDSQLP03'
```

Restore a backup to a server (using `Get-LastBackupPath` to pull the last backup files) - 

```posh
PS C:\_source\git\Brutal> $lastBackupPaths = Get-LastBackupPath -ServerInstance 'MTPVPDSQLP03' -DatabaseName 'H11824_EDD'
PS C:\_source\git\Brutal> Restore-InternalDatabase -DatabaseName 'H11824_EDD' -ServerInstance '(local)' -BackupFiles $lastBackupPaths.BackupFiles
```

Get the last backup paths of a database -

```posh
PS C:\_source\git\Brutal> Get-LastBackupPath -ServerInstance 'MTPVPDSQLP05' -DatabaseName 'H11824_EDD'

DatabaseName BackupFiles                                                                                                                                                                                 
------------ -----------                                                                                                                                                                                 
H11824_EDD   {\\hlnas10\sqlbk_fprojp11\MTPVPDSQLP05\H11824_EDD\FULL\MTPVPDSQLP05_H11824_EDD_FULL_20160617_231524_1.bak, \\hlnas10\sqlbk_fprojp11\MTPVPDSQLP05\H11824_EDD\FULL\MTPVPDSQLP05_H11824_EDD_...
```



## What's Next?
* Finish/Polish the `Invoke-SeekAndRestore` stuff.. A lot of really AWESOME work has gone into this. Basically it should allow us all as 
developers to get a copy of production restored with one command. The code is all here, just not exposed publically because there are still
a couple of kinks to work out.. Mainly the varying configuration settings of all of our servers. works here, not there, etc. 

* Get a database server stood up and configured with one command. 

## Contributing
Seriously, all contributions are welcome! Issues, bug reports, or code.. no matter - it's all important!

1. Fork the repo
2. Create a feature branch `git checkout -b awesome-new-branch`
3. Add your code (tests included), commit it, and push it back up to your fork.
4. Create a PR against master
5. Notify Nick Hudacin for review!


## Notes

Honestly, not sure where to store this information... 

* Had to import the sqlps module in the checkpoint-auditstart test to get the unit tests
to work. This is really brittle as it's probably an order of operations thing which could
change with newer version of pester. 