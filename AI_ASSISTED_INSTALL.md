# 🤖 AI-Assisted Installation Guide

## What is AI-Assisted Installation?

AI-Assisted Installation is a **beginner-friendly mode** that installs a local AI assistant **before** installing Pterodactyl. The AI can then help you through the rest of the installation process, answer questions, and troubleshoot issues in real-time.

## Why Use AI-Assisted Installation?

### Perfect for Beginners
- ✅ **Never feel stuck** - Ask the AI anything during installation
- ✅ **Learn as you go** - Get explanations for technical concepts
- ✅ **Instant troubleshooting** - Fix errors without searching forums
- ✅ **24/7 availability** - No waiting for support responses

### What the AI Can Help With
- 📚 Explaining technical terms (DNS, SSL, reverse proxy, etc.)
- 🔧 Troubleshooting installation errors
- 🌐 Setting up domains and Cloudflare
- 🔒 Configuring SSL certificates
- 🛡️ Firewall and security setup
- 📝 Writing custom scripts
- ⚙️ Optimizing server performance
- 🎮 Creating game server configurations

## How It Works

### Installation Flow

```
1. Choose "AI Assistant First" from main menu
   ↓
2. Install Ollama (AI server) - 5 minutes
   ↓
3. Install Open WebUI (chat interface) - 3 minutes
   ↓
4. Download AI model - 10-15 minutes
   ↓
5. Setup domain (optional)
   ↓
6. AI Assistant ready at ai.yourdomain.com
   ↓
7. Continue with main installation
   ↓
8. Ask AI for help whenever needed!
```

### Total Time
- **Installation:** ~20 minutes
- **Model Download:** 10-15 minutes (one-time, runs in background)
- **Total:** ~30 minutes before you can start using the AI

## Step-by-Step Guide

### 1. Start the Installer

```bash
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install-interactive.sh | sudo bash
```

### 2. Choose AI-Assisted Mode

When the menu appears, select:
```
0 - 🤖 AI Assistant First (Recommended for Beginners!)
```

### 3. Confirm Installation

You'll see a confirmation dialog:
```
This will install an AI assistant FIRST, then help you with the rest!

Benefits:
• Get instant help during installation
• Ask questions about technical concepts
• Troubleshoot errors in real-time
• Learn as you install

The AI will be available at ai.yourdomain.com

Proceed with AI-assisted installation?
```

Click **Yes** to continue.

### 4. Ollama Installation

The installer will:
- Download and install Ollama
- Start the Ollama service
- Verify it's running correctly

**Progress:** `[████████░░░░░░░░] 30%`

### 5. Open WebUI Installation

The installer will:
- Install Docker (if needed)
- Pull the Open WebUI container
- Start the web interface on port 3000

**Progress:** `[████████████░░░░] 60%`

### 6. Domain Setup (Optional)

You'll be asked:
```
Would you like to set up a domain for your AI assistant?

This will make it accessible at ai.yourdomain.com
```

**Option A: Setup Domain**
- Follow the domain wizard
- Configure DNS records
- Get SSL certificate
- Access at: `https://ai.yourdomain.com`

**Option B: Skip Domain**
- Access locally at: `http://localhost:3000`
- Good for testing or local-only use

### 7. Choose AI Model

Select which AI model to download:

```
1. Llama 3.2 (Recommended) - 2GB, Fast & Smart
2. Mistral - 4GB, Very Capable
3. Phi-3 - 2GB, Efficient
4. CodeLlama - 4GB, Best for Code Help
5. Gemma 2 - 3GB, Google's Model
6. Skip for now (install model later)
```

**Recommendations:**
- **Beginners:** Llama 3.2 (fast, easy to use)
- **Technical users:** CodeLlama (best for scripts and commands)
- **Limited RAM:** Phi-3 (smallest, still capable)

### 8. Model Download

The selected model will download:
```
Downloading llama3.2...

This may take 10-15 minutes depending on your internet speed.

Model size: ~4GB
```

**Note:** This happens in the background. You can continue once it starts.

### 9. AI Assistant Ready!

You'll see:
```
🎉 AI Assistant Ready!

Access URL: https://ai.yourdomain.com
AI Model: llama3.2

First-time setup:
1. Open https://ai.yourdomain.com in your browser
2. Create an admin account
3. Start chatting with the AI!
```

### 10. Continue Installation

You'll be asked:
```
Would you like to continue with the main installation now?

You can:
• Keep the AI assistant open in another tab
• Ask it questions as you go
• Get help if you encounter errors

Continue to main installer?
```

**Yes:** Returns to main menu to install Panel/Wings/etc.  
**No:** Exits installer (AI remains running, install later)

## Using the AI Assistant

### First Time Setup

1. **Open the URL**
   ```
   https://ai.yourdomain.com
   ```

2. **Create Admin Account**
   - Email: your@email.com
   - Username: admin
   - Password: (choose a strong password)

3. **Start Chatting!**
   - The AI is pre-configured to help with installation
   - Just type your question and press Enter

### Example Conversations

#### Example 1: Understanding Domains

**You:**
```
I'm confused about domains. What's the difference between a domain and a subdomain?
```

**AI:**
```
Great question! Let me explain:

**Domain:** Your main website address (e.g., example.com)
- You buy this from a registrar like Namecheap or GoDaddy
- Costs about $10-15/year
- Example: myserver.com

**Subdomain:** A prefix added to your domain (e.g., panel.example.com)
- Free to create (unlimited)
- Points to the same or different server
- Examples:
  • panel.myserver.com (for Pterodactyl Panel)
  • node1.myserver.com (for Wings)
  • admin.myserver.com (for Admin Panel)

For Pterodactyl, you'll typically use subdomains like:
- panel.yourdomain.com → Pterodactyl Panel
- node1.yourdomain.com → Wings Node

Would you like help setting up your domains?
```

#### Example 2: Troubleshooting DNS

**You:**
```
I set up my DNS record but the domain isn't working. It says "DNS_PROBE_FINISHED_NXDOMAIN"
```

**AI:**
```
That error means the DNS record hasn't propagated yet. Here's how to fix it:

**1. Verify DNS Record is Created:**
```bash
dig panel.yourdomain.com
```

If it returns "NXDOMAIN", the record isn't set up correctly.

**2. Check Your DNS Provider:**
- Log in to Cloudflare/Namecheap/etc.
- Verify the A record exists:
  - Type: A
  - Name: panel
  - Content: [Your Server IP]

**3. Wait for Propagation:**
- Cloudflare: 5-10 minutes
- Other providers: Up to 48 hours

**4. Clear DNS Cache:**
```bash
# On your computer
sudo systemd-resolve --flush-caches  # Linux
ipconfig /flushdns                    # Windows
```

**5. Test from Different DNS:**
```bash
dig @8.8.8.8 panel.yourdomain.com  # Google DNS
dig @1.1.1.1 panel.yourdomain.com  # Cloudflare DNS
```

Would you like me to help you verify your DNS setup step by step?
```

#### Example 3: Writing a Script

**You:**
```
Can you write me a script to automatically backup my Pterodactyl database every day?
```

**AI:**
```
Absolutely! Here's a complete backup script with daily automation:

**1. Create the backup script:**
```bash
sudo nano /opt/pterodactyl-backup.sh
```

**2. Add this content:**
```bash
#!/bin/bash

# Pterodactyl Database Backup Script
BACKUP_DIR="/var/backups/pterodactyl"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS="your_database_password"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > $BACKUP_DIR/panel_$DATE.sql.gz

# Keep only last 7 days of backups
find $BACKUP_DIR -name "panel_*.sql.gz" -mtime +7 -delete

echo "Backup completed: panel_$DATE.sql.gz"
```

**3. Make it executable:**
```bash
sudo chmod +x /opt/pterodactyl-backup.sh
```

**4. Test it:**
```bash
sudo /opt/pterodactyl-backup.sh
```

**5. Set up daily cron job:**
```bash
sudo crontab -e
```

Add this line (runs at 2 AM daily):
```
0 2 * * * /opt/pterodactyl-backup.sh >> /var/log/pterodactyl-backup.log 2>&1
```

**Important:** Replace `your_database_password` with your actual database password!

Would you like me to explain any part of this script?
```

#### Example 4: Installation Help

**You:**
```
I'm about to install Pterodactyl Panel. What should I know before starting?
```

**AI:**
```
Great! Here's what you need to know before installing the Panel:

**Prerequisites:**
✓ Ubuntu 20.04+ or Debian 11+
✓ At least 2GB RAM (4GB recommended)
✓ 10GB+ free disk space
✓ Root access to your server
✓ A domain name (e.g., panel.yourdomain.com)

**What Will Be Installed:**
1. PHP 8.1 and extensions
2. MySQL/MariaDB database
3. Redis cache server
4. Nginx web server
5. Composer (PHP package manager)
6. SSL certificate (via Let's Encrypt)

**Installation Time:** ~10-15 minutes

**You'll Need:**
- Your domain name
- Email address (for SSL certificate)
- Admin account details (email, username, password)

**After Installation:**
- Panel will be accessible at https://panel.yourdomain.com
- You can create servers, users, and manage everything
- Next step: Install Wings on the same or different server

**Common Issues to Avoid:**
❌ Don't use the root domain (use panel.yourdomain.com, not yourdomain.com)
❌ Make sure DNS is set up BEFORE installation
❌ Don't skip the SSL certificate step

Ready to start? I can guide you through each step!
```

### Tips for Using the AI

#### Be Specific
❌ **Bad:** "It's not working"  
✅ **Good:** "I'm getting error 'Connection refused' when trying to access panel.example.com"

#### Provide Context
❌ **Bad:** "How do I fix this?"  
✅ **Good:** "I'm installing Wings and getting this error: [paste error]. I'm on Ubuntu 22.04"

#### Ask Follow-up Questions
The AI remembers your conversation, so you can ask:
- "Can you explain that in simpler terms?"
- "What does that command do?"
- "Is there an easier way?"

#### Request Examples
- "Can you show me an example?"
- "What would that look like for my domain?"
- "Can you write a script for that?"

## AI Model Comparison

### Llama 3.2 (Recommended)
- **Size:** 2GB
- **Speed:** Very Fast
- **Best for:** General questions, explanations, troubleshooting
- **Pros:** Quick responses, good balance
- **Cons:** May struggle with very complex code

### Mistral
- **Size:** 4GB
- **Speed:** Fast
- **Best for:** Detailed explanations, complex problems
- **Pros:** Very capable, good reasoning
- **Cons:** Larger download, more RAM needed

### Phi-3
- **Size:** 2GB
- **Speed:** Very Fast
- **Best for:** Quick answers, low-resource servers
- **Pros:** Smallest, efficient
- **Cons:** Less detailed responses

### CodeLlama
- **Size:** 4GB
- **Speed:** Medium
- **Best for:** Writing scripts, debugging code
- **Pros:** Excellent at code generation
- **Cons:** Less conversational

### Gemma 2
- **Size:** 3GB
- **Speed:** Fast
- **Best for:** Balanced performance
- **Pros:** Google's model, well-rounded
- **Cons:** Middle ground (not specialized)

## Switching Models Later

You can change models anytime:

```bash
# List available models
ollama list

# Pull a new model
ollama pull codellama

# Remove old model
ollama rm llama3.2
```

Then refresh Open WebUI and select the new model from the dropdown.

## Advanced Features

### Custom System Prompts

You can customize how the AI behaves:

1. Go to Settings → Personalization
2. Edit "System Prompt"
3. Add specific instructions:
   ```
   You are an expert in Pterodactyl and game server hosting.
   Always provide commands for Ubuntu 22.04.
   Include security best practices in your answers.
   ```

### Document Upload

Upload documentation for the AI to reference:

1. Click the paperclip icon
2. Upload files (PDFs, text files, etc.)
3. Ask questions about the content

### Code Execution

Some models can execute code:

1. Enable "Code Interpreter" in settings
2. Ask the AI to run commands
3. See real-time output

### API Access

Use the AI from command line:

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "How do I restart Pterodactyl Panel?"
}'
```

## Troubleshooting

### AI Not Responding

**Check Ollama Status:**
```bash
sudo systemctl status ollama
```

**Restart Ollama:**
```bash
sudo systemctl restart ollama
```

### Open WebUI Not Loading

**Check Docker Container:**
```bash
docker ps | grep open-webui
```

**Restart Container:**
```bash
docker restart open-webui
```

**View Logs:**
```bash
docker logs open-webui
```

### Model Download Failed

**Check Disk Space:**
```bash
df -h
```

**Retry Download:**
```bash
ollama pull llama3.2
```

### Slow Responses

**Check RAM Usage:**
```bash
free -h
```

**Switch to Smaller Model:**
```bash
ollama pull phi3
```

## Resource Requirements

### Minimum
- **RAM:** 4GB (for 2GB models)
- **Disk:** 10GB free
- **CPU:** 2 cores

### Recommended
- **RAM:** 8GB (for 4GB models)
- **Disk:** 20GB free
- **CPU:** 4 cores

### Optimal
- **RAM:** 16GB (multiple models)
- **Disk:** 50GB free
- **CPU:** 8 cores
- **GPU:** NVIDIA GPU (10x faster)

## Security Considerations

### Access Control

**Restrict to Localhost:**
```bash
# Only accessible from server
docker run -p 127.0.0.1:3000:8080 ...
```

**Use Authentication:**
- Always set a strong admin password
- Enable 2FA in Open WebUI settings

**Use HTTPS:**
- Always use SSL certificates
- Never expose HTTP publicly

### Data Privacy

- ✅ **All data stays on your server** - Nothing sent to external APIs
- ✅ **No internet required** - AI runs completely offline
- ✅ **Your conversations are private** - Not shared with anyone

### Firewall Rules

```bash
# Allow only from specific IP
sudo ufw allow from YOUR_IP to any port 3000

# Or use Cloudflare Tunnel (recommended)
# No ports need to be opened!
```

## Cost

### Completely Free!
- ✅ Ollama: Free and open source
- ✅ Open WebUI: Free and open source
- ✅ AI Models: Free to download and use
- ✅ No API costs
- ✅ No subscriptions
- ✅ No usage limits

### Only Costs
- Server resources (RAM, disk, CPU)
- Domain name (optional, ~$10/year)
- Electricity (minimal)

## Comparison with Other AI Assistants

| Feature | AI-Assisted Install | ChatGPT | Claude | GitHub Copilot |
|---------|---------------------|---------|--------|----------------|
| **Cost** | Free | $20/month | $20/month | $10/month |
| **Privacy** | 100% Private | Data sent to OpenAI | Data sent to Anthropic | Data sent to GitHub |
| **Offline** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Customizable** | ✅ Yes | ❌ No | ❌ No | ❌ Limited |
| **Installation Help** | ✅ Pre-configured | ⚠️ Generic | ⚠️ Generic | ❌ Code only |
| **No Limits** | ✅ Unlimited | ❌ Rate limited | ❌ Rate limited | ❌ Rate limited |

## Next Steps

After AI installation:

1. **Test the AI** - Ask a few questions to get comfortable
2. **Continue Installation** - Install Panel, Wings, etc.
3. **Keep AI Open** - Have it in another tab while installing
4. **Ask for Help** - Whenever you're stuck or confused
5. **Learn** - Use it as a learning tool, not just for answers

## FAQ

**Q: Can I skip the AI and install normally?**  
A: Yes! Just choose any other option from the main menu.

**Q: Will the AI slow down my server?**  
A: Only while actively using it. Ollama uses ~2-4GB RAM when running.

**Q: Can I uninstall it later?**  
A: Yes! `docker rm -f open-webui && sudo apt remove ollama`

**Q: Does it work offline?**  
A: Yes! Once installed, no internet needed.

**Q: Can I use it for other things?**  
A: Absolutely! It's a general-purpose AI assistant.

**Q: Is my data safe?**  
A: Yes! Everything runs locally, nothing is sent externally.

---

**Ready to try AI-Assisted Installation?**

```bash
curl -sSL https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/install-interactive.sh | sudo bash
```

Choose option `0 - 🤖 AI Assistant First` and let the AI guide you! 🚀
