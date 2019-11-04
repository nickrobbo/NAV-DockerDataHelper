# NAV-DockerDataHelper
Set of scripts which allow a user to quickly copy data to a database inside a local NAV Container, from a remote SQL Server using SQL Bulk Copy. 

### Requirements
- Requires SqlServer PowerShell module to be installed on machine running the scripts.
- Uses Integrated Security for authentication with databases (Windows Authentication).
- Update Setup.json & TablesToCopy.json before running the script "Copy-DataToContainerDB.ps1".
- "sqlWhereClause" can be used to copy specific sets of records from source to destination.
- Tables will be automatically cleaned before copying using either truncation or deletion.