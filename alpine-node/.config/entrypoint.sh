#!/bin/sh

# Kode warna
RED='\033[0;31m'      # Merah
GREEN='\033[0;32m'    # Hijau
YELLOW='\033[0;33m'   # Kuning
BLUE='\033[0;34m'     # Biru
MAGENTA='\033[0;35m'  # Magenta
CYAN='\033[0;36m'     # Cyan
RESET='\033[0m'       # Reset warna

# Generate SSH host keys if they don't exist
ssh-keygen -A > /dev/null 2>&1

# Check if the root password has been previously generated
if [ -f /root/.password_set ]; then
    echo -e "${MAGENTA}=================================================================${RESET}"
    echo -e "${MAGENTA}Root password is already set. Not generating a new password.${RESET}"
    echo -e "${MAGENTA}=================================================================${RESET}"
else
    # Check if the environment variable for the root password is set
    if [ -z "$DKA_SSH_ROOT_PASSWORD" ]; then
        # Generate a random password for the root user
        ROOT_PASSWORD=$(openssl rand -base64 20)
        echo -e "${GREEN}=================================================================${RESET}"
        echo -e "${GREEN}Generated root password: $ROOT_PASSWORD${RESET}"
        echo -e "${GREEN}=================================================================${RESET}"
    else
        ROOT_PASSWORD="$DKA_SSH_ROOT_PASSWORD"
        echo -e "${GREEN}Using provided root password: $ROOT_PASSWORD${RESET}"
    fi
    # Set the root password
    echo "root:$ROOT_PASSWORD" | chpasswd > /dev/null 2>&1
    # Create a file to indicate that the password has been set
    touch /root/.password_set
fi

# Start the SSH server
/usr/sbin/sshd -D &

# Jika tidak ada perintah yang diberikan, jalankan tail -f untuk menjaga kontainer tetap hidup
if [ -z "$1" ]; then
    echo -e "${BLUE}No command provided, keeping container alive...${RESET}"
    tail -f /dev/null
else
    # Jalankan perintah yang diberikan
    "$@" || {
        exit_code=$?  # Simpan kode keluar perintah yang dijalankan
        echo -e "${RED}failed to run existing command. keeping container alive${RESET}"
        # Jika exit code adalah 1 (atau kegagalan lainnya), tetap jalankan tail -f untuk menjaga kontainer hidup
        if [ $exit_code -eq 1 ]; then
            tail -f /dev/null
        else
            exit $exit_code
        fi
    }
fi
