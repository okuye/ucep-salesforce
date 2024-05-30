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