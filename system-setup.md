# System Setup

## SQL Server Setup

You can provide any strong password for the SQL Server SA (System Administrator) account as long as it meets the password policy requirements of SQL Server. The password must be complex and meet the following criteria:

1. **Minimum Length**: At least 8 characters long.
2. **Character Types**: Must contain at least three of the following four types of characters:
   - Uppercase letters (A-Z)
   - Lowercase letters (a-z)
   - Digits (0-9)
   - Special characters (e.g., !, $, #, %)

Here’s an example of how you can run the SQL Server Docker container with a strong password:

```bash
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=P@ssw0rd123!' -p 1433:1433 --name sqlserver -d mcr.microsoft.com/mssql/server:2019-latest
```

In this example, `P@ssw0rd123!` is a strong password that meets the criteria.

### Complete Example Setup

#### Step 1: Pull the SQL Server Docker Image

```bash
docker pull mcr.microsoft.com/mssql/server:2019-latest
```

#### Step 2: Run the SQL Server Docker Container

Use the command with your desired strong password:

```bash
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=P@ssw0rd123!' -p 1433:1433 --name sqlserver -d mcr.microsoft.com/mssql/server:2019-latest
```

#### Step 3: Set Up the Sample Database

Download and set up a sample database like AdventureWorks.

1. **Download the AdventureWorks sample database**:

   ```bash
   wget https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak
   ```

2. **Copy the backup file into the running SQL Server container**:

   ```bash
   docker cp AdventureWorks2019.bak sqlserver:/var/opt/mssql/backup/
   ```

3. **Restore the sample database inside the container**:

   ```bash
   docker exec -it sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'P@ssw0rd123!' -Q "RESTORE DATABASE AdventureWorks2019 FROM DISK = '/var/opt/mssql/backup/AdventureWorks2019.bak' WITH MOVE 'AdventureWorks2012_Data' TO '/var/opt/mssql/data/AdventureWorks2019.mdf', MOVE 'AdventureWorks2012_Log' TO '/var/opt/mssql/data/AdventureWorks2019.ldf'"
   ```

## Salesforce Environment Setup

### Step 4: Create Dockerfile for Salesforce Environment

**Dockerfile:**

```Dockerfile
# Use the latest Ubuntu image
FROM ubuntu:latest

# Update the package list and install dependencies
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk wget gnupg2 ca-certificates git make curl jq apt-transport-https \
                       gnupg2 software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

# Install Salesforce CLI
RUN npm install --global sfdx-cli

# Install SQL Server tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc

# Create a directory for the scripts
RUN mkdir /scripts

# Set the working directory
WORKDIR /scripts

# Copy the scripts to the container
COPY setup-salesforce.sh /scripts/setup-salesforce.sh
COPY import-data.sh /scripts/import-data.sh

# Make the scripts executable
RUN chmod +x /scripts/setup-salesforce.sh /scripts/import-data.sh

# Start the setup script
CMD ["/scripts/setup-salesforce.sh"]
```

### Step 5: Create the Setup Script for Salesforce

**setup-salesforce.sh:**

```bash
#!/bin/bash

# Authenticate Salesforce CLI (replace with your method if using device login)
sfdx auth:jwt:grant --clientid $SF_CLIENT_ID --jwtkeyfile /path/to/server.key --username $SF_USERNAME --instanceurl https://login.salesforce.com

# Create 3 users
for i in 1 2 3; do
  USERNAME="user${i}@example.com"
  ALIAS="User${i}"

  sfdx force:user:create username=${USERNAME} \
                         email=${USERNAME} \
                         lastname="User${i}" \
                         alias=${ALIAS} \
                         profileName="Standard User"

  # Verify user creation
  sfdx force:user:display -u ${USERNAME}
done

# Call the data import script
/scripts/import-data.sh

# Keep the container running
tail -f /dev/null
```

### Step 6: Create the Data Import Script

**import-data.sh:**

```bash
#!/bin/bash

# SQL Server connection details
SQL_SERVER="sqlserver"  # Name of the Docker container running SQL Server
SQL_DATABASE="AdventureWorks2019"
SQL_USER="SA"
SQL_PASSWORD="P@ssw0rd123!"

# Query to extract data
QUERY="SELECT TOP 10 * FROM Person.Person"  # Example query, adjust as needed

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
```

## Build and Run the Docker Container

### Build the Docker Image

```bash
docker build -t salesforce-environment .
```

### Run the Docker Container

```bash
docker run -it \
  -e SF_CLIENT_ID=your_client_id \
  -e SF_USERNAME=your_salesforce_username \
  -v /path/to/your/server.key:/path/to/server.key \
  --link sqlserver:sqlserver \
  --name salesforce-container salesforce-environment
```

## Environment Variables and Paths

- **SF_CLIENT_ID**: Your Salesforce connected app client ID.
- **SF_USERNAME**: Your Salesforce username.
- **/path/to/your/server.key**: Path to your Salesforce JWT key file.

## Persisting Data

If you want to persist data and logs, use Docker volumes:

```bash
docker run -it \
  -e SF_CLIENT_ID=your_client_id \
  -e SF_USERNAME=your_salesforce_username \
  -v /path/to/your/server.key:/path/to/server.key \
  -v $(pwd)/salesforce:/salesforce \
  -v $(pwd)/logs:/var/log/salesforce \
  --link sqlserver:sqlserver \
  --name salesforce-container salesforce-environment
```

This setup ensures that you can provide any strong password that meets the criteria and use it to extract data from a Microsoft SQL Server database, importing it into Salesforce within a Docker container, ensuring a smooth and automated data migration process.