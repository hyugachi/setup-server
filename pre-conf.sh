#!/bin/bash

# Function to check Linux distribution
get_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "almalinux" ]]; then
            echo "alma"
        else
            echo "$ID"
        fi
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Function to create .zshrc file
create_zshrc() {
    local user_home="$1"
    
    cat > "$user_home"/.zshrc << 'EOF'
# Basic ZSH configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Enable completion
autoload -Uz compinit
compinit

# Environment variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Basic prompt
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '

# Load aliases
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
EOF
}

# Function to create aliases file
create_aliases() {
    local user_home="$1"
    
    cat > "$user_home"/.zsh_aliases << 'EOF'
# Systemd aliases
alias sc-start='sudo systemctl start'
alias sc-stop='sudo systemctl stop'
alias sc-enable='sudo systemctl enable'
alias sc-disable='sudo systemctl disable'
alias sc-status='sudo systemctl status'
alias sc-restart='sudo systemctl restart'
alias sc-reload='sudo systemctl reload'
alias sc-list='systemctl list-unit-files --type=service'
alias sc-failed='systemctl --failed'
alias sc-enabled='systemctl list-unit-files --state=enabled'
alias sc-timers='systemctl list-timers'

# File management aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# ZSH configuration aliases
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
EOF
}

# Function to install packages based on distribution
install_packages() {
    case $1 in
        "ubuntu"|"debian")
            apt update && apt upgrade -y
            apt install -y zsh git curl sudo nano
            ;;
        "centos"|"rhel"|"rocky"|"alma"|"almalinux")
            if command -v dnf &> /dev/null; then
                dnf update -y && dnf upgrade -y
                dnf install -y zsh git curl sudo nano
            else
                yum update -y && yum upgrade -y
                yum install -y zsh git curl sudo nano
            fi
            ;;
        "opensuse"*)
            zypper refresh && zypper update -y
            zypper install -y zsh git curl sudo nano
            ;;
        "arch"|"manjaro")
            pacman -Syu --noconfirm
            pacman -S --noconfirm zsh git curl sudo nano
            ;;
        *)
            echo "Unsupported distribution: $1"
            exit 1
            ;;
    esac
}

# # Function to disable firewall
# configure_firewall() {
#     case $1 in
#         "ubuntu"|"debian")
#             if command -v ufw &> /dev/null; then
#                 systemctl disable --now ufw
#                 ufw disable
#                 echo "UFW firewall disabled successfully"
#             fi
#             ;;
#         "centos"|"rhel"|"rocky"|"alma"|"almalinux"|"fedora")
#             if command -v firewall-cmd &> /dev/null; then
#                 systemctl disable --now firewalld
#                 echo "FirewallD disabled successfully"
#             fi
#             ;;
#     esac
# }

# Get user inputs
read -p "Enter hostname                : " HOSTNAME
read -p "Enter username               : " USERNAME
read -p "Enter user password          : " USER_PASSWORD
read -p "Enter root password          : " ROOT_PASSWORD
echo ""
echo "Separate with comma if more than one key"
read -p "Enter SSH public key         : " SSH_PUB_KEY

# Get distribution
DISTRO=$(get_distro)

# Install necessary packages
install_packages "$DISTRO"

# Create or update user
if id "$USERNAME" &>/dev/null; then
    # User exists, just update password
    echo "$USERNAME:$USER_PASSWORD" | chpasswd
else
    # Create new user
    useradd -m -s /bin/zsh "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | chpasswd
fi

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Configure sudo access
if [ ! -d /etc/sudoers.d ]; then
    mkdir -p /etc/sudoers.d
fi
echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME"
chmod 440 "/etc/sudoers.d/$USERNAME"

# Configure SSH
mkdir -p /root/.ssh /home/"$USERNAME"/.ssh
chmod 700 /root/.ssh /home/"$USERNAME"/.ssh

IFS=',' read -r -a SSH_PUB_KEYS <<< "$SSH_PUB_KEY"
for KEY in "${SSH_PUB_KEYS[@]}"; do
    echo "$KEY" >> /root/.ssh/authorized_keys
    echo "$KEY" >> /home/"$USERNAME"/.ssh/authorized_keys
done

chmod 600 /root/.ssh/authorized_keys /home/"$USERNAME"/.ssh/authorized_keys
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh

# Configure SSH security
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable firewall
# configure_firewall "$DISTRO"

# Configure ZSH for root and user
for user_home in /root /home/"$USERNAME"; do
    # Create zshrc and aliases
    create_zshrc "$user_home"
    create_aliases "$user_home"

    # Set proper ownership
    if [ "$user_home" = "/home/$USERNAME" ]; then
        chown "$USERNAME":"$USERNAME" "$user_home/.zshrc" "$user_home/.zsh_aliases"
    fi
done

# Set default shell for both root and user
chsh -s /bin/zsh
chsh -s /bin/zsh "$USERNAME"

# Set hostname
hostnamectl set-hostname "$HOSTNAME"

# Restart SSH service
if systemctl is-active --quiet ssh; then
    systemctl restart ssh
elif systemctl is-active --quiet sshd; then
    systemctl restart sshd
fi

echo "Configuration completed successfully!"
echo "Please log out and log back in to use your new shell."
