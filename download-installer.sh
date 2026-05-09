#!/bin/bash

# Simple installer downloader
# This ensures you get the actual script, not HTML

echo "Downloading Pterodactyl Automatic System installer..."

# Try multiple methods
if command -v curl &> /dev/null; then
    echo "Using curl..."
    curl -L -o installer.sh "https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh"
elif command -v wget &> /dev/null; then
    echo "Using wget..."
    wget -O installer.sh "https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/installer.sh"
else
    echo "Error: Neither curl nor wget found!"
    exit 1
fi

# Check if download was successful
if [ ! -f installer.sh ]; then
    echo "Error: Download failed!"
    exit 1
fi

# Check if it's actually a bash script
if head -1 installer.sh | grep -q "#!/bin/bash"; then
    echo "✓ Download successful!"
    chmod +x installer.sh
    echo ""
    echo "Run the installer with:"
    echo "  sudo ./installer.sh"
else
    echo "✗ Downloaded file is not a bash script!"
    echo "First line of file:"
    head -1 installer.sh
    echo ""
    echo "This might be a GitHub authentication issue."
    echo "The repository might be private."
    exit 1
fi
