#!/bin/sh

###############################################################################
# Linux server ssh setup & update script - SSHouting
# Description : Automates the setup of ssh & able to update the keys frequently
# Author      : g_ourmet
# Version     : 1.1
# Notes       : Modular via JSON + jq, POSIX-compliant, portable
###############################################################################

set -e

#============================[ ASCII Banner ]==================================
print_banner() {
    cat << "EOF"
   __________ __  __            __  _            
  / ___/ ___// / / /___  __  __/ /_(_)___  ____ _
  \__ \\__ \/ /_/ / __ \/ / / / __/ / __ \/ __ `/
 ___/ /__/ / __  / /_/ / /_/ / /_/ / / / / /_/ / 
/____/____/_/ /_/\____/\__,_/\__/_/_/ /_/\__, /  
                                        /____/     
EOF
}

#============================[ Color Output ]=================================
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_RESET="\033[0m"

log_info()    { printf "${COLOR_GREEN}[INFO] %s${COLOR_RESET}\n" "$1"; }
log_warn()    { printf "${COLOR_YELLOW}[WARN] %s${COLOR_RESET}\n" "$1"; }
log_error()   { printf "${COLOR_RED}[ERROR] %s${COLOR_RESET}\n" "$1"; }
log_debug()   { [ "$DEBUG" = true ] && printf "${COLOR_BLUE}[DEBUG] %s${COLOR_RESET}\n" "$1"; }

#============================[ Logging Setup ]=================================
LOG_DIR="/var/log/SSHouting"
LOG_FILE="$LOG_DIR/sshouting.log"
mkdir -p "$LOG_DIR"

log_to_file() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG_FILE"
}

#============================[ Help Function ]=================================
show_help() {
    print_banner
    echo "Version: 1.1"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -i,   --install             Install and configure SSH"
    echo "  -uk,  --update-keys         Update SSH keys from distribution server"
    echo "  -U,   --Username            Username@host for distribution server (required for SCP)"
    echo "  -sk,  --ssh-key             Path to SSH private key for distribution server (required for SCP)"
    echo "  -p,   --port                SSH port to configure (default: 22)"
    echo "  -pr,  --permit-root         PermitRootLogin setting [no|prohibit-password] (default: no)"
    echo "  -au,  --allow-users         Path to file with allowed SSH users"
    echo "  -c,   --config              Use custom sshd_config file"
    echo "  -f,   --force               Force update of keys and users regardless of hash"
    echo "  -u,   --update              Update this script from GitHub"
    echo "  -h,   --help                Show this help message"
    echo "        --debug               Enable debug mode"
    echo ""
    echo "Examples:"
    echo "  Install SSH with default config:"
    echo "    $0 --install"
    echo ""
    echo "  Install and fetch authorized_keys/users from server:"
    echo "    $0 --install --Username admin@distserver --ssh-key ~/.ssh/id_rsa --allow-users ./users.txt"
    echo ""
    echo "  Update keys and users from remote:"
    echo "    $0 --update-keys --Username admin@distserver --ssh-key ~/.ssh/id_rsa"
    echo ""
    echo "  Install with custom config + PermitRootLogin:"
    echo "    $0 --install --config ./my_sshd_config --permit-root prohibit-password"
    echo ""
    echo "  Force key/user update even if hash unchanged:"
    echo "    $0 --update-keys --Username admin@distserver --ssh-key ~/.ssh/id_rsa --force"
    echo ""
}

#============================[ File Retrieval ]================================
fetch_remote_files() {
    #[ -z "$DISTRO_USER" ] || [ -z "$SSH_KEY" ] && return
    if [ -z "$DISTRO_USER" ] || [ -z "$SSH_KEY" ]; then
        log_debug "No distribution server configured, skipping key/user retrieval."
        return
    fi

    TMP_DIR="/tmp/ssh_fetch_$$"
    mkdir -p "$TMP_DIR"
    chmod 700 "$TMP_DIR"

    REMOTE_KEYS="$TMP_DIR/authorized_keys"
    REMOTE_USERS="$TMP_DIR/users.txt"
    LOCAL_USER="${SUDO_USER:-$(logname)}"
    LOCAL_HOME="/home/$LOCAL_USER"
    LOCAL_KEYS="$LOCAL_HOME/.ssh/authorized_keys"

    KNOWN_HOSTS="$HOME/.ssh/known_hosts"
    ssh-keyscan -H "$(echo $DISTRO_USER | cut -d@ -f2)" >> "$KNOWN_HOSTS" 2>/dev/null || \
    log_warn "Could not update known_hosts for $(echo $DISTRO_USER | cut -d@ -f2)"

    scp -i "$SSH_KEY" "$DISTRO_USER":~/authorized_keys "$REMOTE_KEYS" || {
        log_error "Failed to fetch authorized_keys from $DISTRO_USER"
        return
    }
    NEW_KEYS_HASH=$(sha256sum "$REMOTE_KEYS" | cut -d ' ' -f1)
    [ -f "$LOCAL_KEYS" ] && OLD_KEYS_HASH=$(sha256sum "$LOCAL_KEYS" | cut -d ' ' -f1) || OLD_KEYS_HASH=""
    log_debug "authorized_keys hash old: $OLD_KEYS_HASH | new: $NEW_KEYS_HASH"

    if [ "$NEW_KEYS_HASH" != "$OLD_KEYS_HASH" ] || [ "$FORCE_UPDATE" = true ]; then
        mkdir -p "$LOCAL_HOME/.ssh"
        chmod 700 "$LOCAL_HOME/.ssh"
        cp "$REMOTE_KEYS" "$LOCAL_KEYS"
        chown "$LOCAL_USER":"$LOCAL_USER" "$LOCAL_KEYS"
        chmod 600 "$LOCAL_KEYS"
        log_info "authorized_keys updated."
        log_to_file "authorized_keys updated."
    else
        log_info "authorized_keys is up-to-date."
    fi

    if scp -i "$SSH_KEY" "$DISTRO_USER":~/users.txt "$REMOTE_USERS" 2>/dev/null; then
        LOCAL_USERS_HASH=""
        if [ -n "$ALLOW_USERS_FILE" ] && [ -f "$ALLOW_USERS_FILE" ]; then
            LOCAL_USERS_HASH=$(sha256sum "$ALLOW_USERS_FILE" | cut -d ' ' -f1)
        fi
        REMOTE_USERS_HASH=$(sha256sum "$REMOTE_USERS" | cut -d ' ' -f1)
        log_debug "users.txt hash old: $LOCAL_USERS_HASH | new: $REMOTE_USERS_HASH"

        if [ "$LOCAL_USERS_HASH" != "$REMOTE_USERS_HASH" ] || [ "$FORCE_UPDATE" = true ]; then
            cp "$REMOTE_USERS" "$ALLOW_USERS_FILE"
            log_info "users.txt updated."
            log_to_file "users.txt updated."
        else
            log_info "users.txt is up-to-date."
        fi
    fi

    # clean up temp files
    rm -rf "$TMP_DIR"
}

#============================[ Validate Users Exist ]===========================
validate_users_exist() {
    if [ -f "$ALLOW_USERS_FILE" ]; then
        # while read -r user; do
        #     if ! id "$user" >/dev/null 2>&1; then
        #         log_warn "User $user from users.txt does not exist locally."
        #     fi
        # done < "$ALLOW_USERS_FILE"
        while read -r user; do
            user=$(echo "$user" | xargs)  # trim
            [ -z "$user" ] && continue
            if ! id "$user" >/dev/null 2>&1; then
                log_warn "User $user from users.txt does not exist locally."
            fi
        done < "$ALLOW_USERS_FILE"
    fi
}

#============================[ SSH PermitRootLogin Option ]====================
PERMIT_ROOT="no"

if [ -n "$PERMIT_ROOT_SETTING" ]; then
    case "$PERMIT_ROOT_SETTING" in
        no|prohibit-password)
            PERMIT_ROOT="$PERMIT_ROOT_SETTING"
            ;;
        *)
            log_warn "Invalid value for --permit-root. Falling back to 'no'."
            ;;
    esac
fi

#============================[ SSH Install Function ]===========================
install_ssh() {
    fetch_remote_files

    log_info "Installing OpenSSH server..."
    apt-get update && apt-get install -y openssh-server

    log_info "Backing up existing sshd_config..."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    if [ -n "$CUSTOM_CONFIG_FILE" ] && [ -f "$CUSTOM_CONFIG_FILE" ]; then
        log_info "Using custom sshd_config from $CUSTOM_CONFIG_FILE"
        cp "$CUSTOM_CONFIG_FILE" /etc/ssh/sshd_config

        if [ -n "$ALLOW_USERS_FILE" ] && [ -f "$ALLOW_USERS_FILE" ]; then
            USERS=$(tr '\n' ' ' < "$ALLOW_USERS_FILE")
            echo "AllowUsers $USERS" >> /etc/ssh/sshd_config
            log_info "Appended AllowUsers to custom sshd_config"
        fi
    else
        ALLOW_USERS_LINE=""
        if [ -n "$ALLOW_USERS_FILE" ] && [ -f "$ALLOW_USERS_FILE" ]; then
            USERS=$(tr '\n' ' ' < "$ALLOW_USERS_FILE")
            ALLOW_USERS_LINE="AllowUsers $USERS"
        fi

        log_info "Writing secure sshd_config..."
        cat > /etc/ssh/sshd_config <<EOF
Port ${SSH_PORT:-22}
Protocol 2
PermitRootLogin $PERMIT_ROOT
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
MaxAuthTries 8
AllowTcpForwarding no
$ALLOW_USERS_LINE
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    fi

    validate_users_exist

    log_info "Testing SSH configuration..."
    if sshd -t; then
        log_info "SSH config test passed. Restarting service..."
        systemctl restart ssh
        log_to_file "SSH installed and configured on port ${SSH_PORT:-22} with allowed users: $USERS"
    else
        log_error "SSH config test failed. Check /etc/ssh/sshd_config."
        exit 1
    fi
}

#============================[ Update Function ]===============================
update_keys() {
    fetch_remote_files
    validate_users_exist
    log_info "SSH keys checked and updated if necessary."
    log_to_file "Checked for key/user updates."
}

#============================[ Self-Update Function ]==========================
self_update() {
    REPO_URL="https://raw.githubusercontent.com/G0urmetD/SSHouting/refs/heads/main/sshouting.sh"
    DEST="$0"

    TMP_SCRIPT="/tmp/sshouting_latest.sh"
    log_info "Fetching latest version from GitHub..."
    if curl -fsSL "$REPO_URL" -o "$TMP_SCRIPT"; then
        chmod +x "$TMP_SCRIPT"
        cp "$TMP_SCRIPT" "$DEST"
        log_info "Script successfully updated."
        log_to_file "Script updated from $REPO_URL"
    else
        log_error "Failed to fetch update."
        exit 1
    fi
}

#============================[ Argument Parsing ]==============================
DEBUG=false
SSH_PORT=22
ALLOW_USERS_FILE=""
CUSTOM_CONFIG_FILE=""
FORCE_UPDATE=false
PERMIT_ROOT_SETTING=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -i|--install)
            INSTALL=true
            ;;
        -uk|--update-keys)
            UPDATE_KEYS=true
            ;;
        -U|--Username)
            shift
            DISTRO_USER="$1"
            ;;
        -sk|--ssh-key)
            shift
            SSH_KEY="$1"
            ;;
        -p|--port)
            shift
            SSH_PORT="$1"
            ;;
        -au|--allow-users)
            shift
            ALLOW_USERS_FILE="$1"
            ;;
        -c|--config)
            shift
            CUSTOM_CONFIG_FILE="$1"
            ;;
        -pr|--permit-root)
            shift
            PERMIT_ROOT_SETTING="$1"
            ;;
        -u|--update)
            SELF_UPDATE=true
            ;;
        -f|--force)
            FORCE_UPDATE=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --debug)
            DEBUG=true
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

#============================[ Execution Logic ]===============================
[ "$INSTALL" = true ] && install_ssh
[ "$UPDATE_KEYS" = true ] && update_keys
[ "$SELF_UPDATE" = true ] && self_update
