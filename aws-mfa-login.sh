#!/bin/bash

# Config
# Set this env file when the environment loads
# AWS_TEMP_ENV="~/.aws/temp_env"
AWS_ENV=$(eval echo $AWS_TEMP_ENV)

# Set the profile
AWS_PROFILE=$1
AWS_PROFILE_UPPERCASE=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# Run the AWS CLI command and capture its output
echo "💻 Fetching MFA devices for profile $AWS_PROFILE"
AWS_OUTPUT=$(aws iam list-mfa-devices --profile $AWS_PROFILE | jq -r ".MFADevices |= (map(.SerialNumber)) | .MFADevices | flatten[]")

# Split the output into an array
IFS=$'\n' read -d '' -r -a MFA_DEVICES <<< "$AWS_OUTPUT"

# Detect the current shell
CURRENT_SHELL=$(ps -p $$ -ocomm=)

# Function to check MFA device
check_mfa_device() {
    echo ""
    echo "$MFA_DEVICE" | grep -i 'yubi' > /dev/null
    if [ $? -eq 0 ]; then
        echo "⏳ Selected yubikey, wait for instructions"
        TOKEN_CODE=$(ykman oath accounts code $MFA_DEVICE | awk '{print $NF}' | tr -d '[:space:]')
    else
        echo "👉 Enter your token code and press enter:"
        read TOKEN_CODE
    fi
}

echo ""
PS3="👉 Select an option: "
select choice in "${MFA_DEVICES[@]}"; do
    MFA_DEVICE=${MFA_DEVICES[$REPLY-1]}

    TOKEN_CODE=''

    # Determine which shell is running and call the appropriate function
    check_mfa_device

    echo "⏳ Fetching STS session token"
    AUTH_DATA=$(aws sts get-session-token --profile $AWS_PROFILE --serial-number $MFA_DEVICE --token-code $TOKEN_CODE 2>&1)

    # Check if there was an error
    if [ $? -ne 0 ]; then
        echo "An error occurred while running the AWS CLI command:"
        echo "$AUTH_DATA"

        exit 1
    fi

    echo "📥 Received auth data!"

    # Parse the JSON and set environment variables
    AWS_ACCESS_KEY_ID=$(echo "$AUTH_DATA" | jq -r '.Credentials.AccessKeyId')
    AWS_SECRET_ACCESS_KEY=$(echo "$AUTH_DATA" | jq -r '.Credentials.SecretAccessKey')
    AWS_SESSION_TOKEN=$(echo "$AUTH_DATA" | jq -r '.Credentials.SessionToken')
    AWS_EXPIRATION=$(echo "$AUTH_DATA" | jq -r '.Credentials.Expiration')
    AWS_DEFAULT_REGION=$(aws configure get region --profile $AWS_PROFILE)
    AWS_DEFAULT_PROFILE=$AWS_PROFILE

    # Remove the temp file
    if [ -e "$AWS_ENV" ]; then
        rm "$AWS_ENV"
    fi

    
    # Write the temp file
    echo "💾 Writing credentials to $AWS_ENV"

    touch $AWS_ENV
    echo "# AWS Temp file, created $(date)" 2>/dev/null >> $AWS_ENV
    echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" 2>/dev/null >> $AWS_ENV
    echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" 2>/dev/null >> $AWS_ENV
    echo "export AWS_DEFAULT_PROFILE=$AWS_PROFILE" 2>/dev/null >> $AWS_ENV
    echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" 2>/dev/null >> $AWS_ENV
    echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" 2>/dev/null >> $AWS_ENV
    source $AWS_ENV

    # Now try to add the current machine to different security groups
    AWS_ARNS_ENV_NAME="AWS_SG_BASTION_GROUPIDS_$AWS_PROFILE_UPPERCASE"
    eval "AWS_SG_BASTION_GROUPIDS=\$$AWS_ARNS_ENV_NAME"
    if [ -n "$AWS_SG_BASTION_GROUPIDS" ]; then
        # Get basic info
        HOSTNAME=$(uname -n)
        IP=$(curl -s ifconfig.me)

        RULE_IP="$IP/32"
        RULE_DESC="Added by aws-mfa-login for $HOSTNAME"

        # Split AWS_SG_BASTION_GROUPIDS on commas and loop through each ARN
        IFS=',' read -ra GIDS <<< "$AWS_SG_BASTION_GROUPIDS"
        echo "🔓 Adding to security groups: ${GIDS[@]}"

        for GID in "${GIDS[@]}"; do
            echo "🔓 Processing ARN: $GID"
            aws ec2 revoke-security-group-ingress \
                --group-id $GID \
                --protocol tcp --port 22 \
                --cidr $RULE_IP > /dev/null 2>&1 || true

            SG_RULE_ID=$(aws ec2 authorize-security-group-ingress \
                --group-id $GID \
                --protocol tcp --port 22 \
                --query 'SecurityGroupRules[0].SecurityGroupRuleId' \
                --output text \
                --cidr $RULE_IP)
            
            eval "aws ec2 update-security-group-rule-descriptions-ingress --group-id $GID --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=$RULE_IP,Description=\"$RULE_DESC\"}]' > /dev/null 2>&1"

                
        done
    else
        echo "ℹ️ The environment variable AWS_SG_BASTION_GROUPIDS_$AWS_PROFILE_UPPERCASE is not set."
        echo "  Read the documentation for more info on this feature."
    fi

    echo "🔓 Logged in! Expires $AWS_EXPIRATION"
    exit 0
done