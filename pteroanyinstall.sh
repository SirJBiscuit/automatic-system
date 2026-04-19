#!/bin/bash

set -e

VERSION="2.0.0"
SCRIPT_NAME="automatic-system"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PANEL_VERSION="1.11.5"
WINGS_VERSION="1.11.5"

CONFIG_DIR="/etc/automatic-system"
CONFIG_FILE="$CONFIG_DIR/config.conf"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
    else
        log_error "Cannot detect OS"
        exit 1
    fi
    
    log_info "Detected OS: $OS $OS_VER"
}

prompt_yes_no() {
    local prompt="$1"
    local response
    
    while true; do
        read -p "$prompt (y/n): " response
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt: " response
        echo "$response"
    fi
}

prompt_with_explanation() {
    local prompt="$1"
    local explanation="$2"
    local default="$3"
    
    echo ""
    log_info "$explanation"
    prompt_input "$prompt" "$default"
}

detect_network_interfaces() {
    log_info "Detecting network interfaces..."
    
    echo ""
    echo "Available Network Interfaces:"
    echo "============================="
    
    local interfaces=()
    local count=1
    
    # Get all interfaces except loopback, docker, and virtual interfaces
    for iface in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}'); do
        # Skip loopback, docker, bridge, and veth interfaces (veth includes @)
        if [[ "$iface" == "lo" ]] || [[ "$iface" == docker* ]] || [[ "$iface" == br-* ]] || [[ "$iface" == veth* ]]; then
            continue
        fi
        
        local ip_addr=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' 2>/dev/null | head -1)
        local status=$(ip link show "$iface" 2>/dev/null | grep -oP '(?<=state )\w+' 2>/dev/null)
        local type="Unknown"
        
        if [[ $iface == eth* ]] || [[ $iface == ens* ]] || [[ $iface == enp* ]]; then
            type="Ethernet"
        elif [[ $iface == wlan* ]] || [[ $iface == wlp* ]]; then
            type="WiFi"
        fi
        
        echo "$count) $iface - $type - Status: $status - IP: ${ip_addr:-Not assigned}"
        interfaces+=("$iface")
        ((count++))
    done
    
    echo ""
}

get_public_ip() {
    local public_ip=""
    
    log_info "Detecting public IP address..."
    
    public_ip=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null)
    
    if [ -z "$public_ip" ]; then
        log_warning "Could not auto-detect public IP"
        return 1
    fi
    
    log_success "Detected public IP: $public_ip"
    echo "$public_ip"
}

configure_static_ip() {
    local interface="$1"
    local ip_address="$2"
    local gateway="$3"
    local dns="$4"
    
    log_info "Configuring static IP for $interface..."
    
    case $OS in
        ubuntu|debian)
            if command -v netplan &> /dev/null; then
                cat > /etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $interface:
      dhcp4: no
      addresses:
        - $ip_address/24
      gateway4: $gateway
      nameservers:
        addresses: [$dns, 8.8.8.8]
EOF
                netplan apply
            else
                cat > /etc/network/interfaces.d/$interface <<EOF
auto $interface
iface $interface inet static
    address $ip_address
    netmask 255.255.255.0
    gateway $gateway
    dns-nameservers $dns 8.8.8.8
EOF
                systemctl restart networking
            fi
            ;;
        centos|rhel|rocky|almalinux)
            cat > /etc/sysconfig/network-scripts/ifcfg-$interface <<EOF
TYPE=Ethernet
BOOTPROTO=static
NAME=$interface
DEVICE=$interface
ONBOOT=yes
IPADDR=$ip_address
NETMASK=255.255.255.0
GATEWAY=$gateway
DNS1=$dns
DNS2=8.8.8.8
EOF
            systemctl restart network
            ;;
    esac
    
    log_success "Static IP configured for $interface"
}

show_network_diagram() {
    cat <<'EOF'

╔══════════════════════════════════════════════════════════════════╗
║                  PTERO NETWORK ARCHITECTURE                      ║
╚══════════════════════════════════════════════════════════════════╝

                      ┌─────────────┐
                      │  INTERNET   │
                      └──────┬──────┘
                             │
                      ┌──────▼──────┐
                      │ CLOUDFLARE  │
                      └──────┬──────┘
                             │
                ┌────────────┴────────────┐
                │                         │
         ┌──────▼──────┐          ┌──────▼──────┐
         │    PANEL    │          │    WINGS    │
         │ :80 / :443  │          │ :8080/:2022 │
         └──────┬──────┘          └──────┬──────┘
                │                         │
       ┌────────┼────────┐       ┌────────┼────────┐
       │        │        │       │        │        │
   ┌───▼──┐ ┌──▼──┐ ┌───▼──┐ ┌──▼──┐ ┌───▼───┐ ┌──▼──┐
   │Nginx │ │MySQL│ │Redis │ │ GPU │ │Docker │ │SFTP │
   └──────┘ └─────┘ └──────┘ └─────┘ └───────┘ └─────┘

╔══════════════════════════════════════════════════════════════════╗
║  PORTS: Panel (80,443) | Wings (8080,2022,25565+)               ║
╚══════════════════════════════════════════════════════════════════╝

EOF
}

show_installation_flow() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                      INSTALLATION FLOW DIAGRAM                         ║
╚════════════════════════════════════════════════════════════════════════╝

    ┌─────────────────┐
    │  START INSTALL  │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ Detect OS/HW    │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ Network Setup   │
    │ - WiFi/Ethernet │
    │ - Static IP     │
    │ - Public IP     │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ DNS Verification│
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ Install Deps    │
    │ - Docker        │
    │ - MariaDB       │
    │ - Nginx         │
    │ - PHP/Redis     │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ Install Panel   │
    │ and/or Wings    │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ SSL Certificates│
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ Optional:       │
    │ - GPU Support   │
    │ - Billing       │
    │ - Monitoring    │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │ Health Check    │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │   COMPLETE!     │
    └─────────────────┘

EOF
}

check_dns() {
    local domain="$1"
    local expected_ip="$2"
    
    log_info "Checking DNS for $domain..."
    
    local resolved_ip=$(dig +short "$domain" | tail -n1)
    
    if [ -z "$resolved_ip" ]; then
        log_warning "DNS record for $domain not found"
        return 1
    fi
    
    if [ "$resolved_ip" == "$expected_ip" ]; then
        log_success "DNS correctly points to $expected_ip"
        return 0
    else
        log_warning "DNS points to $resolved_ip but expected $expected_ip"
        return 1
    fi
}

install_dependencies() {
    log_info "Installing system dependencies..."
    
    case $OS in
        ubuntu|debian)
            apt update -y
            apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release wget git unzip tar make gcc g++ python3 dnsutils
            ;;
        centos|rhel|rocky|almalinux)
            yum update -y
            yum install -y curl wget git unzip tar make gcc gcc-c++ python3 bind-utils
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    log_success "System dependencies installed"
}

install_docker() {
    if command -v docker &> /dev/null; then
        log_info "Docker is already installed"
        docker --version
        return 0
    fi
    
    log_info "Installing Docker..."
    
    case $OS in
        ubuntu|debian)
            curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt update -y
            apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
    esac
    
    systemctl enable --now docker
    log_success "Docker installed and started"
}

configure_gpu_support() {
    log_info "Configuring NVIDIA GPU support for Docker..."
    
    if ! lspci | grep -i nvidia &> /dev/null; then
        log_warning "No NVIDIA GPU detected"
        return 1
    fi
    
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
    
    apt update -y
    apt install -y nvidia-docker2
    
    systemctl restart docker
    
    log_success "NVIDIA GPU support configured"
}

install_mariadb() {
    if command -v mysql &> /dev/null; then
        log_info "MariaDB/MySQL is already installed"
        mysql --version
        return 0
    fi
    
    log_info "Installing MariaDB..."
    
    case $OS in
        ubuntu|debian)
            apt install -y mariadb-server mariadb-client
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y mariadb-server mariadb
            ;;
    esac
    
    systemctl enable --now mariadb
    log_success "MariaDB installed and started"
}

install_php() {
    log_info "Installing PHP and required extensions..."
    
    case $OS in
        ubuntu|debian)
            add-apt-repository -y ppa:ondrej/php
            apt update -y
            apt install -y php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip}
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y epel-release
            yum install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
            yum module reset php -y
            yum module enable php:remi-8.1 -y
            yum install -y php php-{common,fpm,cli,json,mysqlnd,mcrypt,gd,mbstring,pdo,zip,bcmath,dom,opcache}
            ;;
    esac
    
    log_success "PHP installed"
}

install_composer() {
    if command -v composer &> /dev/null; then
        log_info "Composer is already installed"
        return 0
    fi
    
    log_info "Installing Composer..."
    
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    
    log_success "Composer installed"
}

install_nginx() {
    if command -v nginx &> /dev/null; then
        log_info "Nginx is already installed"
        return 0
    fi
    
    log_info "Installing Nginx..."
    
    case $OS in
        ubuntu|debian)
            apt install -y nginx
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y nginx
            ;;
    esac
    
    systemctl enable nginx
    log_success "Nginx installed"
}

install_certbot() {
    if command -v certbot &> /dev/null; then
        log_info "Certbot is already installed"
        return 0
    fi
    
    log_info "Installing Certbot..."
    
    case $OS in
        ubuntu|debian)
            apt install -y certbot python3-certbot-nginx
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y certbot python3-certbot-nginx
            ;;
    esac
    
    log_success "Certbot installed"
}

setup_database() {
    local db_name="$1"
    local db_user="$2"
    local db_pass="$3"
    
    log_info "Setting up database: $db_name"
    
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $db_name;
CREATE USER IF NOT EXISTS '$db_user'@'127.0.0.1' IDENTIFIED BY '$db_pass';
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF
    
    log_success "Database $db_name created"
}

setup_network_wizard() {
    log_info "Network Interface Selection"
    echo ""
    log_info "Select your primary network interface for stable connectivity."
    echo ""
    
    # Detect interfaces and display them
    detect_network_interfaces
    
    # Get the interface list for selection
    local interfaces=()
    for iface in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}'); do
        if [[ "$iface" == "lo" ]] || [[ "$iface" == docker* ]] || [[ "$iface" == br-* ]] || [[ "$iface" == veth* ]]; then
            continue
        fi
        interfaces+=("$iface")
    done
    
    echo ""
    read -p "Select network interface number: " iface_num
    
    if [ "$iface_num" -lt 1 ] || [ "$iface_num" -gt "${#interfaces[@]}" ]; then
        log_error "Invalid selection"
        return 1
    fi
    
    SELECTED_INTERFACE="${interfaces[$((iface_num-1))]}"
    log_success "Selected interface: $SELECTED_INTERFACE"
    
    echo ""
    log_info "EXPLANATION: We'll now detect your public IP address."
    log_info "This is the IP address that the internet sees when connecting to your server."
    
    AUTO_PUBLIC_IP=$(get_public_ip)
    
    if [ -n "$AUTO_PUBLIC_IP" ]; then
        PUBLIC_IP=$(prompt_with_explanation \
            "Confirm or enter your public IP" \
            "Auto-detected: $AUTO_PUBLIC_IP. Press Enter to use this, or type a different IP." \
            "$AUTO_PUBLIC_IP")
    else
        PUBLIC_IP=$(prompt_with_explanation \
            "Enter your public IP address" \
            "Could not auto-detect. Please enter your public IP manually." \
            "")
    fi
    
    echo ""
    if prompt_yes_no "Do you want to configure a static IP to prevent IP changes on reboot?"; then
        log_info "EXPLANATION: A static IP ensures your server always uses the same local IP address."
        log_info "This is important for network stability and prevents connectivity issues after reboots."
        
        CURRENT_IP=$(ip -4 addr show $SELECTED_INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
        GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
        
        STATIC_IP=$(prompt_input "Enter static IP for $SELECTED_INTERFACE" "$CURRENT_IP")
        GATEWAY_IP=$(prompt_input "Enter gateway IP" "$GATEWAY")
        DNS_IP=$(prompt_input "Enter DNS server" "8.8.8.8")
        
        configure_static_ip "$SELECTED_INTERFACE" "$STATIC_IP" "$GATEWAY_IP" "$DNS_IP"
        
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_FILE" <<EOF
INTERFACE=$SELECTED_INTERFACE
STATIC_IP=$STATIC_IP
PUBLIC_IP=$PUBLIC_IP
GATEWAY=$GATEWAY_IP
DNS=$DNS_IP
CONFIGURED_DATE=$(date)
EOF
        log_success "Network configuration saved to $CONFIG_FILE"
    fi
    
    echo ""
    log_success "Network configuration complete!"
    echo ""
}

install_billing_system() {
    log_info "Setting up Billing System Integration..."
    echo ""
    log_info "EXPLANATION: A billing system allows you to charge customers for game servers."
    log_info "We offer an automated billing setup with PayPal integration."
    echo ""
    
    echo "Available Billing Options:"
    echo "1) Automatic Billing Setup (PayPal + Custom Portal) - RECOMMENDED"
    echo "2) WHMCS Module (Requires existing WHMCS)"
    echo "3) Blesta Module (Requires existing Blesta)"
    echo "4) Skip billing setup"
    echo ""
    
    read -p "Select billing option [1-4]: " billing_choice
    
    case $billing_choice in
        1)
            log_info "Starting Automatic Billing Setup..."
            log_info "EXPLANATION: This will create a complete billing portal with:"
            log_info "  - PayPal payment integration"
            log_info "  - Automated server provisioning"
            log_info "  - Customer management"
            log_info "  - Invoice generation"
            log_info "  - Game server plan configuration"
            echo ""
            
            if [ ! -f "$(dirname $0)/billing-setup.sh" ]; then
                log_info "Downloading billing setup script..."
                curl -sSL -o /tmp/billing-setup.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/billing-setup.sh
                chmod +x /tmp/billing-setup.sh
                /tmp/billing-setup.sh
            else
                chmod +x "$(dirname $0)/billing-setup.sh"
                "$(dirname $0)/billing-setup.sh"
            fi
            
            log_success "Automatic billing system installed!"
            ;;
        2)
            log_info "Installing WHMCS Pterodactyl Module..."
            log_info "EXPLANATION: This module connects your existing WHMCS to Pterodactyl."
            
            WHMCS_URL=$(prompt_input "Enter your WHMCS URL (e.g., https://billing.example.com)")
            WHMCS_API_ID=$(prompt_input "Enter WHMCS API Identifier")
            WHMCS_API_SECRET=$(prompt_input "Enter WHMCS API Secret")
            
            mkdir -p /var/www/whmcs-pterodactyl
            cd /var/www/whmcs-pterodactyl
            
            git clone https://github.com/pterodactyl/whmcs.git .
            
            cat > /var/www/whmcs-pterodactyl/config.php <<EOF
<?php
return [
    'panel_url' => 'https://$PANEL_FQDN',
    'whmcs_url' => '$WHMCS_URL',
    'api_key' => '$WHMCS_API_ID',
    'api_secret' => '$WHMCS_API_SECRET',
];
EOF
            
            log_success "WHMCS module installed. Configure in WHMCS admin panel."
            log_info "Module location: /var/www/whmcs-pterodactyl"
            ;;
        3)
            log_info "Installing Blesta Pterodactyl Module..."
            log_info "Visit: https://github.com/pterodactyl/blesta-module for manual installation"
            ;;
        4)
            log_info "Skipping billing system setup"
            ;;
        *)
            log_warning "Invalid selection, skipping billing setup"
            ;;
    esac
}

setup_reboot_protection() {
    log_info "Configuring Reboot Protection..."
    echo ""
    log_info "EXPLANATION: Reboot protection ensures all services start automatically after a server restart."
    log_info "This includes Docker containers, databases, web servers, and Pterodactyl services."
    echo ""
    
    cat > /etc/systemd/system/pterodactyl-startup.service <<EOF
[Unit]
Description=Pterodactyl Startup Service
After=network-online.target docker.service mariadb.service nginx.service redis.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/sleep 10
ExecStart=/usr/local/bin/pterodactyl-startup.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    cat > /usr/local/bin/pterodactyl-startup.sh <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/pterodactyl-startup.log"
echo "$(date): Ptero startup initiated" >> $LOG_FILE

if [ -f /etc/automatic-system/config.conf ]; then
    source /etc/automatic-system/config.conf
    echo "$(date): Loaded configuration" >> $LOG_FILE
fi

systemctl is-active --quiet docker || systemctl start docker
echo "$(date): Docker started" >> $LOG_FILE

systemctl is-active --quiet mariadb || systemctl start mariadb
echo "$(date): MariaDB started" >> $LOG_FILE

systemctl is-active --quiet nginx || systemctl start nginx
echo "$(date): Nginx started" >> $LOG_FILE

systemctl is-active --quiet redis-server || systemctl start redis-server || systemctl start redis
echo "$(date): Redis started" >> $LOG_FILE

if systemctl list-unit-files | grep -q wings.service; then
    sleep 5
    systemctl is-active --quiet wings || systemctl start wings
    echo "$(date): Wings started" >> $LOG_FILE
fi

if [ -d /var/www/pterodactyl ]; then
    cd /var/www/pterodactyl
    php artisan queue:restart >> $LOG_FILE 2>&1
    echo "$(date): Panel queue restarted" >> $LOG_FILE
fi

echo "$(date): Ptero startup complete" >> $LOG_FILE
EOF

    chmod +x /usr/local/bin/pterodactyl-startup.sh
    systemctl daemon-reload
    systemctl enable pterodactyl-startup.service
    
    log_success "Reboot protection configured"
    log_info "Services will auto-start on reboot. Logs: /var/log/pterodactyl-startup.log"
}

setup_monitoring() {
    log_info "Setting up Server Monitoring..."
    echo ""
    log_info "EXPLANATION: Monitoring helps you track server performance, resource usage, and uptime."
    log_info "This can alert you to problems before they affect your customers."
    echo ""
    
    if ! prompt_yes_no "Do you want to install monitoring tools?"; then
        return 0
    fi
    
    case $OS in
        ubuntu|debian)
            apt install -y htop iotop nethogs vnstat
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y htop iotop nethogs vnstat
            ;;
    esac
    
    systemctl enable --now vnstat
    
    cat > /usr/local/bin/ptero-monitor <<'EOF'
#!/bin/bash

echo "=== Ptero Server Monitor ==="
echo ""
echo "=== System Resources ==="
free -h
echo ""
df -h | grep -E '^/dev/'
echo ""
echo "=== Service Status ==="
systemctl is-active docker && echo "✓ Docker: Running" || echo "✗ Docker: Stopped"
systemctl is-active mariadb && echo "✓ MariaDB: Running" || echo "✗ MariaDB: Stopped"
systemctl is-active nginx && echo "✓ Nginx: Running" || echo "✗ Nginx: Stopped"
systemctl is-active redis-server && echo "✓ Redis: Running" || systemctl is-active redis && echo "✓ Redis: Running" || echo "✗ Redis: Stopped"
systemctl is-active wings && echo "✓ Wings: Running" || echo "  Wings: Not installed"
echo ""
echo "=== Network Usage ==="
vnstat -d
EOF

    chmod +x /usr/local/bin/ptero-monitor
    
    log_success "Monitoring tools installed"
    log_info "Run 'ptero-monitor' to view server status"
}

setup_automatic_backups() {
    log_info "Setting up Automatic Backups..."
    echo ""
    log_info "EXPLANATION: Automatic backups protect your data by creating regular copies."
    log_info "This includes the Panel database, configuration files, and Wings data."
    echo ""
    
    if ! prompt_yes_no "Do you want to setup automatic backups?"; then
        return 0
    fi
    
    BACKUP_DIR=$(prompt_input "Enter backup directory" "/var/backups/ptero")
    BACKUP_RETENTION=$(prompt_input "How many days to keep backups?" "7")
    
    mkdir -p "$BACKUP_DIR"
    
    cat > /usr/local/bin/pterodactyl-backup.sh <<EOF
#!/bin/bash

BACKUP_DIR="$BACKUP_DIR"
DATE=\$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=$BACKUP_RETENTION

mkdir -p \$BACKUP_DIR

if [ -d /var/www/pterodactyl ]; then
    cd /var/www/pterodactyl
    source .env
    mysqldump -u \$DB_USERNAME -p\$DB_PASSWORD \$DB_DATABASE > \$BACKUP_DIR/panel_db_\$DATE.sql
    tar -czf \$BACKUP_DIR/panel_files_\$DATE.tar.gz /var/www/pterodactyl
    echo "\$(date): Panel backup completed" >> /var/log/pterodactyl-backup.log
fi

if [ -d /etc/pterodactyl ]; then
    tar -czf \$BACKUP_DIR/wings_config_\$DATE.tar.gz /etc/pterodactyl
    echo "\$(date): Wings config backup completed" >> /var/log/pterodactyl-backup.log
fi

find \$BACKUP_DIR -name "*.sql" -mtime +\$RETENTION_DAYS -delete
find \$BACKUP_DIR -name "*.tar.gz" -mtime +\$RETENTION_DAYS -delete

echo "\$(date): Old backups cleaned (retention: \$RETENTION_DAYS days)" >> /var/log/pterodactyl-backup.log
EOF

    chmod +x /usr/local/bin/pterodactyl-backup.sh
    
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/pterodactyl-backup.sh") | crontab -
    
    log_success "Automatic backups configured"
    log_info "Ptero backups run daily at 2 AM, stored in: $BACKUP_DIR"
    log_info "Retention: $BACKUP_RETENTION days"
}

ask_optional_features() {
    log_info "Optional Features Configuration"
    echo ""
    log_info "EXPLANATION: These optional features enhance your Pterodactyl installation."
    log_info "You can add monitoring, backups, and other useful tools."
    echo ""
    
    if prompt_yes_no "Do you want to install server monitoring tools?"; then
        setup_monitoring
    fi
    
    echo ""
    if prompt_yes_no "Do you want to setup automatic backups?"; then
        setup_automatic_backups
    fi
    
    echo ""
    if prompt_yes_no "Do you want to setup a billing system integration?"; then
        install_billing_system
    fi
    
    echo ""
    if prompt_yes_no "Do you want to configure firewall rules automatically?"; then
        setup_firewall
    fi
    
    echo ""
    customize_panel_appearance
}

customize_panel_appearance() {
    log_info "Panel Appearance Customization"
    echo ""
    log_info "EXPLANATION: Customize the look and feel of your Pterodactyl Panel."
    log_info "This includes colors, logos, backgrounds, and styling."
    echo ""
    
    if prompt_yes_no "Do you want to customize your panel's appearance?"; then
        if [ ! -f "$(dirname $0)/panel-customizer.sh" ]; then
            log_info "Downloading panel customizer..."
            curl -sSL -o /tmp/panel-customizer.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/panel-customizer.sh
            chmod +x /tmp/panel-customizer.sh
            /tmp/panel-customizer.sh
        else
            chmod +x "$(dirname $0)/panel-customizer.sh"
            "$(dirname $0)/panel-customizer.sh"
        fi
        log_success "Panel customization complete!"
    else
        log_info "Skipping panel customization"
        log_info "You can customize later by running: ./panel-customizer.sh"
    fi
}

setup_firewall() {
    log_info "Configuring Firewall..."
    echo ""
    log_info "EXPLANATION: Firewall rules protect your server by blocking unauthorized access."
    log_info "We'll open only the necessary ports for Pterodactyl to function."
    echo ""
    
    case $OS in
        ubuntu|debian)
            if ! command -v ufw &> /dev/null; then
                apt install -y ufw
            fi
            
            ufw --force enable
            ufw default deny incoming
            ufw default allow outgoing
            
            ufw allow 22/tcp comment 'SSH'
            ufw allow 80/tcp comment 'HTTP'
            ufw allow 443/tcp comment 'HTTPS'
            ufw allow 8080/tcp comment 'Wings API'
            ufw allow 2022/tcp comment 'Wings SFTP'
            ufw allow 25565/tcp comment 'Minecraft'
            
            ufw --force enable
            log_success "UFW firewall configured"
            ;;
            
        centos|rhel|rocky|almalinux)
            systemctl enable --now firewalld
            
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-service=https
            firewall-cmd --permanent --add-port=8080/tcp
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=25565/tcp
            
            firewall-cmd --reload
            log_success "Firewalld configured"
            ;;
    esac
}

install_panel() {
    log_info "Installing Ptero Panel..."
    
    PANEL_FQDN=$(prompt_input "Enter Panel FQDN (e.g., panel.example.com)")
    PUBLIC_IP=$(prompt_input "Enter Public IP address")
    
    if ! check_dns "$PANEL_FQDN" "$PUBLIC_IP"; then
        log_warning "DNS does not point to the correct IP"
        if ! prompt_yes_no "Continue anyway?"; then
            log_error "Installation aborted"
            exit 1
        fi
    fi
    
    DB_PASS=$(openssl rand -base64 32)
    
    setup_database "panel" "pterodactyl" "$DB_PASS"
    
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    
    cp .env.example .env
    composer install --no-dev --optimize-autoloader
    
    php artisan key:generate --force
    
    php artisan p:environment:setup \
        --author="$USER_EMAIL" \
        --url="https://$PANEL_FQDN" \
        --timezone="America/New_York" \
        --cache="redis" \
        --session="redis" \
        --queue="redis" \
        --redis-host="127.0.0.1" \
        --redis-pass="" \
        --redis-port="6379"
    
    php artisan p:environment:database \
        --host="127.0.0.1" \
        --port="3306" \
        --database="panel" \
        --username="pterodactyl" \
        --password="$DB_PASS"
    
    php artisan migrate --seed --force
    
    php artisan p:user:make \
        --email="$USER_EMAIL" \
        --username="admin" \
        --name-first="Admin" \
        --name-last="User" \
        --password="$ADMIN_PASS" \
        --admin=1
    
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    configure_panel_nginx "$PANEL_FQDN"
    
    if prompt_yes_no "Do you want to setup SSL with Let's Encrypt?"; then
        certbot --nginx -d "$PANEL_FQDN" --non-interactive --agree-tos -m "$USER_EMAIL"
    fi
    
    systemctl restart nginx
    
    log_success "Ptero Panel installed at https://$PANEL_FQDN"
    log_info "Admin credentials saved to /root/panel_credentials.txt"
    
    cat > /root/panel_credentials.txt <<EOF
Panel URL: https://$PANEL_FQDN
Admin Email: $USER_EMAIL
Admin Password: $ADMIN_PASS
Database Password: $DB_PASS
EOF
    
    chmod 600 /root/panel_credentials.txt
}

configure_panel_nginx() {
    local fqdn="$1"
    
    cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name $fqdn;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $fqdn;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    nginx -t
}

install_redis() {
    if command -v redis-server &> /dev/null; then
        log_info "Redis is already installed"
        return 0
    fi
    
    log_info "Installing Redis..."
    
    case $OS in
        ubuntu|debian)
            apt install -y redis-server
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y redis
            ;;
    esac
    
    systemctl enable --now redis-server || systemctl enable --now redis
    log_success "Redis installed and started"
}

install_wings() {
    log_info "Installing Ptero Wings..."
    
    WINGS_FQDN=$(prompt_input "Enter Wings FQDN (e.g., node.example.com)")
    PUBLIC_IP=$(prompt_input "Enter Public IP address")
    
    if ! check_dns "$WINGS_FQDN" "$PUBLIC_IP"; then
        log_warning "DNS does not point to the correct IP"
        if ! prompt_yes_no "Continue anyway?"; then
            log_error "Installation aborted"
            exit 1
        fi
    fi
    
    mkdir -p /etc/pterodactyl
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod u+x /usr/local/bin/wings
    
    log_warning "You need to configure Wings from the Panel:"
    log_info "1. Go to your Panel admin area"
    log_info "2. Create a new Location"
    log_info "3. Create a new Node with FQDN: $WINGS_FQDN"
    log_info "4. Copy the configuration and paste it into /etc/pterodactyl/config.yml"
    
    if prompt_yes_no "Have you created the node in the panel and ready to paste the config?"; then
        log_info "Please paste the configuration (press Ctrl+D when done):"
        cat > /etc/pterodactyl/config.yml
        
        if prompt_yes_no "Do you want to setup SSL for Wings?"; then
            certbot certonly --standalone -d "$WINGS_FQDN" --non-interactive --agree-tos -m "$USER_EMAIL"
        fi
        
        cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl enable --now wings
        log_success "Wings installed and started"
    else
        log_warning "Wings binary installed but not configured. Configure manually later."
    fi
}

setup_cloudflare() {
    echo ""
    log_info "╔════════════════════════════════════════════════════════════╗"
    log_info "║          Cloudflare DNS Integration Setup                 ║"
    log_info "╚════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "This enables automatic SSL certificate generation using Cloudflare DNS."
    echo ""
    log_info "📋 What you need:"
    log_info "  1. Cloudflare API Token"
    log_info "  2. Cloudflare Zone ID"
    echo ""
    log_info "🔑 How to get your API Token:"
    echo ""
    log_info "  Step 1: Go to https://dash.cloudflare.com/profile/api-tokens"
    log_info "  Step 2: Click 'Create Token'"
    log_info "  Step 3: Click 'Create Custom Token'"
    log_info "  Step 4: Set Token name: 'Pterodactyl DNS'"
    log_info "  Step 5: Add permissions:"
    log_info "          • Zone → DNS → Edit"
    log_info "          • Zone → Zone → Read"
    log_info "  Step 6: Under 'Zone Resources':"
    log_info "          • Include → Specific zone → [your domain]"
    log_info "  Step 7: Click 'Continue to summary'"
    log_info "  Step 8: Click 'Create Token'"
    log_info "  Step 9: Copy the token (shown only once!)"
    echo ""
    log_info "📍 How to get your Zone ID:"
    echo ""
    log_info "  Step 1: Go to https://dash.cloudflare.com"
    log_info "  Step 2: Click on your domain"
    log_info "  Step 3: Scroll down on the Overview page"
    log_info "  Step 4: Find 'Zone ID' in the right sidebar"
    log_info "  Step 5: Click to copy"
    echo ""
    echo -ne "${CYAN}Press Enter when you're ready to continue...${NC} "
    read -r
    echo ""
    
    CF_API_TOKEN=$(prompt_input "Enter Cloudflare API Token (or leave empty to skip)")
    
    if [ -z "$CF_API_TOKEN" ]; then
        log_info "Skipping Cloudflare setup"
        echo ""
        log_info "You can set this up later by running:"
        log_info "  certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/cloudflare.ini -d yourdomain.com"
        echo ""
        return 0
    fi
    
    # Validate token format (basic check)
    if [[ ! "$CF_API_TOKEN" =~ ^[A-Za-z0-9_-]{40,}$ ]]; then
        log_warning "⚠️  Token format looks unusual. Make sure you copied the full token."
        if ! prompt_yes_no "Continue anyway?"; then
            log_info "Cloudflare setup cancelled"
            return 0
        fi
    fi
    
    CF_ZONE_ID=$(prompt_input "Enter Cloudflare Zone ID")
    
    # Validate Zone ID format (basic check)
    if [[ ! "$CF_ZONE_ID" =~ ^[a-f0-9]{32}$ ]]; then
        log_warning "⚠️  Zone ID format looks unusual. It should be 32 hexadecimal characters."
        if ! prompt_yes_no "Continue anyway?"; then
            log_info "Cloudflare setup cancelled"
            return 0
        fi
    fi
    
    echo ""
    log_info "Installing Cloudflare DNS plugin for Certbot..."
    
    case $OS in
        ubuntu|debian)
            apt install -y python3-certbot-dns-cloudflare
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y python3-certbot-dns-cloudflare
            ;;
    esac
    
    mkdir -p /root/.secrets
    cat > /root/.secrets/cloudflare.ini <<EOF
# Cloudflare API Token for DNS validation
# Created: $(date)
dns_cloudflare_api_token = $CF_API_TOKEN
EOF
    chmod 600 /root/.secrets/cloudflare.ini
    
    echo ""
    log_success "✅ Cloudflare integration configured successfully!"
    echo ""
    log_info "📁 Configuration saved to: /root/.secrets/cloudflare.ini"
    log_info "🔒 Zone ID: $CF_ZONE_ID"
    echo ""
    log_info "💡 To generate SSL certificate for your domain:"
    log_info "   certbot certonly --dns-cloudflare \\"
    log_info "     --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \\"
    log_info "     -d yourdomain.com -d *.yourdomain.com"
    echo ""
}

check_service_status() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        log_success "$service is running"
        return 0
    else
        log_error "$service is not running"
        return 1
    fi
}

health_check() {
    log_info "Performing health check..."
    
    local all_healthy=true
    
    if command -v docker &> /dev/null; then
        check_service_status docker || all_healthy=false
    fi
    
    if command -v mysql &> /dev/null; then
        check_service_status mariadb || check_service_status mysql || all_healthy=false
    fi
    
    if command -v nginx &> /dev/null; then
        check_service_status nginx || all_healthy=false
    fi
    
    if command -v redis-server &> /dev/null; then
        check_service_status redis-server || check_service_status redis || all_healthy=false
    fi
    
    if [ -f /usr/local/bin/wings ]; then
        check_service_status wings || all_healthy=false
    fi
    
    if [ -d /var/www/pterodactyl ]; then
        if [ -f /var/www/pterodactyl/artisan ]; then
            log_info "Checking Panel status..."
            cd /var/www/pterodactyl
            php artisan --version
        fi
    fi
    
    if $all_healthy; then
        log_success "All services are healthy"
    else
        log_warning "Some services are not running properly"
    fi
}

update_system() {
    log_info "Updating system packages..."
    
    case $OS in
        ubuntu|debian)
            apt update -y
            apt upgrade -y
            ;;
        centos|rhel|rocky|almalinux)
            yum update -y
            ;;
    esac
    
    log_success "System updated"
}

update_panel() {
    if [ ! -d /var/www/pterodactyl ]; then
        log_warning "Panel not found, skipping panel update"
        return 0
    fi
    
    log_info "Updating Pterodactyl Panel..."
    
    cd /var/www/pterodactyl
    php artisan down
    
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    chmod -R 755 storage/* bootstrap/cache
    
    composer install --no-dev --optimize-autoloader
    
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    
    chown -R www-data:www-data /var/www/pterodactyl/*
    
    php artisan queue:restart
    php artisan up
    
    log_success "Panel updated"
}

update_wings() {
    if [ ! -f /usr/local/bin/wings ]; then
        log_warning "Wings not found, skipping wings update"
        return 0
    fi
    
    log_info "Updating Pterodactyl Wings..."
    
    systemctl stop wings
    
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod u+x /usr/local/bin/wings
    
    systemctl start wings
    
    log_success "Wings updated"
}

update_all() {
    log_info "Starting full system update..."
    
    update_system
    update_panel
    update_wings
    health_check
    
    log_success "All updates completed"
}

scan_and_fix() {
    log_info "Scanning and fixing Ptero installation..."
    
    if [ -d /var/www/pterodactyl ]; then
        log_info "Found Panel installation, checking..."
        
        cd /var/www/pterodactyl
        
        log_info "Fixing permissions..."
        chown -R www-data:www-data /var/www/pterodactyl/*
        chmod -R 755 storage/* bootstrap/cache/
        
        log_info "Clearing caches..."
        php artisan config:clear
        php artisan cache:clear
        php artisan view:clear
        
        log_info "Checking database connection..."
        if php artisan migrate:status &> /dev/null; then
            log_success "Database connection OK"
        else
            log_error "Database connection failed"
        fi
        
        log_info "Restarting queue workers..."
        php artisan queue:restart
    fi
    
    if [ -f /usr/local/bin/wings ]; then
        log_info "Found Wings installation, checking..."
        
        if [ -f /etc/pterodactyl/config.yml ]; then
            log_success "Wings configuration found"
            systemctl restart wings
        else
            log_warning "Wings configuration not found at /etc/pterodactyl/config.yml"
        fi
    fi
    
    health_check
    
    log_success "Scan and fix completed"
}

show_help() {
    cat <<EOF
$SCRIPT_NAME v$VERSION - Ptero Universal Installer

Usage: $SCRIPT_NAME [COMMAND]

Installation Commands:
    install-panel       Install Ptero Panel
    install-wings       Install Ptero Wings
    install-full        Install both Panel and Wings
    
Management Commands:
    update              Update all Ptero components
    health-check        Check status of all services
    scan                Scan and fix Pterodactyl installation
    backup              Run backup (or setup automatic backups)
    clean               Clean cache, logs, and Docker images
    
Advanced Commands:
    customize           Customize Panel appearance
    pre-check           Run pre-installation checks
    quick-setup         Run quick setup wizard
    admin               Launch admin control panel
    ai-assistant        Setup P.R.I.S.M AI assistant
    prism-upgrade       Upgrade to P.R.I.S.M Enhanced
    
Help:
    help                Show this help message

Examples:
    $SCRIPT_NAME install-full
    $SCRIPT_NAME backup
    $SCRIPT_NAME clean
    $SCRIPT_NAME health-check

EOF
}

main() {
    check_root
    detect_os
    
    case "${1:-}" in
        install-panel)
            log_info "Starting Panel installation..."
            show_installation_flow
            
            setup_network_wizard
            
            install_dependencies
            install_mariadb
            install_redis
            install_php
            install_composer
            install_nginx
            install_certbot
            
            USER_EMAIL=$(prompt_with_explanation \
                "Enter your email address" \
                "This email will be used for SSL certificates and admin account notifications." \
                "")
            ADMIN_PASS=$(prompt_with_explanation \
                "Enter admin password" \
                "This is the password for the Panel admin account. Leave blank to auto-generate a secure password." \
                "$(openssl rand -base64 16)")
            
            install_panel
            
            if prompt_yes_no "Do you want to setup Cloudflare integration?"; then
                setup_cloudflare
            fi
            
            setup_reboot_protection
            ask_optional_features
            
            health_check
            log_success "Ptero Panel installation completed!"
            ;;
            
        install-wings)
            log_info "Starting Wings installation..."
            show_installation_flow
            
            setup_network_wizard
            
            install_dependencies
            install_docker
            
            echo ""
            log_info "EXPLANATION: GPU support allows game servers to use your NVIDIA graphics card."
            log_info "This is useful for games that benefit from GPU acceleration."
            if prompt_yes_no "Do you want to enable GPU support?"; then
                configure_gpu_support
            fi
            
            USER_EMAIL=$(prompt_with_explanation \
                "Enter your email address" \
                "This email will be used for SSL certificates." \
                "")
            
            install_wings
            
            setup_reboot_protection
            ask_optional_features
            
            health_check
            log_success "Ptero Wings installation completed!"
            ;;
            
        install-full)
            log_info "Starting full Ptero installation..."
            show_installation_flow
            
            setup_network_wizard
            
            install_dependencies
            install_mariadb
            install_redis
            install_php
            install_composer
            install_nginx
            install_certbot
            install_docker
            
            echo ""
            log_info "EXPLANATION: GPU support allows game servers to use your NVIDIA graphics card."
            log_info "This is useful for games that benefit from GPU acceleration."
            if prompt_yes_no "Do you want to enable GPU support?"; then
                configure_gpu_support
            fi
            
            USER_EMAIL=$(prompt_with_explanation \
                "Enter your email address" \
                "This email will be used for SSL certificates and admin account." \
                "")
            ADMIN_PASS=$(prompt_with_explanation \
                "Enter admin password" \
                "This is the password for the Panel admin account. Leave blank to auto-generate." \
                "$(openssl rand -base64 16)")
            
            install_panel
            
            echo ""
            log_info "EXPLANATION: Wings can be installed on the same server as the Panel,"
            log_info "or on a separate server for better performance and scalability."
            if prompt_yes_no "Do you want to install Wings on this server too?"; then
                install_wings
            fi
            
            if prompt_yes_no "Do you want to setup Cloudflare integration?"; then
                setup_cloudflare
            fi
            
            setup_reboot_protection
            ask_optional_features
            
            health_check
            log_success "Full Ptero installation completed!"
            ;;
            
        update)
            update_all
            ;;
            
        health-check)
            health_check
            ;;
            
        scan)
            scan_and_fix
            ;;
            
        pre-check|precheck)
            log_info "Running pre-installation checks..."
            if [ -f "$(dirname $0)/pre-install-checks.sh" ]; then
                bash "$(dirname $0)/pre-install-checks.sh"
            else
                log_info "Downloading pre-install checks script..."
                curl -sSL -o /tmp/pre-install-checks.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/pre-install-checks.sh
                chmod +x /tmp/pre-install-checks.sh
                bash /tmp/pre-install-checks.sh
            fi
            ;;
            
        quick-setup|quicksetup)
            log_info "Running quick setup wizard..."
            if [ -f "$(dirname $0)/quick-setup.sh" ]; then
                bash "$(dirname $0)/quick-setup.sh"
            else
                log_info "Downloading quick setup script..."
                curl -sSL -o /tmp/quick-setup.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/quick-setup.sh
                chmod +x /tmp/quick-setup.sh
                bash /tmp/quick-setup.sh
            fi
            ;;
            
        admin|control-panel)
            log_info "Launching admin control panel..."
            if [ -f "$(dirname $0)/ptero-admin.sh" ]; then
                bash "$(dirname $0)/ptero-admin.sh"
            else
                log_info "Downloading admin panel..."
                curl -sSL -o /tmp/ptero-admin.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ptero-admin.sh
                chmod +x /tmp/ptero-admin.sh
                bash /tmp/ptero-admin.sh
            fi
            ;;
            
        ai-assistant|ai)
            log_info "Setting up AI assistant..."
            if [ -f "$(dirname $0)/ai-assistant-setup.sh" ]; then
                bash "$(dirname $0)/ai-assistant-setup.sh"
            else
                log_info "Downloading AI assistant setup..."
                curl -sSL -o /tmp/ai-assistant-setup.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/ai-assistant-setup.sh
                chmod +x /tmp/ai-assistant-setup.sh
                bash /tmp/ai-assistant-setup.sh
            fi
            ;;
            
        prism-upgrade|prism)
            log_info "Upgrading to P.R.I.S.M Enhanced..."
            if [ -f "$(dirname $0)/prism-upgrade.sh" ]; then
                bash "$(dirname $0)/prism-upgrade.sh"
            else
                log_info "Downloading P.R.I.S.M Enhanced upgrade..."
                curl -sSL -o /tmp/prism-upgrade.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/prism-upgrade.sh
                curl -sSL -o /tmp/prism-enhanced.py https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/prism-enhanced.py
                curl -sSL -o /tmp/prism-cli.sh https://raw.githubusercontent.com/SirJBiscuit/automatic-system/main/prism-cli.sh
                chmod +x /tmp/prism-upgrade.sh
                bash /tmp/prism-upgrade.sh
            fi
            ;;
            
        backup)
            log_info "Running Pterodactyl backup..."
            if [ -f "/usr/local/bin/pterodactyl-backup.sh" ]; then
                /usr/local/bin/pterodactyl-backup.sh
                log_success "Backup completed! Check /var/backups/ptero/"
            else
                log_warning "Automatic backups not configured yet"
                echo ""
                if prompt_yes_no "Do you want to setup automatic backups now?"; then
                    setup_automatic_backups
                    log_info "Running first backup..."
                    /usr/local/bin/pterodactyl-backup.sh
                    log_success "Backup completed!"
                fi
            fi
            ;;
            
        clean)
            log_info "Cleaning up Pterodactyl..."
            echo ""
            log_info "This will:"
            echo "  • Clear Panel cache"
            echo "  • Clean old logs (>30 days)"
            echo "  • Remove old backups (based on retention)"
            echo "  • Clean Docker images (unused)"
            echo ""
            
            if ! prompt_yes_no "Continue with cleanup?"; then
                log_info "Cleanup cancelled"
                exit 0
            fi
            
            # Clear Panel cache
            if [ -d "/var/www/pterodactyl" ]; then
                log_info "Clearing Panel cache..."
                cd /var/www/pterodactyl
                php artisan cache:clear
                php artisan view:clear
                php artisan config:clear
                log_success "Panel cache cleared"
            fi
            
            # Clean old logs
            log_info "Cleaning old logs..."
            find /var/log -name "*.log" -mtime +30 -type f -delete 2>/dev/null || true
            find /var/www/pterodactyl/storage/logs -name "*.log" -mtime +30 -type f -delete 2>/dev/null || true
            log_success "Old logs cleaned"
            
            # Clean Docker
            if command -v docker &> /dev/null; then
                log_info "Cleaning Docker images..."
                docker system prune -af --volumes
                log_success "Docker cleaned"
            fi
            
            # Show disk space saved
            log_success "Cleanup completed!"
            df -h / | tail -1 | awk '{print "Disk usage: " $5 " (" $3 " used / " $2 " total)"}'
            ;;
            
        help|--help|-h)
            show_help
            ;;
            
        *)
            clear
            log_info "Welcome to $SCRIPT_NAME v$VERSION"
            echo ""
            show_network_diagram
            echo ""
            
            if prompt_yes_no "Do you want to scan existing Ptero installation?"; then
                scan_and_fix
                echo ""
            fi
            
            echo ""
            log_info "What would you like to install?"
            echo "1) Panel only"
            echo "2) Wings only"
            echo "3) Full installation (Panel + Wings)"
            echo "4) Update existing installation"
            echo "5) Exit"
            echo ""
            
            read -p "Enter choice [1-5]: " choice
            
            case $choice in
                1) main install-panel ;;
                2) main install-wings ;;
                3) main install-full ;;
                4) main update ;;
                5) exit 0 ;;
                *) log_error "Invalid choice"; exit 1 ;;
            esac
            ;;
    esac
}

main "$@"
