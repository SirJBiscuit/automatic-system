# Git Auto Sync Script (PowerShell)
# Automatically commits, pulls, and pushes changes

param(
    [string]$CommitMessage = ""
)

# Navigate to repo root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
Set-Location $RepoDir

Write-Host "============================================================" -ForegroundColor Blue
Write-Host "              Git Auto Sync - pteroanyinstall               " -ForegroundColor Blue
Write-Host "============================================================" -ForegroundColor Blue
Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "✗ Not a git repository!" -ForegroundColor Red
    exit 1
}

# Get current branch
$Branch = git branch --show-current
Write-Host "Current branch: $Branch" -ForegroundColor Blue
Write-Host ""

# Check for uncommitted changes
$Status = git status -s
if ($Status) {
    Write-Host "Uncommitted changes detected:" -ForegroundColor Yellow
    git status -s
    Write-Host ""
    
    # Use provided commit message or ask for one
    if (-not $CommitMessage) {
        $CommitMessage = Read-Host "Enter commit message (or press Enter for auto-message)"
    }
    
    if (-not $CommitMessage) {
        $CommitMessage = "Auto-sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    
    Write-Host "Staging all changes..." -ForegroundColor Yellow
    git add -A
    
    Write-Host "Committing with message: `"$CommitMessage`"" -ForegroundColor Yellow
    git commit -m $CommitMessage
    Write-Host "✓ Changes committed!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "✓ No uncommitted changes" -ForegroundColor Green
    Write-Host ""
}

# Pull latest changes
Write-Host "Pulling latest changes from origin/$Branch..." -ForegroundColor Yellow
git pull origin $Branch --rebase
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Pull successful!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Pull failed! Resolve conflicts manually." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Push changes
Write-Host "Pushing changes to origin/$Branch..." -ForegroundColor Yellow
git push origin $Branch
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Push successful!" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Push failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Show summary
Write-Host "============================================================" -ForegroundColor Green
Write-Host "                    Sync Complete!                          " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Latest commits:" -ForegroundColor Blue
git log --oneline -5
