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

## Installation Commands

1. Install SSH with default config
```bash
./sshouting.sh --install
```

2. Install SSH and fetch keys/users from distribution server
```bash
# fetches `authorized_keys` and `users.txt` via scp
# appends `AllowUsers` if users.txt is provided

./sshouting.sh --install \
    --Username root@distro-srv \
    --ssh-key ~/.ssh/id_rsa \
    --allow-users ./users.txt
```

3. Install SSH with custom configuration file
```bash
# Applies your own `sshd_config` file
# If `--allow-users` is also given, `AllowUsers` is appended

./sshouting.sh --install --config ./custom_sshd_config
```

4. Install SSH with specific PermitRootLogin value
```bash
# Sets `PermitRootLogin prohibit-password` instead of the default `no`

./sshouting.sh --install --permit-root prohibit-password
```

5. Full-featured install with port, root config, key fetching
```bash
# Combines all features into a single install operation.

./sshouting.sh --install \
  --Username admin@distribution-server \
  --ssh-key ~/.ssh/id_rsa \
  --permit-root prohibit-password \
  --port 2222 \
  --allow-users ./users.txt
```

## Update commands

1. Update authorized_keys and users.txt (hash-checked)
```bash
# Only updates if SHA256 hash differs.

./sshouting.sh --update-keys \
  --Username admin@distribution-server \
  --ssh-key ~/.ssh/id_rsa
```

2. Force key/user update regardless of hash
```bash
# Forces file replacement.

./sshouting.sh --update-keys \
  --Username admin@distribution-server \
  --ssh-key ~/.ssh/id_rsa \
  --force
```

## Other commands

1. Update the script itself
```bash
./sshouting.sh --update
```

2. Show help
```bash
./sshouting.sh --help
```

3. Enable debug mode
```bash
./sshouting.sh --install --debug
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
Version: 1.1

Usage: ./sshouting.sh [options]

Options:
  -i,   --install             Install and configure SSH
  -uk,  --update-keys         Update SSH keys from distribution server
  -U,   --Username            Username@host for distribution server (required for SCP)
  -sk,  --ssh-key             Path to SSH private key for distribution server (required for SCP)
  -p,   --port                SSH port to configure (default: 22)
  -pr,  --permit-root         PermitRootLogin setting [no|prohibit-password] (default: no)
  -au,  --allow-users         Path to file with allowed SSH users
  -c,   --config              Use custom sshd_config file
  -f,   --force               Force update of keys and users regardless of hash
  -u,   --update              Update this script from GitHub
  -h,   --help                Show this help message
        --debug               Enable debug mode

Examples:
  Install SSH with default config:
    ./sshouting.sh --install

  Install and fetch authorized_keys/users from server:
    ./sshouting.sh --install --Username admin@distserver --ssh-key ~/.ssh/id_rsa --allow-users ./users.txt

  Update keys and users from remote:
    ./sshouting.sh --update-keys --Username admin@distserver --ssh-key ~/.ssh/id_rsa

  Install with custom config + PermitRootLogin:
    ./sshouting.sh --install --config ./my_sshd_config --permit-root prohibit-password

  Force key/user update even if hash unchanged:
    ./sshouting.sh --update-keys --Username admin@distserver --ssh-key ~/.ssh/id_rsa --force
```
