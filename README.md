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

```
curl -sSL "https://raw.githubusercontent.com/io-veeblefetzer/aws-mfa-login/main/install.sh" | bash -s
```

## How to run it
### Login
Just run the following command. If you have a Yubikey, plug it in.

```
aws-mfa-login <profile name>
```

This will list your MFA options. Pick the right one and provide the MFA code. If
you use your yubikey, please touch it.

Your environment is now set. Test your access by running, for example:

```
aws s3 ls
```

### Logout
Run the following command: 

```
aws-logout
```


## Compatibility
Compatible with bash, zsh