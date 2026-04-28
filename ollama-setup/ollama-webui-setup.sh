#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/tmp/ollama-setup-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should NOT be run as root. Run as a regular user with sudo access."
        exit 1
    fi
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        warn "This script requires sudo access. You may be prompted for your password."
        sudo -v
    fi
}

check_internet() {
    info "Checking internet connectivity..."
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error "No internet connection detected. Please check your network."
        exit 1
    fi
    log "✓ Internet connection verified"
}

check_gpu() {
    info "Checking for NVIDIA GPU..."
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)
        if [ -n "$GPU_INFO" ]; then
            log "✓ GPU detected: $GPU_INFO"
            return 0
        fi
    fi
    warn "No NVIDIA GPU detected. Ollama will run on CPU (slower)."
    return 1
}

echo ""
echo "=========================================="
echo "  Ollama + Open WebUI + Cloudflared Setup"
echo "=========================================="
echo ""
echo "This script will install and configure:"
echo "  • Ollama (AI model server)"
echo "  • Open WebUI (web interface)"
echo "  • Cloudflared (secure tunnel)"
echo ""
echo "Log file: $LOG_FILE"
echo ""

check_root
check_sudo
check_internet
HAS_GPU=$(check_gpu && echo "true" || echo "false")

DOMAIN=""
SUBDOMAIN="chat"
WEBUI_SUBDOMAIN="ui"
OLLAMA_PORT=11434
WEBUI_PORT=3000

echo ""
echo "=== Step 1: Configuration ==="
read -p "Enter your domain (e.g., cloudmc.online): " DOMAIN

if [ -z "$DOMAIN" ]; then
    error "Domain is required!"
    exit 1
fi

read -p "Enter subdomain for Ollama API (default: chat): " SUBDOMAIN_INPUT
SUBDOMAIN=${SUBDOMAIN_INPUT:-chat}

read -p "Enter subdomain for Open WebUI (default: ui): " WEBUI_SUBDOMAIN_INPUT
WEBUI_SUBDOMAIN=${WEBUI_SUBDOMAIN_INPUT:-ui}

read -p "Enter Open WebUI port (default: 3000): " WEBUI_PORT_INPUT
WEBUI_PORT=${WEBUI_PORT_INPUT:-3000}

OLLAMA_URL="${SUBDOMAIN}.${DOMAIN}"
WEBUI_URL="${WEBUI_SUBDOMAIN}.${DOMAIN}"

echo ""
echo "Configuration Summary:"
echo "  - Ollama API:    https://${OLLAMA_URL}"
echo "  - Open WebUI:    https://${WEBUI_URL}"
echo "  - Local WebUI:   http://localhost:${WEBUI_PORT}"
echo "  - GPU Support:   ${HAS_GPU}"
echo ""
read -p "Continue with this configuration? [Y/n]: " CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi
echo ""

echo "=== Step 2: Installing Ollama ==="
if command -v ollama &> /dev/null; then
    echo "Ollama already installed"
else
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

echo ""
echo "=== Step 3: Configuring Ollama Service ==="
sudo mkdir -p /etc/systemd/system/ollama.service.d/

cat <<EOF | sudo tee /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0:${OLLAMA_PORT}"
Environment="OLLAMA_ORIGINS=*"
Environment="CUDA_VISIBLE_DEVICES=0"
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama

echo "Waiting for Ollama to start..."
sleep 5

echo ""
echo "=== Step 4: Verifying Ollama ==="
if curl -s http://localhost:${OLLAMA_PORT}/api/tags > /dev/null; then
    echo "✓ Ollama is running"
else
    echo "✗ Ollama failed to start"
    exit 1
fi

echo ""
echo "=== Step 5: Installing Cloudflared ==="
if command -v cloudflared &> /dev/null; then
    echo "Cloudflared already installed"
else
    echo "Installing Cloudflared..."
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
fi

echo ""
echo "=== Step 6: Cloudflare Authentication ==="
if [ ! -f ~/.cloudflared/cert.pem ]; then
    echo "Please authenticate with Cloudflare..."
    cloudflared tunnel login
else
    echo "Already authenticated with Cloudflare"
fi

echo ""
echo "=== Step 7: Creating Cloudflare Tunnel ==="
TUNNEL_NAME="ollama-$(date +%s)"
TUNNEL_ID=$(cloudflared tunnel list 2>/dev/null | grep ollama | head -1 | awk '{print $1}')

if [ -z "$TUNNEL_ID" ]; then
    echo "Creating new tunnel: ${TUNNEL_NAME}"
    cloudflared tunnel create ${TUNNEL_NAME}
    TUNNEL_ID=$(cloudflared tunnel list | grep ${TUNNEL_NAME} | awk '{print $1}')
else
    echo "Using existing tunnel: ${TUNNEL_ID}"
fi

echo "Tunnel ID: ${TUNNEL_ID}"

echo ""
echo "=== Step 8: Configuring Tunnel ==="
mkdir -p ~/.cloudflared

cat <<EOF > ~/.cloudflared/config.yml
tunnel: ${TUNNEL_ID}
credentials-file: /home/$(whoami)/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${OLLAMA_URL}
    service: http://localhost:${OLLAMA_PORT}
    originRequest:
      httpHostHeader: "localhost:${OLLAMA_PORT}"
      noTLSVerify: true
      disableChunkedEncoding: false
  - service: http_status:404
EOF

echo "✓ Tunnel config created at ~/.cloudflared/config.yml"

echo ""
echo "=== Step 9: Setting up DNS ==="
echo "Creating DNS record for ${OLLAMA_URL}..."
cloudflared tunnel route dns ${TUNNEL_ID} ${OLLAMA_URL}

echo ""
echo "=== Step 10: Installing Tunnel as Service ==="
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl restart cloudflared

echo "Waiting for tunnel to start..."
sleep 5

echo ""
echo "=== Step 11: Installing Docker (if needed) ==="
if command -v docker &> /dev/null; then
    log "✓ Docker already installed"
else
    info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $(whoami)
    rm get-docker.sh
    log "✓ Docker installed"
    warn "You may need to log out and back in for Docker permissions to take effect"
    
    read -p "Continue anyway? [Y/n]: " CONTINUE_DOCKER
    if [[ "$CONTINUE_DOCKER" =~ ^[Nn]$ ]]; then
        echo "Please log out and run this script again."
        exit 0
    fi
fi

echo ""
echo "=== Step 12: Deploying Open WebUI ==="
info "Stopping any existing Open WebUI container..."
docker stop open-webui 2>/dev/null || true
docker rm open-webui 2>/dev/null || true

SERVER_IP=$(hostname -I | awk '{print $1}')

info "Starting Open WebUI container..."
docker run -d \
  --name open-webui \
  -p ${WEBUI_PORT}:8080 \
  -e OLLAMA_BASE_URL=http://${SERVER_IP}:${OLLAMA_PORT} \
  -e WEBUI_AUTH=true \
  -e ENABLE_SIGNUP=true \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

log "✓ Open WebUI container started"
info "Waiting for Open WebUI to initialize..."
sleep 15

if docker ps | grep -q open-webui; then
    log "✓ Open WebUI is running"
else
    error "Open WebUI failed to start. Check logs with: docker logs open-webui"
    exit 1
fi

echo ""
echo "=== Step 13: Configuring WebUI Cloudflare Tunnel ==="
info "Adding WebUI route to tunnel..."

cat <<EOF > ~/.cloudflared/config.yml
tunnel: ${TUNNEL_ID}
credentials-file: /home/$(whoami)/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: ${OLLAMA_URL}
    service: http://localhost:${OLLAMA_PORT}
    originRequest:
      httpHostHeader: "localhost:${OLLAMA_PORT}"
      noTLSVerify: true
      disableChunkedEncoding: false
  - hostname: ${WEBUI_URL}
    service: http://localhost:${WEBUI_PORT}
  - service: http_status:404
EOF

log "✓ Updated tunnel config with WebUI route"

info "Creating DNS record for ${WEBUI_URL}..."
cloudflared tunnel route dns ${TUNNEL_ID} ${WEBUI_URL} 2>/dev/null || warn "DNS route may already exist"

info "Restarting Cloudflared to apply changes..."
sudo systemctl restart cloudflared
sleep 5

log "✓ WebUI tunnel configured"

echo ""
echo "=== Step 14: Model Selection ==="
echo "Choose models to install (you can install more later):"
echo ""
echo "Recommended models for your setup:"
if [ "$HAS_GPU" = "true" ]; then
    echo "  1) qwen2.5:7b       - Fast & intelligent (4.7GB) [RECOMMENDED]"
    echo "  2) gemma2:9b        - High quality (5.4GB)"
    echo "  3) deepseek-coder:6.7b - Excellent for coding (3.8GB)"
    echo "  4) llama3.2:3b      - Small & fast (2GB)"
    echo "  5) Custom model name"
    echo "  6) Skip for now"
else
    echo "  1) qwen2.5:3b       - Fast & intelligent (2GB) [RECOMMENDED for CPU]"
    echo "  2) llama3.2:3b      - Small & fast (2GB)"
    echo "  3) phi3:mini        - Microsoft's small model (2.3GB)"
    echo "  4) Custom model name"
    echo "  5) Skip for now"
fi
echo ""

read -p "Select option [1-6]: " MODEL_CHOICE

case $MODEL_CHOICE in
    1)
        if [ "$HAS_GPU" = "true" ]; then
            MODEL="qwen2.5:7b"
        else
            MODEL="qwen2.5:3b"
        fi
        ;;
    2)
        if [ "$HAS_GPU" = "true" ]; then
            MODEL="gemma2:9b"
        else
            MODEL="llama3.2:3b"
        fi
        ;;
    3)
        if [ "$HAS_GPU" = "true" ]; then
            MODEL="deepseek-coder:6.7b"
        else
            MODEL="phi3:mini"
        fi
        ;;
    4)
        if [ "$HAS_GPU" = "true" ]; then
            MODEL="llama3.2:3b"
        else
            read -p "Enter model name (e.g., llama3.2:1b): " MODEL
        fi
        ;;
    5)
        if [ "$HAS_GPU" = "true" ]; then
            read -p "Enter model name (e.g., mistral:7b): " MODEL
        else
            info "Skipping model installation"
            MODEL=""
        fi
        ;;
    6|*)
        info "Skipping model installation"
        MODEL=""
        ;;
esac

if [ -n "$MODEL" ]; then
    info "Pulling model: $MODEL (this may take several minutes)..."
    if ollama pull "$MODEL"; then
        log "✓ Model $MODEL installed successfully"
    else
        error "Failed to pull model $MODEL"
    fi
fi

echo ""
log "Testing connectivity..."
sleep 3

OLLAMA_TEST=$(curl -s http://localhost:${OLLAMA_PORT}/api/tags 2>/dev/null)
if [ -n "$OLLAMA_TEST" ]; then
    log "✓ Ollama API is responding"
else
    warn "Ollama API test failed - may need a moment to start"
fi

WEBUI_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${WEBUI_PORT} 2>/dev/null)
if [ "$WEBUI_TEST" = "200" ] || [ "$WEBUI_TEST" = "302" ]; then
    log "✓ Open WebUI is responding"
else
    warn "Open WebUI test failed - may need a moment to start"
fi

echo ""
echo "=========================================="
echo "✓✓✓ Setup Complete! ✓✓✓"
echo "=========================================="
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo "  🌐 Ollama API:     https://${OLLAMA_URL}"
echo "  🌐 Open WebUI:     https://${WEBUI_URL}"
echo "  🏠 Local WebUI:    http://${SERVER_IP}:${WEBUI_PORT}"
echo "  🏠 Local API:      http://localhost:${OLLAMA_PORT}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Open https://${WEBUI_URL} in your browser"
echo "  2. Create your admin account (first user becomes admin)"
echo "  3. Start chatting with your AI models!"
echo ""
echo -e "${YELLOW}Useful Commands:${NC}"
echo "  📋 List models:          ollama list"
echo "  ⬇️  Pull new model:       ollama pull <model-name>"
echo "  🗑️  Remove model:         ollama rm <model-name>"
echo "  ✅ Check Ollama:         sudo systemctl status ollama"
echo "  ✅ Check tunnel:         sudo systemctl status cloudflared"
echo "  📝 View WebUI logs:      docker logs -f open-webui"
echo "  🔄 Restart Ollama:       sudo systemctl restart ollama"
echo "  🔄 Restart WebUI:        docker restart open-webui"
echo ""
echo -e "${BLUE}Configuration Files:${NC}"
echo "  - Ollama service:    /etc/systemd/system/ollama.service.d/override.conf"
echo "  - Cloudflared:       ~/.cloudflared/config.yml"
echo "  - Setup log:         $LOG_FILE"
echo ""
echo -e "${GREEN}Popular Models to Try:${NC}"
echo "  ollama pull qwen2.5:7b          # Fast & intelligent"
echo "  ollama pull gemma2:9b           # High quality"
echo "  ollama pull deepseek-coder:6.7b # Great for coding"
echo "  ollama pull llama3.2:3b         # Small & fast"
echo "  ollama pull mistral:7b          # Very popular"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  If models don't appear in WebUI:"
echo "    1. docker restart open-webui"
echo "    2. Hard refresh browser (Ctrl+Shift+R)"
echo "    3. Check connection in Settings → Admin → Connections"
echo ""
echo "  If tunnel doesn't work:"
echo "    1. sudo systemctl status cloudflared"
echo "    2. Check DNS propagation (may take a few minutes)"
echo "    3. Verify in Cloudflare dashboard"
echo ""
echo -e "${GREEN}Setup completed successfully!${NC}"
echo "Log saved to: $LOG_FILE"
echo ""
