#!/bin/bash

# Simple test script to diagnose Termux SSH setup issues

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Termux SSH Setup Diagnostic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check internet connection
echo "1. Testing internet connection..."
if curl -s --max-time 5 https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/README.md > /dev/null 2>&1; then
    echo "   ✓ Internet connection OK"
else
    echo "   ✗ Cannot reach GitHub - check your internet connection"
    exit 1
fi

# Check if running as root
echo ""
echo "2. Checking root access..."
if [ "$EUID" -eq 0 ]; then
    echo "   ✓ Running as root"
else
    echo "   ✗ Not running as root - please use sudo"
    exit 1
fi

# Check required commands
echo ""
echo "3. Checking required commands..."
for cmd in curl whiptail apt-get; do
    if command -v $cmd &> /dev/null; then
        echo "   ✓ $cmd found"
    else
        echo "   ✗ $cmd not found - installing..."
        if [ "$cmd" = "whiptail" ]; then
            apt-get update -qq && apt-get install -y whiptail
        fi
    fi
done

# Try to download the script
echo ""
echo "4. Testing script download..."
if curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh -o /tmp/test-termux-download.sh; then
    echo "   ✓ Script downloaded successfully"
    
    # Check file size
    size=$(stat -f%z /tmp/test-termux-download.sh 2>/dev/null || stat -c%s /tmp/test-termux-download.sh 2>/dev/null)
    echo "   ✓ File size: $size bytes"
    
    # Check for version string
    if grep -q "SCRIPT_VERSION" /tmp/test-termux-download.sh; then
        version=$(grep "SCRIPT_VERSION=" /tmp/test-termux-download.sh | head -1 | cut -d'"' -f2)
        echo "   ✓ Script version: $version"
    else
        echo "   ✗ Version string not found in script"
    fi
    
    # Check if executable
    chmod +x /tmp/test-termux-download.sh
    echo "   ✓ Made executable"
else
    echo "   ✗ Failed to download script"
    exit 1
fi

# Try to download cloudflare script
echo ""
echo "5. Testing Cloudflare script download..."
if curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/cloudflare-ssh-tunnel.sh -o /tmp/test-cf-download.sh; then
    echo "   ✓ Cloudflare script downloaded successfully"
    size=$(stat -f%z /tmp/test-cf-download.sh 2>/dev/null || stat -c%s /tmp/test-cf-download.sh 2>/dev/null)
    echo "   ✓ File size: $size bytes"
else
    echo "   ✗ Failed to download Cloudflare script"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Diagnostic Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If all checks passed, try running:"
echo "  bash /tmp/test-termux-download.sh"
echo ""
echo "Or run the full installer:"
echo "  bash <(curl -sL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/termux-ssh-setup.sh)"
echo ""
