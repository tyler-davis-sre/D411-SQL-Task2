# Tyler Davis  / Student ID: 001433124

Try {

<# Create Database #>
Write-Host -ForegroundColor Cyan "[SQL]: Starting SQL Tasks"

<# Import SqlServer Module
if (Get-Module -Name sqlps) { Remove-Module sqlps }
Import-Module -Name SqlServer

# Set a string variable equal to the name of the SQL Instance
$sqlServerInstanceName = "SRV19-PRIMARY\SQLEXPRESS"


# Set a string variable equal to the name of the Database
$databaseName = 'MyDatabase-InvokeSqlCmd'

# Create an object reference to the SQL server
$sqlServerObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sqlServerInstanceName

# Create an object referencing the Database and try to detect if it exists
$databaseObject = Get-SqlDatabase -ServerInstance $sqlServerInstanceName -Name $databaseName -ErrorAction Silently Continue
  if($databaseObject) {
	Write-Host -ForegroundColor Cyan "[SQL]: $($databaseName) Database Found. Now Deleting"

	#Kill all running processes in the database system
	$sqlServerObject.KillAllProcesses($databaseName)

	# Set the database to Single user access mode
	$databaseObject.UserAccess = "Single"

	# Delete the database
	$databaseObject.Drop()
	}
else {
	Write-Host -ForegroundColor Cyan "[SQL]: $($databaseName) Not Found"

}

# Call the Create method on the databse object to create it
$databaseObject = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -ArgumentList $sqlServerObject, $databaseName
$databaseObject.Create()

# Update user on progress
Write-Host -ForegroundColor Cyan "[SQL]: Database Created: [$($sqlServerInstanceName)].[$($databaseName)]"

<# Create Table

# Invoke a SQL Command against the SQL Instance
$schema = "dbo"
$tableName = 'MyTable'
Invoke-Sqlcmd -ServerInstance $sqlServerInstanceName -Database $databaseName -InputFile $PSScriptRoot\CreateTable_MyTable.sql

# update user on progress
Write-Host -ForegroundColor Cyan "[SQL]: Table created: [$($sqlServerInstanceName)].[$($databasename)].[$($schema)].[$($tableName)]"

# Import rows from csv file and transfer over each one using Invoke-Sqlcmd

$InsertQuery = "INSERT INTO [$($schema)].[$($tableName)] (first_name, last_name, city, county, zip, officePhone, mobilePhone) "
$NewClients = Import-Csv $PSScriptRoot\NewClientData.csv

Write-Host -ForegroundColor Cyan "[SQL]: Inserting Data"
foreach($NewClient in $NewClients)
	{
	$Values = "VALUES ('$($NewClient.first_name)','
			'$($NewClient.last_name)','
			'$($NewClient.city)','
			'$($NewClient.county)','
			'$($NewClient.zip)','
			'$($NewClient.officePhone)','
			'$($NewClient.mobilePhone)','
	
	$query = $InsertQuery + $Values
	Invoke-Sqlcmd -Database $databaseName -ServerInstance $sqlServerInstanceName -Query $query
}

# Read Data-set
	Write-Host -ForegroundColor Cyan "[SQL]: Reading Data"
	$selectQuery = "SELECT * FROM $($tableName)"
	$Clients =Invoke-Sqlcmd -Database $databaseName -ServerInstance $sqlServerInstanceName -Query $selectQuery
forech($Client in $Clients)
{
Write-Host "Client Name: $($Client.first_name) $($Client.last_name)"
Write-Host "Address: $($Client.county) County, City of $($Client.city), Zip- $($Client.zip)"
Write-Host "Phone: Office $($Client.officePhone), Mobile $($Client.mobilePhone)"
Write-Host ".............."
}
	Write-Host-ForegroundColor Cyan "[SQL]: SQL Tasks Complete"
}
# Catch any Errors
Catch {
	Write-Host -ForegroundColor Red "An Exception Occurred"
	Write-Host -ForegroundColor Red "$($PSItem.ToString())'n'n$($PSItem.ScriptStackTrace)"
}



