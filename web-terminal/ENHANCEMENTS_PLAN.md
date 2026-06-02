# Enhanced SSH Terminal - Feature Enhancements Plan

## 1. Real Filesystem Viewer Tree

### Current State
- Static demo filesystem structure
- No real SSH connection to browse files
- Limited to predefined folders

### Enhancement Plan
**Backend API Required:**
```bash
# Create endpoint: /api/filesystem/list
POST /api/filesystem/list
{
  "serverId": "server-123",
  "path": "/home/user"
}

Response:
{
  "path": "/home/user",
  "items": [
    {
      "name": "Documents",
      "type": "directory",
      "size": null,
      "permissions": "drwxr-xr-x",
      "modified": "2026-06-01T10:00:00Z"
    },
    {
      "name": "script.sh",
      "type": "file",
      "size": 1024,
      "permissions": "-rw-r--r--",
      "modified": "2026-06-01T09:30:00Z"
    }
  ]
}
```

**Frontend Enhancements:**
- Real-time directory browsing via SSH
- Lazy loading (load folders on expand)
- File icons based on extension
- Right-click context menu (download, edit, delete, rename)
- Drag-and-drop file upload
- Search/filter files
- Breadcrumb navigation
- File preview for text files

**Implementation:**
1. Add SSH command execution: `ls -la --color=never <path>`
2. Parse output to JSON structure
3. Cache directory listings
4. Add loading states
5. Error handling for permission denied

---

## 2. Code Snippets with Search & Ghost Commands

### Current State
- Basic snippets panel exists
- No search functionality
- No autocomplete/ghost commands while typing

### Enhancement Plan A: Search in Snippets Panel
```javascript
// Add search input to snippets panel
<input type="text" 
       id="snippetSearch" 
       placeholder="Search snippets..." 
       oninput="filterSnippets(this.value)">

function filterSnippets(query) {
    const filtered = snippets.filter(s => 
        s.name.toLowerCase().includes(query.toLowerCase()) ||
        s.command.toLowerCase().includes(query.toLowerCase()) ||
        s.category.toLowerCase().includes(query.toLowerCase())
    );
    renderSnippets(filtered);
}
```

### Enhancement Plan B: Ghost Commands (Autocomplete)
**Like Fish shell or GitHub Copilot:**
```javascript
// Show ghost command as you type
input.addEventListener('input', (e) => {
    const typed = e.target.value;
    const match = findBestMatch(typed, commandHistory, snippets);
    
    if (match) {
        showGhostText(match, typed.length);
    }
});

// Press Tab or Right Arrow to accept
input.addEventListener('keydown', (e) => {
    if (e.key === 'Tab' || e.key === 'ArrowRight') {
        if (ghostTextVisible) {
            e.preventDefault();
            acceptGhostText();
        }
    }
});
```

**Features:**
- Match from command history
- Match from snippets
- Match from common commands
- Fuzzy matching
- Show in gray text after cursor
- Accept with Tab or Right Arrow
- Dismiss with Escape

---

## 3. Open WebUI Models on Nextcloud

### Why Models Disappeared

**Possible Causes:**

#### A. Docker Volume Mapping Issue
If Open WebUI is running in Docker and models are stored on Nextcloud:
```bash
# Check current volume mapping
docker inspect open-webui | grep -A 10 Mounts

# Models should be at:
/var/lib/docker/volumes/open-webui/_data/models
# OR mapped to Nextcloud:
/mnt/nextcloud/ollama-models:/root/.ollama/models
```

**Problem:** If the Nextcloud mount was temporary or disconnected, models appear gone.

#### B. Ollama Update Cleared Models
```bash
# Check Ollama version
ollama --version

# Models location changed in updates:
# Old: ~/.ollama/models
# New: /usr/share/ollama/.ollama/models
```

**Problem:** Update may have changed model storage location.

#### C. Nextcloud Sync Issue
```bash
# Check if Nextcloud is mounted
df -h | grep nextcloud
mount | grep nextcloud

# Check if files exist
ls -lah /mnt/nextcloud/ollama-models/
```

**Problem:** Nextcloud client may have stopped syncing or unmounted.

### Solution Steps

#### 1. Verify Model Location
```bash
# Find where Ollama stores models
ollama list
# If empty, check:
find / -name "*.gguf" 2>/dev/null
find / -name "qwen2.5*" 2>/dev/null
```

#### 2. Check Nextcloud Mount
```bash
# If using nextcloud client
systemctl status nextcloud-client

# If using WebDAV mount
mount | grep nextcloud
cat /etc/fstab | grep nextcloud
```

#### 3. Restore Models

**Option A: Models still on Nextcloud**
```bash
# Remount Nextcloud
sudo mount -a

# Or restart Nextcloud client
systemctl restart nextcloud-client

# Verify models are visible
ls -lah /mnt/nextcloud/ollama-models/

# Restart Ollama
sudo systemctl restart ollama
```

**Option B: Models were deleted (need to re-download)**
```bash
# Pull models again
ollama pull qwen2.5:7b
ollama pull llama3.2:3b
ollama pull mistral:7b

# Verify
ollama list
```

#### 4. Proper Nextcloud Integration

**Best Practice: Use Nextcloud as backup, not primary storage**
```bash
# 1. Store models locally for performance
OLLAMA_MODELS=/var/lib/ollama/models

# 2. Sync to Nextcloud as backup
rsync -av /var/lib/ollama/models/ /mnt/nextcloud/ollama-models/

# 3. Create cron job for automatic backup
crontab -e
# Add: 0 2 * * * rsync -av /var/lib/ollama/models/ /mnt/nextcloud/ollama-models/
```

**Why:** 
- Ollama needs fast local access to models
- Network storage (Nextcloud) is too slow for inference
- Use Nextcloud for backup/sync only

### Recommended Setup

```bash
# 1. Install Ollama locally
curl -fsSL https://ollama.com/install.sh | sh

# 2. Pull models to local storage
ollama pull qwen2.5:7b

# 3. Verify models are local
ls -lah ~/.ollama/models/

# 4. Create backup script
cat > /usr/local/bin/backup-ollama-models.sh << 'EOF'
#!/bin/bash
rsync -av --delete ~/.ollama/models/ /mnt/nextcloud/ollama-models/
echo "$(date): Ollama models backed up to Nextcloud" >> /var/log/ollama-backup.log
EOF

chmod +x /usr/local/bin/backup-ollama-models.sh

# 5. Schedule daily backups
crontab -e
# Add: 0 3 * * * /usr/local/bin/backup-ollama-models.sh
```

---

## Implementation Priority

1. **Ghost Commands** (High Priority - Best UX improvement)
   - Autocomplete as you type
   - Match from history and snippets
   - Easy to implement, big impact

2. **Snippet Search** (Medium Priority)
   - Add search input to existing panel
   - Filter snippets in real-time
   - Quick win

3. **Real Filesystem Viewer** (Low Priority - Requires Backend)
   - Needs SSH command execution API
   - More complex implementation
   - Can use existing file browser as starting point

---

## Next Steps

1. Implement ghost command autocomplete
2. Add search to snippets panel
3. Create backend API for filesystem browsing
4. Fix Nextcloud/Ollama model storage issue
