function Copy-SQLTable {
    [CmdletBinding()]
    param( 
  
        [Parameter(Mandatory = $true)]
        [string] $SourceSQLInstance,
 
        [Parameter(Mandatory = $true)]
        [string] $SourceDatabase,        
         
        [Parameter(Mandatory = $true)]
        [string] $TargetSQLInstance,
         
        [Parameter(Mandatory = $true)]
        [string] $TargetDatabase,
         
        [Parameter(Mandatory = $true)]
        [string] $JsonTable,

        [Parameter(Mandatory = $false)]
        [string] $SqlWhereClause,
         
        [Parameter(Mandatory = $false)]
        [switch] $DeleteTargetTableRecordsBeforeInsertingNewRecords,

        [Parameter(Mandatory = $false)]
        [int] $BulkCopyBatchSize = 10000,
 
        [Parameter(Mandatory = $false)]
        [int] $BulkCopyTimeout = 600
  
    )
    
    Import-Module SqlServer
    
    $sourceConnStr = "Data Source=$SourceSQLInstance;Initial Catalog=$SourceDatabase;Integrated Security=True;"
    $TargetConnStr = "Data Source=$TargetSQLInstance;Initial Catalog=$TargetDatabase;Integrated Security=True;"
      
    try {               
        $sourceSQLServer = New-Object Microsoft.SqlServer.Management.Smo.Server $SourceSQLInstance
        $sourceDB = $sourceSQLServer.Databases[$SourceDatabase]
        $sourceConn = New-Object System.Data.SqlClient.SQLConnection($sourceConnStr)     
        $sourceConn.Open()        
 
        foreach ($table in $sourceDB.Tables) {          
            $tableName = $table.Name
            $formattedtablename = $tableName -replace '[$]', ''
            $schemaName = $table.Schema
            $formattedTableAndSchema = "[$schemaName].[$formattedtablename]"
            $tableAndSchema = "[$schemaName].[$tableName]"
            $jsonTableAndSchema = "[$schemaName].[$JsonTable]"
            if ($jsonTableAndSchema.Equals($formattedTableAndSchema)) {
            
                if ($DeleteTargetTableRecordsBeforeInsertingNewRecords) {
                    if ([string]::IsNullOrEmpty($SqlWhereClause)) {
                        $DeleteRecordsSqlCommand = "TRUNCATE TABLE [$TargetDatabase].$tableAndSchema"
                    }
                    else {
                        $DeleteRecordsSqlCommand = "DELETE FROM [$TargetDatabase].$tableAndSchema WHERE $SqlWhereClause"
                    }
                    Invoke-Sqlcmd -ServerInstance $TargetSQLInstance `
                        -Database $TargetDatabase `
                        -Query $DeleteRecordsSqlCommand
                }

                Write-Host "Copying $tableAndSchema records from $SourceDatabase to $TargetDatabase"            

                if ([string]::IsNullOrEmpty($SqlWhereClause)) {
                    $sql = "SELECT * FROM $tableAndSchema"              
                }
                else {
                    $sql = "SELECT * FROM $tableAndSchema WHERE $SqlWhereClause"              
                }

                $sqlCommand = New-Object system.Data.SqlClient.SqlCommand($sql, $sourceConn) 
                [System.Data.SqlClient.SqlDataReader] $sqlReader = $sqlCommand.ExecuteReader()        
                
                $bulkCopy = New-Object Data.SqlClient.SqlBulkCopy($TargetConnStr, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity)
                $bulkCopy.DestinationTableName = $table
                $bulkCopy.BulkCopyTimeOut = $BulkCopyTimeout
                $bulkCopy.BatchSize = $BulkCopyBatchSize

                foreach ($column in ( $table.Columns | Select-Object -ExpandProperty Name )) {
                    if ( $PSBoundParameters.ContainsKey('ColumnMappings') -and $ColumnMappings.ContainsKey($column) ) {
                        [void]$bulkCopy.ColumnMappings.Add($column, $ColumnMappings[$column])
                    }
                    else {
                        [void]$bulkCopy.ColumnMappings.Add($column, $column)
                    }
                }
                
                $bulkCopy.WriteToServer($sqlReader)
                $sqlReader.Close()
                $bulkCopy.Close()
            }
        } 
        $sourceConn.Close() 
    }
    catch {
        [Exception]$ex = $_.Exception
        Write-Host $ex.Message

    }    
}




