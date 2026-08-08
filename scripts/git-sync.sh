#!/bin/bash

# Git Auto Sync Script
# Automatically commits, pulls, and pushes changes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the script directory and navigate to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Git Auto Sync - pteroanyinstall               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}✗ Not a git repository!${NC}"
    exit 1
fi

# Get current branch
BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch:${NC} $BRANCH"
echo ""

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Uncommitted changes detected:${NC}"
    git status -s
    echo ""
    
    # Ask for commit message
    read -p "Enter commit message (or press Enter for auto-message): " commit_msg
    
    if [ -z "$commit_msg" ]; then
        commit_msg="Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    echo -e "${YELLOW}Staging all changes...${NC}"
    git add -A
    
    echo -e "${YELLOW}Committing with message: ${NC}\"$commit_msg\""
    git commit -m "$commit_msg"
    echo -e "${GREEN}✓ Changes committed!${NC}"
    echo ""
else
    echo -e "${GREEN}✓ No uncommitted changes${NC}"
    echo ""
fi

# Pull latest changes
echo -e "${YELLOW}Pulling latest changes from origin/$BRANCH...${NC}"
if git pull origin "$BRANCH" --rebase; then
    echo -e "${GREEN}✓ Pull successful!${NC}"
else
    echo -e "${RED}✗ Pull failed! Resolve conflicts manually.${NC}"
    exit 1
fi
echo ""

# Push changes
echo -e "${YELLOW}Pushing changes to origin/$BRANCH...${NC}"
if git push origin "$BRANCH"; then
    echo -e "${GREEN}✓ Push successful!${NC}"
else
    echo -e "${RED}✗ Push failed!${NC}"
    exit 1
fi
echo ""

# Show summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Sync Complete! ✓                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Latest commits:${NC}"
git log --oneline -5
