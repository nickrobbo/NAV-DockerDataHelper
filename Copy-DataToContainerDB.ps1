."$PSScriptRoot\Copy-SQLTable.ps1"

$Setup = Get-Content -Raw -Path "$PSScriptRoot\Setup.json" | ConvertFrom-Json
$TablesToCopy = Get-Content -Raw -Path "$PSScriptRoot\TablesToCopy.json" | ConvertFrom-Json

$NoOfTablesCreated = 1
try {
    foreach ($Table in $TablesToCopy.tables) {
        $FullTableName = $Table.tableName 
        $TableName = $FullTableName -replace '[$]', ''
        $SqlWhereClause = $t.sqlWhereClause

        $PercentComplete = $(($NoOfTablesCreated / $TablesToCopy.tables.Count) * 100 )

        $Progress = @{
            Activity = "Creating a table & copying records from $FullTableName."
            Status = "Processing $NoOfTablesCreated of $($TablesToCopy.tables.Count) tables"
            PercentComplete = $([math]::Round($PercentComplete, 2))
        }

        Write-Progress @Progress
 
        Copy-SQLTable -SourceSQLInstance $Setup.CopyFromSQLServerName `
            -SourceDatabase $Setup.CopyFromDatabaseName `
            -TargetSQLInstance $Setup.ContainerName `
            -TargetDatabase $Setup.ContainerDatabaseName `
            -JsonTable $TableName `
            -SqlWhereClause $SqlWhereClause `
            -DeleteTargetTableRecordsBeforeInsertingNewRecords `
            -BulkCopyBatchSize 5000              

        $NoOfTablesCreated++                   
    }
}
catch {
    Write-Host "Error copying setup tables from $($Setup.CopyFromDatabaseName) to $($Setup.ContainerName)" -ForegroundColor Red
    [Exception]$ex = $_.Exception
    Write-Host $ex.Message
    exit      
}

