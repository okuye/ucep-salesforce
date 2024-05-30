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