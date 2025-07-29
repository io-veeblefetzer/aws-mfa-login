#!/bin/bash

set -e

echo "🔍 Retrieving AWS RDS secrets..."

# Get all secrets starting with 'rds!'
secrets=$(aws secretsmanager list-secrets --query "SecretList[?starts_with(Name, 'rds!')].{Name:Name,Description:Description}" --output json)

# Check if any secrets were found
if [[ $(echo "$secrets" | jq '. | length') -eq 0 ]]; then
    echo "❌ No RDS secrets found starting with 'rds!'"
    exit 1
fi

echo ""
echo "📋 Available RDS Secrets:"

# Display numbered list with DB instance names from description
declare -a secret_names=()
i=1
while IFS= read -r secret; do
    name=$(echo "$secret" | jq -r '.Name')
    description=$(echo "$secret" | jq -r '.Description // "No description"')
    
    # Extract DB instance name from description (assuming it contains the instance name)
    db_instance=$(echo "$description" | sed -n 's/.*db:\(.*\).*/\1/p' || echo "$description")
    
    echo "$i. $db_instance"
    secret_names+=("$name")
    ((i++))
done < <(echo "$secrets" | jq -c '.[]')

echo ""
read -p "👉 Select a secret (1-$((i-1))): " choice

# Validate choice
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $((i-1)) ]; then
    echo "❌ Invalid choice. Please select a number between 1 and $((i-1))."
    exit 1
fi

# Get the selected secret name
selected_secret="${secret_names[$((choice-1))]}"
echo "✅ Selected: $selected_secret"

echo "🔍 Retrieving secret value..."

# Get the secret value
secret_value=$(aws secretsmanager get-secret-value --secret-id "$selected_secret" --query 'SecretString' --output text)

# Extract password from JSON and copy to clipboard
password=$(echo "$secret_value" | jq -r '.password')

if [ "$password" = "null" ] || [ -z "$password" ]; then
    echo "❌ Error: No password field found in secret"
    exit 1
fi

echo -n "$password" | pbcopy
echo "📋 Password copied to clipboard!"