# GitHub Upload Instructions

## Quick Upload to GitHub

Follow these steps to upload the Ollama setup to your repository:

### 1. Navigate to Repository

```powershell
cd "C:\Users\Jeremiah Payne\CascadeProjects\pteroanyinstall"
```

### 2. Check Git Status

```powershell
git status
```

### 3. Add New Files

```powershell
# Add the ollama-setup folder
git add ollama-setup/

# Add the updated README
git add README.md
```

### 4. Commit Changes

```powershell
git commit -m "Add Ollama + Open WebUI automated setup with GPU support and Cloudflare tunnels"
```

### 5. Push to GitHub

```powershell
git push origin main
```

If you're pushing to a different branch:

```powershell
git push origin <branch-name>
```

## What's Being Added

The following files will be uploaded:

```
pteroanyinstall/
├── ollama-setup/
│   ├── README.md                    # Complete user documentation
│   ├── ollama-webui-setup.sh        # Main automated setup script
│   └── install-ollama.sh            # Quick installer that downloads from GitHub
└── README.md                        # Updated main README with Ollama section
```

## After Upload

Once pushed, users can install Ollama + Open WebUI with:

```bash
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ollama-setup/install-ollama.sh -o install-ollama.sh
chmod +x install-ollama.sh
./install-ollama.sh
```

## Verify Upload

After pushing, visit:
- https://github.com/SirJBiscuit/automatic-system/tree/main/ollama-setup

You should see:
- ✅ README.md
- ✅ ollama-webui-setup.sh
- ✅ install-ollama.sh

## Troubleshooting

### If you get "fatal: not a git repository"

```powershell
# Initialize git
git init

# Add remote
git remote add origin https://github.com/SirJBiscuit/automatic-system.git

# Pull existing files
git pull origin main

# Then follow steps 3-5 above
```

### If you get authentication errors

```powershell
# Use GitHub CLI
gh auth login

# Or configure git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### If you want to create a new branch

```powershell
# Create and switch to new branch
git checkout -b ollama-setup-feature

# Push to new branch
git push origin ollama-setup-feature
```

## Alternative: Manual Upload via GitHub Web Interface

If you prefer not to use command line:

1. Go to https://github.com/SirJBiscuit/automatic-system
2. Click "Add file" → "Upload files"
3. Drag and drop the `ollama-setup` folder
4. Add commit message: "Add Ollama + Open WebUI automated setup"
5. Click "Commit changes"

## Testing After Upload

After uploading, test the installation on a fresh server:

```bash
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ollama-setup/install-ollama.sh -o install-ollama.sh
chmod +x install-ollama.sh
./install-ollama.sh
```

This should download and run the full setup script automatically!
