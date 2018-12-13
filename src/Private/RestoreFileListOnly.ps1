function RestoreFileListOnly {
<#
    Internal function to peer into a set of sqlserver backup
    files to get the database properties of a backup set
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
            [string]$ServerInstance,

        [Parameter(Mandatory=$true,Position=1,ValueFromPipelineByPropertyName=$true)]
            [string[]]$BackupFiles
    )

    $query = "RESTORE FILELISTONLY FROM`n"

    foreach($file in $BackupFiles) {
        $query += "DISK = N'$file'"

        # skip the comma on the last file
        if (($BackupFiles.IndexOf($file)) -eq ($BackupFiles.Count - 1)) {
            $query += "`n"
        }
        else {
            $query += ",`n"
        }
    }

    $query += "WITH FILE = 1"

    $params = @{
        ServerInstance = $ServerInstance
        Database = 'master'
        OutputSqlErrors = $true
        ErrorAction = 'Stop'
        Query = $query
        QueryTimeout = 0
    }

    try {
        $result = Invoke-Sqlcmd @params

        # format the return object
        $return_object = @()

        foreach ($o in $result) {
            $properties = @{
                LogicalName = $o.LogicalName
                PhysicalName = $o.PhysicalName
                Type = $o.Type
            }

            $obj = New-Object -TypeName PSObject -Property $properties

            $return_object += $obj
        }

        Write-Output $return_object
    }
    catch {
        Throw "$($MyInvocation.MyCommand.Name): There was an error restoring the file list. Error Details: $_"
    }
}
