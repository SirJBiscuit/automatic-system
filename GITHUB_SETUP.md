# GitHub Repository Setup Guide

## Quick Setup

### 1. Initialize Git Repository

```bash
cd /path/to/pteroanyinstall
git init
git add .
git commit -m "Initial commit: Pterodactyl Universal Installer"
```

### 2. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `pteroanyinstall`
3. Description: `Universal Pterodactyl Panel and Wings installer for any Linux distribution`
4. Public or Private: **Public** (recommended)
5. Click "Create repository"

### 3. Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/pteroanyinstall.git
git branch -M main
git push -u origin main
```

### 4. Update URLs in Scripts

Replace `yourusername` with your actual GitHub username in:
- `install.sh`
- `pteroanyinstall.sh`
- `README.md`

```bash
# Quick find and replace
sed -i 's/yourusername/YOUR_ACTUAL_USERNAME/g' install.sh
sed -i 's/yourusername/YOUR_ACTUAL_USERNAME/g' pteroanyinstall.sh
sed -i 's/yourusername/YOUR_ACTUAL_USERNAME/g' README.md
```

## Repository Structure

```
pteroanyinstall/
├── .github/
│   └── workflows/
│       └── shellcheck.yml          # Automated shell script linting
├── pteroanyinstall.sh              # Main installation script
├── pre-install-checks.sh           # Pre-installation verification
├── billing-setup.sh                # Billing system setup
├── panel-customizer.sh             # Panel appearance customization
├── install.sh                      # Quick installer from GitHub
├── README.md                       # Main documentation
├── INSTALL_GUIDE.md                # Detailed installation guide
├── CUSTOMIZATION_GUIDE.md          # Panel customization guide
├── BILLING_GUIDE.md                # Billing system guide
├── ENHANCED_FEATURES.md            # Enhanced features documentation
├── FEATURES.md                     # Feature list
├── QUICK_START.md                  # Quick start guide
├── EXAMPLES.md                     # Usage examples
├── CHANGELOG.md                    # Version history
├── GITHUB_SETUP.md                 # This file
├── LICENSE                         # MIT License
└── .gitignore                      # Git ignore rules
```

## One-Line Installation

After pushing to GitHub, users can install with:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main/install.sh | sudo bash
```

Or download and run:

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/pteroanyinstall/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## GitHub Features to Enable

### 1. GitHub Actions (Automated Testing)

Already configured in `.github/workflows/shellcheck.yml`

This will automatically:
- Check shell scripts for errors
- Validate syntax
- Run on every push and pull request

### 2. GitHub Releases

Create releases for version tracking:

```bash
git tag -a v2.0.0 -m "Version 2.0.0 - Enhanced features release"
git push origin v2.0.0
```

Then create a release on GitHub:
1. Go to repository → Releases → Create a new release
2. Choose tag: v2.0.0
3. Release title: "v2.0.0 - Enhanced Features"
4. Add release notes from CHANGELOG.md
5. Publish release

### 3. GitHub Pages (Documentation)

Enable GitHub Pages for documentation:

1. Repository Settings → Pages
2. Source: Deploy from branch
3. Branch: main
4. Folder: / (root)
5. Save

Documentation will be available at:
`https://YOUR_USERNAME.github.io/pteroanyinstall/`

### 4. Repository Topics

Add topics to make your repo discoverable:

Settings → Topics → Add:
- pterodactyl
- pterodactyl-panel
- pterodactyl-wings
- game-server
- hosting
- automation
- installer
- linux
- bash
- shell-script

### 5. Repository Description

Add a clear description:
```
🚀 Universal Pterodactyl Panel and Wings installer with automated billing, panel customization, and pre-installation checks. Works on any Linux distribution.
```

### 6. README Badges

Add badges to README.md:

```markdown
![GitHub release](https://img.shields.io/github/v/release/YOUR_USERNAME/pteroanyinstall)
![GitHub stars](https://img.shields.io/github/stars/YOUR_USERNAME/pteroanyinstall)
![GitHub license](https://img.shields.io/github/license/YOUR_USERNAME/pteroanyinstall)
![ShellCheck](https://github.com/YOUR_USERNAME/pteroanyinstall/workflows/ShellCheck/badge.svg)
```

## Updating the Repository

### After Making Changes

```bash
git add .
git commit -m "Description of changes"
git push origin main
```

### Creating a New Version

```bash
# Update VERSION in pteroanyinstall.sh
# Update CHANGELOG.md

git add .
git commit -m "Release v2.1.0"
git tag -a v2.1.0 -m "Version 2.1.0"
git push origin main
git push origin v2.1.0
```

## Branch Strategy

### Main Branch
- Stable, production-ready code
- All releases tagged here
- Protected branch (require pull requests)

### Develop Branch (Optional)

```bash
git checkout -b develop
git push -u origin develop
```

- Development and testing
- Merge to main when stable

### Feature Branches

```bash
git checkout -b feature/new-feature
# Make changes
git commit -m "Add new feature"
git push -u origin feature/new-feature
# Create pull request on GitHub
```

## Collaboration

### Enable Issues

Repository Settings → Features → Issues ✓

Categories:
- Bug report
- Feature request
- Question
- Documentation

### Pull Request Template

Create `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested on Ubuntu 22.04
- [ ] Tested on Debian 11
- [ ] Tested on CentOS 8
- [ ] ShellCheck passed

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

### Issue Templates

Create `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: Report a bug or issue
title: '[BUG] '
labels: bug
---

**Describe the bug**
A clear description of the bug.

**To Reproduce**
Steps to reproduce the behavior.

**Expected behavior**
What you expected to happen.

**System Information**
- OS: [e.g., Ubuntu 22.04]
- Script version: [e.g., 2.0.0]

**Logs**
Paste relevant logs here.
```

## Security

### Security Policy

Create `SECURITY.md`:

```markdown
# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities to:
- Email: security@yourdomain.com
- GitHub Security Advisories

Do not create public issues for security vulnerabilities.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x.x   | :white_check_mark: |
| 1.x.x   | :x:                |
```

### Dependabot (Optional)

Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Marketing Your Repository

### 1. Share on Social Media
- Twitter/X with #pterodactyl hashtag
- Reddit: r/pterodactyl, r/selfhosted
- Discord: Pterodactyl community

### 2. Add to Lists
- Awesome Pterodactyl lists
- Awesome Self-Hosted lists
- Awesome Bash lists

### 3. Write Blog Post
- Dev.to
- Medium
- Your own blog

### 4. Create Demo Video
- YouTube tutorial
- Asciinema recording
- GIF demonstrations

## Maintenance

### Regular Tasks

**Weekly:**
- Check and respond to issues
- Review pull requests
- Update dependencies

**Monthly:**
- Review and update documentation
- Check for Pterodactyl updates
- Test on latest OS versions

**Quarterly:**
- Major version releases
- Feature additions
- Performance improvements

## Analytics

### GitHub Insights

Monitor:
- Stars and forks
- Clone statistics
- Traffic sources
- Popular content

### User Feedback

Encourage feedback:
- GitHub Discussions
- Issue templates
- Community Discord/Slack

## Backup

### Regular Backups

```bash
# Backup repository
git clone --mirror https://github.com/YOUR_USERNAME/pteroanyinstall.git
cd pteroanyinstall.git
git bundle create ../pteroanyinstall-backup.bundle --all
```

### Mirror to Other Platforms

Consider mirroring to:
- GitLab
- Bitbucket
- Gitea (self-hosted)

## License

MIT License is recommended for open-source projects.

Already included in `LICENSE` file.

## Support

### Documentation
- README.md - Overview and quick start
- INSTALL_GUIDE.md - Detailed installation
- CUSTOMIZATION_GUIDE.md - Customization options
- BILLING_GUIDE.md - Billing system setup

### Community
- GitHub Issues - Bug reports and features
- GitHub Discussions - Q&A and community
- Discord - Real-time chat (if you create one)

## Success Metrics

Track:
- ⭐ GitHub stars
- 🍴 Forks
- 📥 Clone count
- 🐛 Issues resolved
- 🎉 Pull requests merged
- 👥 Contributors

## Next Steps

1. ✅ Push to GitHub
2. ✅ Update URLs in scripts
3. ✅ Enable GitHub Actions
4. ✅ Create first release
5. ✅ Add repository topics
6. ✅ Share with community
7. ✅ Monitor and maintain

Happy coding! 🚀
