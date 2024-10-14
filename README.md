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

Make sure that the prerequisites are installed and configured. Then open a terminal and run the following command:

```shell
curl -sSL "https://raw.githubusercontent.com/io-veeblefetzer/aws-mfa-login/main/install.sh" | bash -s
```
### Fish users
Go to `~/.config/fish/config.fish` and add the following line:

```shell
# aws-mfa-login
set --export AWS_TEMP_ENV "$HOME/.aws/temp_env"

# Read thr file and parse the AWS_ tokens into the environment
function source_env
    if test -f $AWS_TEMP_ENV
        set -lx bash_env (bash -c "source $AWS_TEMP_ENV; env")

        # Parse the output and set environment variables in Fish
        for line in $bash_env
            set key_value (string split "=" $line)
            if string match -q 'AWS_*' $key_value[1]
                set -Ux $key_value[1] $key_value[2]
            end
        end
    end
end

source_env 
```

## How to run it
### Login
Just run the following command. If you have a Yubikey, plug it in.

```shell
aws-mfa-login <profile name>
```

This will list your MFA options. Pick the right one and provide the MFA code. If
you use your yubikey, please touch it.

Your environment is now set. Test your access by running, for example:

```shell
aws s3 ls
```

## How to configure bastion login
The script can automatically update inbound rules of security groups to configure your bastions or db access. Based on your
profile you should define the following environment variable:

```
AWS_SG_BASTION_GROUPIDS_<Profile name in uppercase>=<securitygroup id>,<securitygroup id>
```

This variable must contain a comma-separated list of security groups. If defined the script will parse it and add dynamic inbound
rules to this security group:

- Port: 22
- Protocol: tcp
- Description: contains 'added by aws-mfa-login', followed by the hostname 


### Logout
Run the following command: 

```shell
aws-logout
```


## Compatibility
Compatible with bash, zsh