#!/bin/bash

#######################################
# EST Password Reset Script
# Resets the Enhanced SSH Terminal password
#######################################

set -e

CONFIG_FILE="/etc/automatic-system/est-auth.conf"

echo "=========================================="
echo "  Enhanced SSH Terminal - Password Reset"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Prompt for new password
echo "Enter new password (minimum 6 characters):"
read -s NEW_PASSWORD
echo ""

echo "Confirm new password:"
read -s CONFIRM_PASSWORD
echo ""

# Validate passwords match
if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "❌ Passwords do not match!"
    exit 1
fi

# Validate password length
if [ ${#NEW_PASSWORD} -lt 6 ]; then
    echo "❌ Password must be at least 6 characters!"
    exit 1
fi

echo "🔐 Generating bcrypt hash..."

# Generate bcrypt hash using Node.js
HASH=$(node -e "
const bcrypt = require('bcrypt');
bcrypt.hash('$NEW_PASSWORD', 10, (err, hash) => {
    if (err) {
        console.error('Error:', err);
        process.exit(1);
    }
    console.log(hash);
});
")

if [ -z "$HASH" ]; then
    echo "❌ Failed to generate password hash!"
    exit 1
fi

# Generate session secret
SESSION_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

# Create config directory if it doesn't exist
mkdir -p /etc/automatic-system

# Write config file
cat > "$CONFIG_FILE" << EOF
# Enhanced SSH Terminal Authentication Configuration
# Updated: $(date -Iseconds)

EST_PASSWORD_HASH="$HASH"
SESSION_SECRET="$SESSION_SECRET"
EOF

# Set proper permissions
chmod 600 "$CONFIG_FILE"

echo "✅ Password reset successfully!"
echo "📁 Configuration saved to: $CONFIG_FILE"
echo ""
echo "🔄 Restarting EST authentication service..."
systemctl restart est-auth

echo ""
echo "✅ Done! You can now login with your new password at:"
echo "   https://ssh.cloudmc.online"
echo ""
