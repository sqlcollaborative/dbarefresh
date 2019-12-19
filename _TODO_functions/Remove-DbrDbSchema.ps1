function Remove-DbrDbSchema {

    <#
    .SYNOPSIS
        Remove the schema

    .DESCRIPTION
        Remove the schema in a database

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Windows and SQL Authentication supported. Accepts credential objects (Get-Credential)

    .PARAMETER Database
        Database to remove the schema from

    .PARAMETER Schema
        Filter based on schema

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Remove-DbrDbSchema -SqlInstance sqldb1 -Database DB1

        Remove all the schema from the database

    .EXAMPLE
        Remove-DbrDbSchema -SqlInstance sqldb1 -Database DB1 -StoredProcedure PROC1, PROC2

        Remove all the schema from the database with the name PROC1 and PROC2

    #>

    [CmdLetBinding(SupportsShouldProcess)]

    param(
        [parameter(Mandatory)]
        [DbaInstanceParameter]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string]$Database,
        [string]$Schema,
        [switch]$EnableException
    )

    begin {
        $progressId = 1

        # Get the schema
        $db = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $Database

        $task = "Removing schemas"

        # Filter out the schema based on schema
        Write-Progress -Id ($progressId + 2) -ParentId ($progressId + 1) -Activity $task

        try {
            $schemas = @()
            $schemas += $db.Schemas | Where-Object IsSystemObject -eq $false | Sort-Object Name
        }
        catch {
            Stop-PSFFunction -Message "Could not retrieve schemas from source instance" -ErrorRecord $_ -Target $SourceSqlInstance
        }

        if ($Schema) {
            $schemas = $schemas | Where-Object Name -in $Schema
        }
    }

    process {
        $totalObjects = $schemas.Count
        $objectStep = 0

        if ($totalObjects -ge 1) {
            if ($PSCmdlet.ShouldProcess("Removing schema in database $Database")) {

                $task = "Removing Schema(s)"

                foreach ($object in $schemas) {
                    $objectStep++
                    $operation = "Schema [$($object.Name)]"

                    $params = @{
                        Id               = ($progressId + 2)
                        ParentId         = ($progressId + 1)
                        Activity         = $task
                        Status           = "Progress-> Schema $objectStep of $totalObjects"
                        PercentComplete  = $($objectStep / $totalObjects * 100)
                        CurrentOperation = $operation
                    }

                    Write-Progress @params

                    Write-PSFMessage -Level Verbose -Message "Dropping schema [$($object.Name)] from $Database"

                    try {
                        ($db.Schemas | Where-Object Name -eq $object.Name).Drop()
                    }
                    catch {
                        Stop-PSFFunction -Message "Could not drop schema from $Database" -Target $object -ErrorRecord $_
                    }
                }
            }
        }
    }
}

