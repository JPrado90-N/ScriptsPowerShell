import-Module SQLServer

# Define the connection string
$connectionString = "Server=UB4DBPROD\UB4PROD;Database=CIS4TEST;Integrated Security=SSPI;"

# Replace 'SERVERNAME' with the name of the SQL Server you want to connect to
# Replace 'DATABASENAME' with the name of the database you want to connect to

# Create a SqlConnection object
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString

# Open the connection
$sqlConnection.Open()

# If the connection is successful, write a message to the console
if ($sqlConnection.State -eq "Open") {
    Write-Host "Connected to SQL Server successfully!"
}
else {
    # If the connection fails, write the error message to the console
    Write-Host "Connection failed: $($sqlConnection.ConnectionString)"
}
# Define the query to retrieve data from BIF002 table
$query = "SELECT * FROM ADVANCED.BIF002"  # You can modify this query to select specific columns

# Create a SqlCommand object to execute the query
$sqlCommand = New-Object System.Data.SqlClient.SqlCommand($query, $sqlConnection)

# Ejecuta la consulta y almacena los resultados en un SqlDataReader
$sqlDataReader = $sqlCommand.ExecuteReader()

# Obtiene el esquema de la tabla
$tableSchema = $sqlDataReader.GetSchemaTable()

# Si hay filas en el SqlDataReader
if ($sqlDataReader.HasRows) {
    # Si hay un esquema de tabla válido
    if ($tableSchema) {
        # Obtén los nombres de las columnas
        $columnNames = @()
        foreach ($row in $tableSchema.Rows) {
            $columnName = $row["ColumnName"]
            $columnNames += $columnName
        }

        # Escribe los nombres de las columnas como encabezados en el archivo CSV
        $header = $columnNames -join ","
        $header | Out-File -FilePath $outputFile -Encoding UTF8

        # Escribe el contenido del SqlDataReader (excluyendo los nombres de las columnas)
        while ($sqlDataReader.Read()) {
            $rowData = @()
            for ($i = 0; $i -lt $sqlDataReader.FieldCount; $i++) {
                $rowData += $sqlDataReader[$i]
            }
            $rowString = $rowData -join ","
            $rowString | Out-File -FilePath $outputFile -Append -Encoding UTF8
        }
        Write-Host "Data successfully exported to: $outputFile"
    }
    else {
        Write-Host "No schema information available."
    }
}
else {
    Write-Host "No rows found in the BIF002 table."
}

# Close the SqlDataReader and connection
$sqlDataReader.Close()
$sqlConnection.Close()


# Close the connection
$sqlConnection.Close()