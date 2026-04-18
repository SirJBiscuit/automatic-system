# 🚀 GitHub Setup - Quick Guide

## Step-by-Step Instructions

### Option 1: Automated Setup (Easiest!)

```bash
# Run the automated setup script
chmod +x setup-github.sh
./setup-github.sh
```

This script will:
- ✅ Configure Git
- ✅ Create GitHub repository
- ✅ Set up authentication
- ✅ Push your code
- ✅ Update all URLs automatically

**Time:** 5-10 minutes

---

### Option 2: Manual Setup

#### 1. Install Git

**Windows:**
```powershell
winget install --id Git.Git -e --source winget
```

**Linux:**
```bash
sudo apt install git  # Ubuntu/Debian
sudo yum install git  # CentOS/RHEL
```

#### 2. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

#### 3. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `pteroanyinstall`
3. Description: "Automated Pterodactyl installation with P.R.I.S.M AI"
4. Choose Public
5. **DO NOT** check "Add a README file"
6. Click "Create repository"

#### 4. Push Your Code

```bash
cd C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall

# Initialize Git
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: Complete Pterodactyl automation suite with P.R.I.S.M AI"

# Add remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/pteroanyinstall.git

# Push to GitHub
git branch -M main
git push -u origin main
```

#### 5. Update Repository URLs

Edit `install.sh` and replace:
```bash
REPO_URL="https://raw.githubusercontent.com/yourusername/pteroanyinstall/main"
```

With:
```bash
REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main"
```

Then commit:
```bash
git add install.sh
git commit -m "Update repository URL"
git push
```

---

## 🔐 Authentication Options

### Option A: Personal Access Token (Recommended)

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Note: "pteroanyinstall access"
4. Select scopes: `repo` (all), `workflow`
5. Click "Generate token"
6. **COPY THE TOKEN** (you won't see it again!)
7. Use token as password when pushing

### Option B: SSH Key

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub:
# 1. Go to https://github.com/settings/keys
# 2. Click "New SSH key"
# 3. Paste your public key
# 4. Click "Add SSH key"

# Change remote to SSH
git remote set-url origin git@github.com:YOUR_USERNAME/pteroanyinstall.git
```

---

## ✅ Verify Setup

```bash
# Check remote
git remote -v

# Test one-line installer
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main/install.sh)
```

---

## 📚 Next Steps

After GitHub is set up:

1. **Read the Complete Setup Guide:**
   - Open `COMPLETE_SETUP_GUIDE.md`
   - Follow from Part 2: Server Preparation

2. **Test Installation:**
   - Get a test server
   - Run the one-line installer
   - Verify everything works

3. **Customize:**
   - Add repository topics on GitHub
   - Enable GitHub Pages (optional)
   - Create releases (optional)

---

## 🆘 Troubleshooting

### Push Failed

**If using Personal Access Token:**
- Username: Your GitHub username
- Password: Your token (not your GitHub password!)

**If using SSH:**
```bash
# Test SSH connection
ssh -T git@github.com

# Should see: "Hi USERNAME! You've successfully authenticated"
```

### Wrong Repository URL

```bash
# Check current remote
git remote -v

# Change remote URL
git remote set-url origin https://github.com/YOUR_USERNAME/pteroanyinstall.git
```

### Permission Denied

```bash
# Make sure you're the owner of the repository
# Or you've been added as a collaborator
```

---

## 🎉 Success!

Your repository is now on GitHub!

**One-line installation command:**
```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main/install.sh)
```

**Next:** Follow `COMPLETE_SETUP_GUIDE.md` starting from Part 2!
