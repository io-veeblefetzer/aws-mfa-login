# AWS MFA Login
> Simple bash script to handle AWS MFA cli login without too much hassle. 

## Prerequisites
You should have the AWS cli installed on your machine. You should also have a profile
configured with a valid Access Key ID and Secret Access Key. Check the AWS cli documentation
for further information.

### For Yubikey users
If you use a Yubikey for MFA, pleasse have the `ykman` cli tool installed. Also small note, if 
you name your MFA method in AWS, 'yubi' should be in the name in order to work...

## Installation instructions

[ ] Clone this repository
[ ] Install the `*sh` scripts on your path
[ ] Update your `.profile` or alike with the following snippet:

```
# Added for AWS environment
export AWS_TEMP_ENV="~/.aws/temp_env"
AWS_ENV=$(eval echo $AWS_TEMP_ENV)
if [ -e "$AWS_ENV" ]; then
    source "$AWS_ENV"
fi
```

## How to run it
Just run the following command. If you have a Yubikey, plug it in.

```
./aws-mfa-login.sh <profile name>
```

This will list your MFA options. Pick the right one and provide the MFA code. If
you use your yubikey, please touch it.

Your environment is now set. Test your access by running, for example:

```
aws s3 ls
```


## Compatibility
Compatible with bash, zsh