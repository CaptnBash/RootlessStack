## TrueNAS Setup
Follow https://github.com/AnotherStranger/docker-borg-backup?tab=readme-ov-file#truenas-community-edition.

Under `Network Configuration` make sure to publish port 8022 to `Container Port` 22.

Make sure to create a dataset before you create the user, so you can set it as the users home directory.

Add the correct public key you get during your server setup into the environment variable.

---

## Dev Setup
For development purposes it is easier to use a separate Ubuntu/Debian VM that simulates the TrueNAS setup.
There are two ways you can set up borg in a VM for development.

### Docker Compose (Recommended)

Edit [docker-compose.yml](docker-compose.yml) and set your public key in `BORG_AUTHORIZED_KEYS`:

```yaml
environment:
  BORG_AUTHORIZED_KEYS: "ssh-ed25519 AAAA... your-key"
```

Then start the server:

```bash
docker compose up -d
```

The Borg SSH server will be available on port `8022`.

---

### bash script
You can use the [POC-backup-server.sh](POC-backup-server.sh) script provided.

On the VM simply execute the script as root **before** running the normal install script on the main server.
Once the script asks for `Client Public Key:` you can run the normal install script on the main server.
