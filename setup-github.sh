#!/bin/bash

# GitHub Setup Script for pteroanyinstall
# This script helps you quickly set up your GitHub repository

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              GITHUB REPOSITORY SETUP FOR PTEROANYINSTALL               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git is not installed!${NC}"
    echo ""
    echo "Please install Git first:"
    echo "  Windows: https://git-scm.com/download/win"
    echo "  Linux:   sudo apt install git"
    echo "  macOS:   brew install git"
    exit 1
fi

echo -e "${GREEN}✓ Git is installed${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "pteroanyinstall.sh" ]; then
    echo -e "${RED}✗ Error: pteroanyinstall.sh not found!${NC}"
    echo "Please run this script from the pteroanyinstall directory"
    exit 1
fi

echo -e "${GREEN}✓ In correct directory${NC}"
echo ""

# Git configuration
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  STEP 1: GIT CONFIGURATION${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if git is already configured
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    echo -e "${GREEN}✓ Git is already configured:${NC}"
    echo "  Name:  $GIT_NAME"
    echo "  Email: $GIT_EMAIL"
    echo ""
    read -p "Do you want to change these settings? (y/n): " change_config
    if [[ ! "$change_config" =~ ^[Yy]$ ]]; then
        echo "Keeping existing configuration"
    else
        GIT_NAME=""
        GIT_EMAIL=""
    fi
fi

if [ -z "$GIT_NAME" ]; then
    echo "Enter your name (for Git commits):"
    read -p "Name: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi

if [ -z "$GIT_EMAIL" ]; then
    echo "Enter your email (use your GitHub email):"
    read -p "Email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

echo ""
echo -e "${GREEN}✓ Git configured successfully${NC}"
echo ""

# GitHub username
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  STEP 2: GITHUB REPOSITORY${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Enter your GitHub username:"
read -p "Username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}✗ GitHub username is required!${NC}"
    exit 1
fi

echo ""
echo "Repository name (default: pteroanyinstall):"
read -p "Name [pteroanyinstall]: " REPO_NAME
REPO_NAME=${REPO_NAME:-pteroanyinstall}

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Go to https://github.com/new"
echo "2. Repository name: $REPO_NAME"
echo "3. Description: Automated Pterodactyl installation with P.R.I.S.M AI"
echo "4. Choose Public or Private"
echo "5. DO NOT initialize with README (we have one)"
echo "6. Click 'Create repository'"
echo ""

read -p "Press Enter when you've created the repository on GitHub..."

# Initialize git if not already done
if [ ! -d ".git" ]; then
    echo ""
    echo "Initializing Git repository..."
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
else
    echo -e "${GREEN}✓ Git repository already initialized${NC}"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    echo ""
    echo "Creating .gitignore..."
    cat > .gitignore <<'EOF'
# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Temporary files
*.tmp
*.bak
.cache/

# Sensitive data
*.key
*.pem
config.local.json
EOF
    echo -e "${GREEN}✓ .gitignore created${NC}"
fi

# Add all files
echo ""
echo "Adding files to Git..."
git add .
echo -e "${GREEN}✓ Files added${NC}"

# Create initial commit
echo ""
echo "Creating initial commit..."
git commit -m "Initial commit: Complete Pterodactyl automation suite with P.R.I.S.M AI

Features:
- Automated Pterodactyl Panel & Wings installation
- P.R.I.S.M AI assistant with Discord notifications
- Panel customization tools
- Pre-installation checks
- Automated backups and monitoring
- Quick setup scripts
- Comprehensive documentation"

echo -e "${GREEN}✓ Initial commit created${NC}"

# Add remote
echo ""
echo "Adding GitHub remote..."
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git" 2>/dev/null || \
git remote set-url origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo -e "${GREEN}✓ Remote added${NC}"

# Set main branch
echo ""
echo "Setting main branch..."
git branch -M main
echo -e "${GREEN}✓ Branch set to main${NC}"

# Update install.sh with correct URL
echo ""
echo "Updating install.sh with your repository URL..."
sed -i.bak "s|yourusername|$GITHUB_USERNAME|g" install.sh
sed -i.bak "s|YOUR_USERNAME|$GITHUB_USERNAME|g" install.sh
rm -f install.sh.bak

# Update pteroanyinstall.sh with correct URL
sed -i.bak "s|yourusername|$GITHUB_USERNAME|g" pteroanyinstall.sh
sed -i.bak "s|YOUR_USERNAME|$GITHUB_USERNAME|g" pteroanyinstall.sh
rm -f pteroanyinstall.sh.bak

git add install.sh pteroanyinstall.sh
git commit -m "Update repository URLs with GitHub username" 2>/dev/null || true

echo -e "${GREEN}✓ Repository URLs updated${NC}"

# Authentication
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  STEP 3: GITHUB AUTHENTICATION${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Choose authentication method:"
echo "  1) Personal Access Token (Recommended)"
echo "  2) SSH Key"
echo ""
read -p "Choice [1]: " AUTH_CHOICE
AUTH_CHOICE=${AUTH_CHOICE:-1}

if [ "$AUTH_CHOICE" == "2" ]; then
    # SSH Key setup
    echo ""
    echo "Setting up SSH key..."
    
    if [ ! -f "$HOME/.ssh/id_ed25519.pub" ] && [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo "Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
        echo -e "${GREEN}✓ SSH key generated${NC}"
    else
        echo -e "${GREEN}✓ SSH key already exists${NC}"
    fi
    
    echo ""
    echo "Your public SSH key:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || cat "$HOME/.ssh/id_rsa.pub"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Add this key to GitHub:"
    echo "1. Go to https://github.com/settings/keys"
    echo "2. Click 'New SSH key'"
    echo "3. Title: pteroanyinstall"
    echo "4. Paste the key above"
    echo "5. Click 'Add SSH key'"
    echo ""
    read -p "Press Enter when you've added the SSH key to GitHub..."
    
    # Change remote to SSH
    git remote set-url origin "git@github.com:$GITHUB_USERNAME/$REPO_NAME.git"
    echo -e "${GREEN}✓ Remote changed to SSH${NC}"
else
    # Personal Access Token
    echo ""
    echo "Create a Personal Access Token:"
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Click 'Generate new token (classic)'"
    echo "3. Note: pteroanyinstall access"
    echo "4. Select scopes: repo (all), workflow"
    echo "5. Click 'Generate token'"
    echo "6. COPY THE TOKEN (you won't see it again!)"
    echo ""
    echo "You'll be asked for your token when pushing to GitHub"
    echo "Use the token as your password"
    echo ""
fi

# Push to GitHub
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  STEP 4: PUSH TO GITHUB${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Pushing to GitHub..."
if git push -u origin main; then
    echo ""
    echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
else
    echo ""
    echo -e "${RED}✗ Push failed${NC}"
    echo ""
    echo "If using Personal Access Token:"
    echo "  Username: $GITHUB_USERNAME"
    echo "  Password: <your token>"
    echo ""
    echo "Try pushing manually:"
    echo "  git push -u origin main"
    exit 1
fi

# Success!
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                        SETUP COMPLETE!                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Your repository is now on GitHub:"
echo -e "${BLUE}https://github.com/$GITHUB_USERNAME/$REPO_NAME${NC}"
echo ""

echo "One-line installation command:"
echo -e "${BLUE}bash <(curl -s https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/install.sh)${NC}"
echo ""

echo "Next steps:"
echo "  1. Test the one-line installer on a fresh server"
echo "  2. Add repository topics on GitHub (pterodactyl, automation, ai, monitoring)"
echo "  3. Enable GitHub Pages for documentation (optional)"
echo "  4. Create a release (optional)"
echo ""

echo "To update your repository in the future:"
echo "  git add ."
echo "  git commit -m \"Your commit message\""
echo "  git push"
echo ""

echo -e "${GREEN}Happy hosting! 🚀${NC}"
