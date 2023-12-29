#!/bin/bash

unset AWS_PROFILE
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_DEFAULT_REGION

AWS_ENV=$(eval echo $AWS_TEMP_ENV)


# Remove the temp file
if [ -e "$AWS_ENV" ]; then
    rm "$AWS_ENV"
fi