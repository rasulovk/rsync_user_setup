#!/bin/bash

# === Configuration ===
USERNAME="syncuser"
USER_HOME="/home/$USERNAME"
WRAPPER_PATH="/usr/local/sbin/restricted-rsync"
AUTHORIZED_KEYS="$USER_HOME/.ssh/authorized_keys"

# Prompt for source folder path
echo -n "Enter the source folder path to restrict rsync access to: "
read -r SOURCE_FOLDER
# Ensure the path ends with a trailing slash
SOURCE_FOLDER="${SOURCE_FOLDER%/}/"

# === Step 1: Prompt for password ===
echo -n "Enter password for new user '$USERNAME': "
read -s USER_PASS
echo

# === Pre-check: Ensure rsync is installed ===
RSYNC_BIN="$(command -v /usr/bin/rsync || true)"
if [[ -z "$RSYNC_BIN" ]]; then
    echo "Error: 'rsync' is not installed or not in PATH. Please install rsync and retry." >&2
    exit 1
fi

# === Step 2: Prompt for public key ===
echo "Enter or paste the public SSH key for '$USERNAME' (single line), or provide a path to a key file:"
read -r PUBKEY_INPUT

# Determine if it's a file or raw key string
if [[ -f "$PUBKEY_INPUT" ]]; then
    PUBKEY_CONTENT=$(cat "$PUBKEY_INPUT")
else
    PUBKEY_CONTENT="$PUBKEY_INPUT"
fi

# === Step 3: Create user if not exists ===
if ! id "$USERNAME" &>/dev/null; then
    /usr/sbin/useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$USER_PASS" | /usr/sbin/chpasswd
    echo "User '$USERNAME' created."
else
    echo "User '$USERNAME' already exists."
fi

# === Step 4: Add public key ===
mkdir -p "$USER_HOME/.ssh"
echo "$PUBKEY_CONTENT" >> "$AUTHORIZED_KEYS"
chmod 600 "$AUTHORIZED_KEYS"
chmod 700 "$USER_HOME/.ssh"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"
echo "Public key installed for '$USERNAME'."

# Create a symbolic link to the user-provided source folder
ln -s "$SOURCE_FOLDER" /home/synced_folder

# === Step 5: Create restricted rsync wrapper ===
mkdir -p "$(dirname "$WRAPPER_PATH")"

cat > "$WRAPPER_PATH" <<EOF
#!/bin/bash

# Allow only rsync access to specified path
case "\$@" in
    *"/home/synced_folder"* )
        # Use the system rsync binary resolved at script runtime
        /usr/bin/rsync "\$@"
        ;;
    *)
        echo "Access denied. You can only rsync /home/synced_folder"
        exit 1
        ;;
esac
EOF

chmod +x "$WRAPPER_PATH"
echo "Restricted rsync wrapper created at $WRAPPER_PATH"

# Check if sudo is installed
if ! command -v sudo &>/dev/null; then
    echo "Error: 'sudo' is not installed. Please install sudo to proceed with permissions setup."
    echo "You can install it manually and then run 'visudo' to add this line:"
    echo "$USERNAME ALL=(ALL) NOPASSWD: $WRAPPER_PATH"
    exit 1
fi

# Ask user if they want to edit sudo permissions now
echo -n "Do you want to edit sudo permissions now? (y/N): "
read -r EDIT_SUDO

if [[ "${EDIT_SUDO,,}" == "y" ]]; then
    echo "$USERNAME ALL=(ALL) NOPASSWD: $WRAPPER_PATH" | sudo EDITOR='tee -a' /usr/sbin/visudo
else
    echo "=== Done ==="
    echo "Remember to run 'visudo' and allow sudo access for '$USERNAME' to the wrapper:"
    echo "$USERNAME ALL=(ALL) NOPASSWD: $WRAPPER_PATH"
fi
