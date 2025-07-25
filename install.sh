#!/bin/bash

# This is the installation script for the AWS MFA login and logout scripts

# Check if the script is already running with sudo privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script requires superuser privileges. Please enter your password when prompted."
    sudo "$0" "$@"  # Re-run the script with sudo
    exit $?
fi

# Install the login and logout scripts
INSTALL_PATH=/usr/local/bin

echo "Installing scripts"
curl -s "https://raw.githubusercontent.com/io-veeblefetzer/aws-mfa-login/main/aws-mfa-login.sh" > "$INSTALL_PATH/aws-mfa-login"
curl -s "https://raw.githubusercontent.com/io-veeblefetzer/aws-mfa-login/main/aws-logout.sh" > "$INSTALL_PATH/aws-logout"
curl -s "https://raw.githubusercontent.com/io-veeblefetzer/aws-mfa-login/main/get-rds-password.sh" > "$INSTALL_PATH/get-rds-password"


# Make them executable
chmod +x "$INSTALL_PATH/aws-mfa-login"
chmod +x "$INSTALL_PATH/aws-logout"
chmod +x "$INSTALL_PATH/get-rds-password"

# Echo the profile settings

# Define the snippet
echo "Configuring .profile"
PROFILE_CONFIG='export AWS_TEMP_ENV="~/.aws/temp_env"
AWS_ENV=$(eval echo $AWS_TEMP_ENV)
if [ -e "$AWS_ENV" ]; then
    source "$AWS_ENV"
fi'

# Check if the snippet is already in .profile
if ! grep -q "$PROFILE_CONFIG" ~/.profile; then
    # Append the snippet to .profile
    echo "$PROFILE_CONFIG" >> ~/.profile
    echo "- Snippet added to .profile"
else
    echo "- Snippet is already in .profile"
fi