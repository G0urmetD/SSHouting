<img src="/images/sshouting.png" alt="SSHouting" width="200" height="200" /></a>

# SSHouting [WORK IN PROGRESS]

Automates the setup and secure configuration of SSH – with the ability to frequently update authorized keys and allowed user lists from a distribution server.

## Features

- Install SSH with secure default config
- Use custom SSH config file
- Sync `authorized_keys` from a central server (with hash check)
- Sync `users.txt` (AllowUsers) from a central server (with hash check)
- Warns if users in `users.txt` do not exist locally
- Validates SSH configuration before restart
- Logs actions to `/var/log/SSHouting/sshouting.log`
- Colorized terminal output
- Debug mode available
- Self-updating via GitHub

---

## Usage

### Install SSH with keys and users from a distribution server
```bash
./sshouting.sh --install \
  --Username admin@<distribution-server> \
  --ssh-key ~/.ssh/id_rsa \
  --allow-users /etc/ssh/allowed_users.txt
```

### Install SSH with basic secure config & update ssh-keys & user afterwards
```bash
# basic secure installation
./sshouting.sh --install

# update ssh-keys & userlist
./sshouting.sh --update-keys \
  --Username admin@<distribution-server> \
  --ssh-key ~/.ssh/id_rsa
```

## Files on distribution server
- `authorized_keys` -> SSH public keys to be deployed
- `users.txt` -> list of usernames allowed to SSH (one per line)

## Logging
All operations are logged to: `/var/log/SSHouting/sshouting.log`

## Help
```bash
   __________ __  __            __  _
  / ___/ ___// / / /___  __  __/ /_(_)___  ____ _
  \__ \\__ \/ /_/ / __ \/ / / / __/ / __ \/ __ `/
 ___/ /__/ / __  / /_/ / /_/ / /_/ / / / / /_/ /
/____/____/_/ /_/\____/\__,_/\__/_/_/ /_/\__, /
                                        /____/
Version: 0.9-beta

Usage: ./sshouting.sh [options]
Options:
  -i,  --install            Install and configure SSH
  -uk, --update-keys        Update SSH keys from distribution server
  -U,  --Username           Username for distribution server
  -sk, --ssh-key            SSH private key for distribution server
  -p,  --port               SSH port to configure (default: 22)
  -au, --allow-users        Path to file with allowed SSH users
  -c,  --config             Use custom sshd_config file
  -u,  --update             Update script from GitHub
  -h,  --help               Show this help message
      --debug              Enable debug mode
```
