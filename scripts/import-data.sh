#!/bin/bash

# SQL Server connection details
SQL_SERVER="your_sql_server_address"
SQL_DATABASE="your_database_name"
SQL_USER="your_sql_username"
SQL_PASSWORD="your_sql_password"

# Query to extract data
QUERY="SELECT * FROM YourTable"

# Export data to CSV
/opt/mssql-tools/bin/sqlcmd -S $SQL_SERVER -d $SQL_DATABASE -U $SQL_USER -P $SQL_PASSWORD -Q "$QUERY" -s"," -o data.csv

# Authenticate with Salesforce CLI
sfdx force:auth:web:login -a MyOrgAlias

# Define the target object in Salesforce
SALESFORCE_OBJECT="TargetObject__c"

# Import data into Salesforce using Salesforce CLI
sfdx force:data:bulk:upsert -s $SALESFORCE_OBJECT -f data.csv -i Id -w 5

# Verify the import
sfdx force:data:soql:query -q "SELECT Id, Name FROM $SALESFORCE_OBJECT" -u MyOrgAlias
