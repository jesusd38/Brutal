2.0.5 2018/04/10
-----------------

* Update Project Reports now uses SSIS Xref in AdminDb

2.0.4 2017/04/21
-----------------

* CID code change ONLY!! The publish script got messed up in 2.0.3. This is just a quick patch to restore
the publishing stage during the master workflow. 

* Packages will now publish here: \\hlnas00\tech\Packages\Brutal

2.0.3 2017/04/21
-----------------

* Fixing the send logging event; had to add the use default credentials switch

2.0.2 (April 2017)
--------------------

* Added Logging through REST service.

2.0.1 (February 2017)
----------------------

* `Update-ProjectReports` no longer requires SSIS Instance as a parameter.

2.0.0 (January 2017)
------------------

* `Get-ProjectProperties` now works with projects that don't have a hosting environment.
* Installation is much simpler and should have more resilience.
* `Update-ProjectReports` now works with all datacenters and the -wait param gives sql agent job info on completion

1.4.2 (August 2016)
------------------
Updating README with data disp workflows

1.4.1 (July 2016)
------------------

* Changed the required version in the manifest file down to 2.0

1.4.0 (July 2016)
------------------

* Added thed changelog file and corresponding test to ensure it stays up-to-date
* Tweaked `Get-LastBackupPath` to ignore failed backups and to pull both COPY_ONLY & Regular FULL backups
* Added the functionality to move a project database (`Move-ProjectDatabase`)
* Cleaned up the old code (everything in the Functions\ folder)
* Added `Restore-InternalDatabase` to restore databases from backup files
* Added `Set-DatabaseReadOnly` & `Set-DatabaseReadWrite` to help with moving project databases
* Added a unit test to check for blank spaces on line endings and fixed all of the issues reported by it. 
* Added a script inthe Examples\ folder to move all of the data disp projects that haven't been moved yet. 
* Tweaked the install script to ignore all of the pester tests and a few additional files on the root. 
