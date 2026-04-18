#!/bin/bash

set -e

BILLING_VERSION="1.0.0"
BILLING_DIR="/var/www/ptero-billing"
CONFIG_DIR="/etc/ptero-billing"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[BILLING]${NC} $1"
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

show_billing_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                   PTERO BILLING SYSTEM CONFIGURATOR                    ║
║                      Automated Game Server Billing                     ║
╚════════════════════════════════════════════════════════════════════════╝

This wizard will help you set up a complete billing system for your
game server hosting business with PayPal integration.

EOF
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

prompt_currency() {
    echo ""
    echo "Select Currency:"
    echo "1) USD - US Dollar"
    echo "2) EUR - Euro"
    echo "3) GBP - British Pound"
    echo "4) CAD - Canadian Dollar"
    echo "5) AUD - Australian Dollar"
    echo "6) Custom"
    echo ""
    
    read -p "Select currency [1-6]: " currency_choice
    
    case $currency_choice in
        1) echo "USD";;
        2) echo "EUR";;
        3) echo "GBP";;
        4) echo "CAD";;
        5) echo "AUD";;
        6) prompt_input "Enter currency code (e.g., JPY)";;
        *) echo "USD";;
    esac
}

configure_business_info() {
    log_info "Step 1: Business Information"
    echo ""
    log_info "EXPLANATION: This information will appear on invoices and your billing portal."
    echo ""
    
    BUSINESS_NAME=$(prompt_input "Enter your business/company name")
    BUSINESS_EMAIL=$(prompt_input "Enter business email address")
    BUSINESS_WEBSITE=$(prompt_input "Enter website URL" "https://example.com")
    SUPPORT_EMAIL=$(prompt_input "Enter support email" "$BUSINESS_EMAIL")
    
    CURRENCY=$(prompt_currency)
    
    TAX_ENABLED="false"
    if prompt_yes_no "Do you charge sales tax/VAT?"; then
        TAX_ENABLED="true"
        TAX_RATE=$(prompt_input "Enter tax rate (e.g., 10 for 10%)" "0")
        TAX_NAME=$(prompt_input "Enter tax name (e.g., VAT, Sales Tax)" "Tax")
    fi
    
    log_success "Business information configured"
}

configure_paypal() {
    log_info "Step 2: PayPal Integration"
    echo ""
    log_info "EXPLANATION: PayPal will process payments from your customers."
    log_info "You'll need a PayPal Business account and API credentials."
    echo ""
    
    echo "PayPal Mode:"
    echo "1) Sandbox (Testing)"
    echo "2) Live (Production)"
    echo ""
    
    read -p "Select mode [1-2]: " paypal_mode
    
    if [ "$paypal_mode" == "1" ]; then
        PAYPAL_MODE="sandbox"
        PAYPAL_URL="https://api-m.sandbox.paypal.com"
        log_info "Using PayPal Sandbox for testing"
    else
        PAYPAL_MODE="live"
        PAYPAL_URL="https://api-m.paypal.com"
        log_warning "Using PayPal Live mode - real transactions will be processed!"
    fi
    
    echo ""
    log_info "Get your PayPal API credentials from:"
    log_info "https://developer.paypal.com/dashboard/applications/live"
    echo ""
    
    PAYPAL_CLIENT_ID=$(prompt_input "Enter PayPal Client ID")
    PAYPAL_SECRET=$(prompt_input "Enter PayPal Secret Key")
    
    PAYPAL_WEBHOOK_ID=$(prompt_input "Enter PayPal Webhook ID (optional)" "")
    
    log_success "PayPal integration configured"
}

configure_game_servers() {
    log_info "Step 3: Game Server Plans Configuration"
    echo ""
    log_info "EXPLANATION: Define the game server types and pricing you'll offer."
    echo ""
    
    declare -a GAME_PLANS
    
    while true; do
        echo ""
        echo "=== Add Game Server Plan ==="
        
        GAME_NAME=$(prompt_input "Game name (e.g., Minecraft, Rust, ARK)")
        
        echo ""
        echo "Server Specifications:"
        RAM=$(prompt_input "RAM in MB" "2048")
        CPU=$(prompt_input "CPU cores" "2")
        DISK=$(prompt_input "Disk space in MB" "10240")
        DATABASES=$(prompt_input "Number of databases" "1")
        BACKUPS=$(prompt_input "Number of backup slots" "2")
        
        echo ""
        echo "Pricing:"
        MONTHLY_PRICE=$(prompt_input "Monthly price in $CURRENCY" "10.00")
        SETUP_FEE=$(prompt_input "One-time setup fee (0 for none)" "0.00")
        
        echo ""
        echo "Player Slots:"
        MIN_SLOTS=$(prompt_input "Minimum slots" "10")
        MAX_SLOTS=$(prompt_input "Maximum slots" "100")
        PRICE_PER_SLOT=$(prompt_input "Price per additional slot" "0.50")
        
        PLAN_DATA="$GAME_NAME|$RAM|$CPU|$DISK|$DATABASES|$BACKUPS|$MONTHLY_PRICE|$SETUP_FEE|$MIN_SLOTS|$MAX_SLOTS|$PRICE_PER_SLOT"
        GAME_PLANS+=("$PLAN_DATA")
        
        log_success "Added plan: $GAME_NAME - $MONTHLY_PRICE $CURRENCY/month"
        
        if ! prompt_yes_no "Add another game server plan?"; then
            break
        fi
    done
    
    log_success "Game server plans configured (${#GAME_PLANS[@]} plans)"
}

configure_billing_cycles() {
    log_info "Step 4: Billing Cycles"
    echo ""
    log_info "EXPLANATION: Choose which billing periods customers can select."
    echo ""
    
    MONTHLY_ENABLED="true"
    QUARTERLY_ENABLED="false"
    SEMIANNUAL_ENABLED="false"
    ANNUAL_ENABLED="false"
    
    if prompt_yes_no "Enable quarterly billing (3 months)?"; then
        QUARTERLY_ENABLED="true"
        QUARTERLY_DISCOUNT=$(prompt_input "Discount percentage for quarterly" "5")
    fi
    
    if prompt_yes_no "Enable semi-annual billing (6 months)?"; then
        SEMIANNUAL_ENABLED="true"
        SEMIANNUAL_DISCOUNT=$(prompt_input "Discount percentage for semi-annual" "10")
    fi
    
    if prompt_yes_no "Enable annual billing (12 months)?"; then
        ANNUAL_ENABLED="true"
        ANNUAL_DISCOUNT=$(prompt_input "Discount percentage for annual" "15")
    fi
    
    log_success "Billing cycles configured"
}

configure_user_settings() {
    log_info "Step 5: User Account Settings"
    echo ""
    log_info "EXPLANATION: Configure how customer accounts work."
    echo ""
    
    REQUIRE_EMAIL_VERIFICATION="true"
    if ! prompt_yes_no "Require email verification for new accounts?"; then
        REQUIRE_EMAIL_VERIFICATION="false"
    fi
    
    ALLOW_TRIAL="false"
    if prompt_yes_no "Offer free trial period?"; then
        ALLOW_TRIAL="true"
        TRIAL_DAYS=$(prompt_input "Trial period in days" "7")
        TRIAL_REQUIRES_CARD="false"
        if prompt_yes_no "Require payment method for trial?"; then
            TRIAL_REQUIRES_CARD="true"
        fi
    fi
    
    MIN_PASSWORD_LENGTH=$(prompt_input "Minimum password length" "8")
    
    ALLOW_REFERRALS="false"
    if prompt_yes_no "Enable referral program?"; then
        ALLOW_REFERRALS="true"
        REFERRAL_CREDIT=$(prompt_input "Referral credit amount in $CURRENCY" "5.00")
        REFERRAL_DISCOUNT=$(prompt_input "Referee discount percentage" "10")
    fi
    
    log_success "User settings configured"
}

configure_automation() {
    log_info "Step 6: Automation Settings"
    echo ""
    log_info "EXPLANATION: Configure automatic actions for billing events."
    echo ""
    
    AUTO_PROVISION="true"
    if ! prompt_yes_no "Automatically provision servers after payment?"; then
        AUTO_PROVISION="false"
    fi
    
    AUTO_SUSPEND_DAYS=$(prompt_input "Days before suspending unpaid servers" "3")
    AUTO_TERMINATE_DAYS=$(prompt_input "Days before terminating suspended servers" "7")
    
    SEND_INVOICE_REMINDER="true"
    if prompt_yes_no "Send invoice reminders?"; then
        REMINDER_DAYS=$(prompt_input "Days before due date to send reminder" "3")
    fi
    
    SEND_PAYMENT_RECEIPTS="true"
    SEND_WELCOME_EMAIL="true"
    
    log_success "Automation configured"
}

configure_addons() {
    log_info "Step 7: Optional Add-ons"
    echo ""
    log_info "EXPLANATION: Additional services customers can purchase."
    echo ""
    
    declare -a ADDONS
    
    if prompt_yes_no "Offer additional RAM as add-on?"; then
        RAM_ADDON_PRICE=$(prompt_input "Price per 1GB RAM/month" "2.00")
        ADDONS+=("ram|Additional RAM|1024|$RAM_ADDON_PRICE")
    fi
    
    if prompt_yes_no "Offer additional disk space as add-on?"; then
        DISK_ADDON_PRICE=$(prompt_input "Price per 10GB disk/month" "1.00")
        ADDONS+=("disk|Additional Disk Space|10240|$DISK_ADDON_PRICE")
    fi
    
    if prompt_yes_no "Offer additional databases as add-on?"; then
        DB_ADDON_PRICE=$(prompt_input "Price per database/month" "1.50")
        ADDONS+=("database|Additional Database|1|$DB_ADDON_PRICE")
    fi
    
    if prompt_yes_no "Offer DDoS protection as add-on?"; then
        DDOS_ADDON_PRICE=$(prompt_input "Price for DDoS protection/month" "5.00")
        ADDONS+=("ddos|DDoS Protection|1|$DDOS_ADDON_PRICE")
    fi
    
    if prompt_yes_no "Offer priority support as add-on?"; then
        SUPPORT_ADDON_PRICE=$(prompt_input "Price for priority support/month" "10.00")
        ADDONS+=("support|Priority Support|1|$SUPPORT_ADDON_PRICE")
    fi
    
    log_success "Add-ons configured (${#ADDONS[@]} add-ons)"
}

generate_billing_config() {
    log_info "Generating billing system configuration..."
    
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/config.json" <<EOF
{
  "version": "$BILLING_VERSION",
  "business": {
    "name": "$BUSINESS_NAME",
    "email": "$BUSINESS_EMAIL",
    "website": "$BUSINESS_WEBSITE",
    "support_email": "$SUPPORT_EMAIL",
    "currency": "$CURRENCY",
    "tax": {
      "enabled": $TAX_ENABLED,
      "rate": ${TAX_RATE:-0},
      "name": "${TAX_NAME:-Tax}"
    }
  },
  "paypal": {
    "mode": "$PAYPAL_MODE",
    "api_url": "$PAYPAL_URL",
    "client_id": "$PAYPAL_CLIENT_ID",
    "secret": "$PAYPAL_SECRET",
    "webhook_id": "$PAYPAL_WEBHOOK_ID"
  },
  "billing_cycles": {
    "monthly": {
      "enabled": $MONTHLY_ENABLED,
      "discount": 0
    },
    "quarterly": {
      "enabled": $QUARTERLY_ENABLED,
      "discount": ${QUARTERLY_DISCOUNT:-0}
    },
    "semiannual": {
      "enabled": $SEMIANNUAL_ENABLED,
      "discount": ${SEMIANNUAL_DISCOUNT:-0}
    },
    "annual": {
      "enabled": $ANNUAL_ENABLED,
      "discount": ${ANNUAL_DISCOUNT:-0}
    }
  },
  "user_settings": {
    "require_email_verification": $REQUIRE_EMAIL_VERIFICATION,
    "min_password_length": $MIN_PASSWORD_LENGTH,
    "trial": {
      "enabled": $ALLOW_TRIAL,
      "days": ${TRIAL_DAYS:-0},
      "requires_payment_method": ${TRIAL_REQUIRES_CARD:-false}
    },
    "referrals": {
      "enabled": $ALLOW_REFERRALS,
      "credit_amount": ${REFERRAL_CREDIT:-0},
      "discount_percentage": ${REFERRAL_DISCOUNT:-0}
    }
  },
  "automation": {
    "auto_provision": $AUTO_PROVISION,
    "suspend_after_days": $AUTO_SUSPEND_DAYS,
    "terminate_after_days": $AUTO_TERMINATE_DAYS,
    "send_invoice_reminders": $SEND_INVOICE_REMINDER,
    "reminder_days_before": ${REMINDER_DAYS:-3},
    "send_payment_receipts": $SEND_PAYMENT_RECEIPTS,
    "send_welcome_email": $SEND_WELCOME_EMAIL
  }
}
EOF
    
    chmod 600 "$CONFIG_DIR/config.json"
    log_success "Configuration saved to $CONFIG_DIR/config.json"
}

generate_plans_config() {
    log_info "Generating game server plans..."
    
    cat > "$CONFIG_DIR/plans.json" <<EOF
{
  "plans": [
EOF
    
    local first=true
    for plan in "${GAME_PLANS[@]}"; do
        IFS='|' read -r game ram cpu disk dbs backups price setup min_slots max_slots slot_price <<< "$plan"
        
        if [ "$first" = false ]; then
            echo "    ," >> "$CONFIG_DIR/plans.json"
        fi
        first=false
        
        cat >> "$CONFIG_DIR/plans.json" <<EOF
    {
      "name": "$game",
      "slug": "$(echo $game | tr '[:upper:]' '[:lower:]' | tr ' ' '-')",
      "resources": {
        "ram_mb": $ram,
        "cpu_cores": $cpu,
        "disk_mb": $disk,
        "databases": $dbs,
        "backups": $backups
      },
      "pricing": {
        "monthly": $price,
        "setup_fee": $setup,
        "currency": "$CURRENCY"
      },
      "slots": {
        "min": $min_slots,
        "max": $max_slots,
        "price_per_slot": $slot_price
      }
    }
EOF
    done
    
    cat >> "$CONFIG_DIR/plans.json" <<EOF

  ]
}
EOF
    
    chmod 600 "$CONFIG_DIR/plans.json"
    log_success "Plans saved to $CONFIG_DIR/plans.json"
}

generate_addons_config() {
    if [ ${#ADDONS[@]} -eq 0 ]; then
        return
    fi
    
    log_info "Generating add-ons configuration..."
    
    cat > "$CONFIG_DIR/addons.json" <<EOF
{
  "addons": [
EOF
    
    local first=true
    for addon in "${ADDONS[@]}"; do
        IFS='|' read -r type name quantity price <<< "$addon"
        
        if [ "$first" = false ]; then
            echo "    ," >> "$CONFIG_DIR/addons.json"
        fi
        first=false
        
        cat >> "$CONFIG_DIR/addons.json" <<EOF
    {
      "type": "$type",
      "name": "$name",
      "quantity": $quantity,
      "price": $price,
      "currency": "$CURRENCY",
      "billing_cycle": "monthly"
    }
EOF
    done
    
    cat >> "$CONFIG_DIR/addons.json" <<EOF

  ]
}
EOF
    
    chmod 600 "$CONFIG_DIR/addons.json"
    log_success "Add-ons saved to $CONFIG_DIR/addons.json"
}

install_billing_portal() {
    log_info "Installing billing portal web interface..."
    
    mkdir -p "$BILLING_DIR"
    cd "$BILLING_DIR"
    
    cat > "$BILLING_DIR/index.php" <<'EOFPHP'
<?php
require_once 'config.php';
require_once 'functions.php';

session_start();

$page = $_GET['page'] ?? 'home';

include 'header.php';

switch($page) {
    case 'plans':
        include 'pages/plans.php';
        break;
    case 'register':
        include 'pages/register.php';
        break;
    case 'login':
        include 'pages/login.php';
        break;
    case 'dashboard':
        include 'pages/dashboard.php';
        break;
    case 'checkout':
        include 'pages/checkout.php';
        break;
    default:
        include 'pages/home.php';
}

include 'footer.php';
?>
EOFPHP
    
    cat > "$BILLING_DIR/config.php" <<EOFPHP
<?php
define('BILLING_CONFIG', '/etc/ptero-billing/config.json');
define('PLANS_CONFIG', '/etc/ptero-billing/plans.json');
define('ADDONS_CONFIG', '/etc/ptero-billing/addons.json');

\$config = json_decode(file_get_contents(BILLING_CONFIG), true);
\$plans = json_decode(file_get_contents(PLANS_CONFIG), true);
\$addons = file_exists(ADDONS_CONFIG) ? json_decode(file_get_contents(ADDONS_CONFIG), true) : ['addons' => []];

define('BUSINESS_NAME', \$config['business']['name']);
define('CURRENCY', \$config['business']['currency']);
define('PAYPAL_CLIENT_ID', \$config['paypal']['client_id']);
define('PAYPAL_MODE', \$config['paypal']['mode']);
?>
EOFPHP
    
    mkdir -p "$BILLING_DIR/pages"
    mkdir -p "$BILLING_DIR/assets/css"
    mkdir -p "$BILLING_DIR/assets/js"
    
    create_billing_pages
    create_billing_styles
    create_billing_scripts
    
    chown -R www-data:www-data "$BILLING_DIR"
    
    log_success "Billing portal installed at $BILLING_DIR"
}

create_billing_pages() {
    cat > "$BILLING_DIR/pages/plans.php" <<'EOFPHP'
<?php
global $plans, $config;
?>
<div class="container">
    <h1>Game Server Plans</h1>
    <div class="plans-grid">
        <?php foreach($plans['plans'] as $plan): ?>
        <div class="plan-card">
            <h3><?php echo htmlspecialchars($plan['name']); ?></h3>
            <div class="price">
                <?php echo CURRENCY; ?> <?php echo number_format($plan['pricing']['monthly'], 2); ?>/mo
            </div>
            <ul class="features">
                <li><?php echo $plan['resources']['ram_mb']; ?>MB RAM</li>
                <li><?php echo $plan['resources']['cpu_cores']; ?> CPU Cores</li>
                <li><?php echo $plan['resources']['disk_mb']; ?>MB Disk</li>
                <li><?php echo $plan['slots']['min']; ?>-<?php echo $plan['slots']['max']; ?> Player Slots</li>
                <li><?php echo $plan['resources']['databases']; ?> Database(s)</li>
                <li><?php echo $plan['resources']['backups']; ?> Backup Slot(s)</li>
            </ul>
            <a href="?page=checkout&plan=<?php echo $plan['slug']; ?>" class="btn btn-primary">Order Now</a>
        </div>
        <?php endforeach; ?>
    </div>
</div>
EOFPHP

    cat > "$BILLING_DIR/pages/checkout.php" <<'EOFPHP'
<?php
global $plans, $config;

$plan_slug = $_GET['plan'] ?? '';
$selected_plan = null;

foreach($plans['plans'] as $plan) {
    if($plan['slug'] === $plan_slug) {
        $selected_plan = $plan;
        break;
    }
}

if(!$selected_plan) {
    header('Location: ?page=plans');
    exit;
}
?>
<div class="container">
    <h1>Checkout</h1>
    <div class="checkout-container">
        <div class="order-summary">
            <h3>Order Summary</h3>
            <p><strong><?php echo htmlspecialchars($selected_plan['name']); ?></strong></p>
            <p>Monthly Price: <?php echo CURRENCY; ?> <?php echo number_format($selected_plan['pricing']['monthly'], 2); ?></p>
            <?php if($selected_plan['pricing']['setup_fee'] > 0): ?>
            <p>Setup Fee: <?php echo CURRENCY; ?> <?php echo number_format($selected_plan['pricing']['setup_fee'], 2); ?></p>
            <?php endif; ?>
        </div>
        <div class="payment-form">
            <h3>Payment Method</h3>
            <div id="paypal-button-container"></div>
        </div>
    </div>
</div>

<script src="https://www.paypal.com/sdk/js?client-id=<?php echo PAYPAL_CLIENT_ID; ?>&currency=<?php echo CURRENCY; ?>"></script>
<script>
paypal.Buttons({
    createOrder: function(data, actions) {
        return actions.order.create({
            purchase_units: [{
                amount: {
                    value: '<?php echo $selected_plan['pricing']['monthly']; ?>'
                }
            }]
        });
    },
    onApprove: function(data, actions) {
        return actions.order.capture().then(function(details) {
            window.location.href = '?page=success&order_id=' + data.orderID;
        });
    }
}).render('#paypal-button-container');
</script>
EOFPHP
}

create_billing_styles() {
    cat > "$BILLING_DIR/assets/css/style.css" <<'EOFCSS'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    background: #f5f7fa;
    color: #333;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

h1 {
    color: #2c3e50;
    margin-bottom: 30px;
}

.plans-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 30px;
    margin-top: 30px;
}

.plan-card {
    background: white;
    border-radius: 10px;
    padding: 30px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    transition: transform 0.3s;
}

.plan-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 20px rgba(0,0,0,0.15);
}

.plan-card h3 {
    color: #3498db;
    font-size: 24px;
    margin-bottom: 15px;
}

.price {
    font-size: 36px;
    font-weight: bold;
    color: #27ae60;
    margin: 20px 0;
}

.features {
    list-style: none;
    margin: 20px 0;
}

.features li {
    padding: 10px 0;
    border-bottom: 1px solid #ecf0f1;
}

.features li:before {
    content: "✓ ";
    color: #27ae60;
    font-weight: bold;
    margin-right: 10px;
}

.btn {
    display: inline-block;
    padding: 12px 30px;
    text-decoration: none;
    border-radius: 5px;
    transition: all 0.3s;
    font-weight: bold;
    text-align: center;
}

.btn-primary {
    background: #3498db;
    color: white;
}

.btn-primary:hover {
    background: #2980b9;
}

.checkout-container {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 30px;
    margin-top: 30px;
}

.order-summary, .payment-form {
    background: white;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

#paypal-button-container {
    margin-top: 20px;
}
EOFCSS
}

create_billing_scripts() {
    cat > "$BILLING_DIR/assets/js/billing.js" <<'EOFJS'
document.addEventListener('DOMContentLoaded', function() {
    console.log('Ptero Billing System Loaded');
    
    // Add smooth scrolling
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if(target) {
                target.scrollIntoView({ behavior: 'smooth' });
            }
        });
    });
});
EOFJS
}

configure_nginx_billing() {
    log_info "Configuring Nginx for billing portal..."
    
    BILLING_DOMAIN=$(prompt_input "Enter billing portal domain (e.g., billing.example.com)")
    
    cat > /etc/nginx/sites-available/ptero-billing.conf <<EOF
server {
    listen 80;
    server_name $BILLING_DOMAIN;
    root $BILLING_DIR;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/ptero-billing.conf /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
    
    log_success "Nginx configured for $BILLING_DOMAIN"
}

create_database() {
    log_info "Creating billing database..."
    
    DB_NAME="ptero_billing"
    DB_USER="billing_user"
    DB_PASS=$(openssl rand -base64 24)
    
    mysql -u root <<EOFSQL
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOFSQL
    
    mysql -u root $DB_NAME <<EOFSQL
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    email_verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plan_slug VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    paypal_order_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    order_id INT NOT NULL,
    ptero_server_id INT,
    plan_slug VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    server_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(50) DEFAULT 'unpaid',
    due_date DATE NOT NULL,
    paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (server_id) REFERENCES servers(id)
);
EOFSQL
    
    echo "DB_HOST=localhost" >> "$CONFIG_DIR/database.conf"
    echo "DB_NAME=$DB_NAME" >> "$CONFIG_DIR/database.conf"
    echo "DB_USER=$DB_USER" >> "$CONFIG_DIR/database.conf"
    echo "DB_PASS=$DB_PASS" >> "$CONFIG_DIR/database.conf"
    
    chmod 600 "$CONFIG_DIR/database.conf"
    
    log_success "Database created and configured"
}

show_summary() {
    clear
    cat <<EOF

╔════════════════════════════════════════════════════════════════════════╗
║                    BILLING SYSTEM SETUP COMPLETE!                      ║
╚════════════════════════════════════════════════════════════════════════╝

Business Information:
  Name: $BUSINESS_NAME
  Email: $BUSINESS_EMAIL
  Currency: $CURRENCY

PayPal Integration:
  Mode: $PAYPAL_MODE
  Status: Configured

Game Server Plans: ${#GAME_PLANS[@]} plans configured
Add-ons: ${#ADDONS[@]} add-ons available

Configuration Files:
  Main Config: $CONFIG_DIR/config.json
  Plans: $CONFIG_DIR/plans.json
  Add-ons: $CONFIG_DIR/addons.json
  Database: $CONFIG_DIR/database.conf

Billing Portal:
  Location: $BILLING_DIR
  URL: http://$BILLING_DOMAIN

Next Steps:
  1. Setup SSL certificate for billing domain
  2. Test PayPal integration in sandbox mode
  3. Customize billing portal design
  4. Configure email notifications
  5. Test complete order flow

Documentation: See /var/www/ptero-billing/README.md

EOF
    
    log_success "Billing system is ready to use!"
}

main() {
    show_billing_banner
    
    configure_business_info
    configure_paypal
    configure_game_servers
    configure_billing_cycles
    configure_user_settings
    configure_automation
    configure_addons
    
    generate_billing_config
    generate_plans_config
    generate_addons_config
    
    create_database
    install_billing_portal
    configure_nginx_billing
    
    show_summary
}

main "$@"
