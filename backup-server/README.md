## TrueNAS setup
Follow https://github.com/AnotherStranger/docker-borg-backup?tab=readme-ov-file#truenas-community-edition. 

Under `Network Configuration` make sure to publish port 8022 to `Container Port` 22. 

Make sure to create a dataset before you create the user, so you can set it as the users home directory. 

Add the correct publickey you get during your server setup into the environment variable.

## Dev Setup
For development purposes it is easiert to use a seperate Ubuntu VM that simulates the TrueNAS setup.

You can use the [POC-backup-server.sh](POC-backup-server.sh) script provided.

On the VM simply execute the script as root **before** running the normal install script on the main server.
Once the script asks for `Client Public Key:` you can run the normal install script on the main server.

