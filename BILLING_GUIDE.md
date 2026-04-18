# Ptero Billing System Guide

## Overview

The Ptero Billing System is a complete, automated billing solution for game server hosting businesses. It integrates seamlessly with Pterodactyl Panel and PayPal to provide:

- **Automated Payment Processing** via PayPal
- **Game Server Plan Configuration** with custom pricing
- **Customer Portal** for ordering and managing servers
- **Automatic Server Provisioning** after payment
- **Invoice Management** with automated reminders
- **Add-on Services** (extra RAM, disk, databases, etc.)
- **Referral Program** to grow your business
- **Free Trial Support** to attract customers

## Quick Start

### Installation

The billing system is installed automatically when you choose option 1 during the pteroanyinstall billing setup:

```bash
sudo ./pteroanyinstall.sh install-full
# When prompted, select:
# "Do you want to setup a billing system integration?" -> Yes
# "Select billing option" -> 1 (Automatic Billing Setup)
```

### Setup Wizard

The billing setup wizard will ask you questions to configure your billing system:

#### Step 1: Business Information
- Business/Company Name
- Business Email
- Website URL
- Support Email
- Currency (USD, EUR, GBP, etc.)
- Tax/VAT settings

#### Step 2: PayPal Integration
- PayPal Mode (Sandbox for testing, Live for production)
- PayPal Client ID
- PayPal Secret Key
- PayPal Webhook ID (optional)

#### Step 3: Game Server Plans
For each game server type you want to offer:
- Game Name (Minecraft, Rust, ARK, etc.)
- RAM in MB
- CPU Cores
- Disk Space in MB
- Number of Databases
- Backup Slots
- Monthly Price
- Setup Fee (one-time)
- Minimum Player Slots
- Maximum Player Slots
- Price per Additional Slot

#### Step 4: Billing Cycles
- Monthly (always enabled)
- Quarterly (3 months) with discount
- Semi-Annual (6 months) with discount
- Annual (12 months) with discount

#### Step 5: User Account Settings
- Email verification requirement
- Free trial period (days)
- Trial requires payment method
- Minimum password length
- Referral program settings

#### Step 6: Automation Settings
- Auto-provision servers after payment
- Days before suspending unpaid servers
- Days before terminating suspended servers
- Invoice reminder settings
- Email notification preferences

#### Step 7: Optional Add-ons
- Additional RAM
- Additional Disk Space
- Additional Databases
- DDoS Protection
- Priority Support

## Getting PayPal API Credentials

### For Testing (Sandbox)

1. Go to https://developer.paypal.com
2. Log in with your PayPal account
3. Click "Dashboard" → "My Apps & Credentials"
4. Under "Sandbox", click "Create App"
5. Enter app name and click "Create App"
6. Copy the **Client ID** and **Secret**

### For Production (Live)

1. Go to https://developer.paypal.com
2. Log in with your PayPal Business account
3. Click "Dashboard" → "My Apps & Credentials"
4. Under "Live", click "Create App"
5. Enter app name and click "Create App"
6. Copy the **Client ID** and **Secret**

**Important:** Always test in Sandbox mode first before going live!

## Configuration Files

After setup, configuration files are created in `/etc/ptero-billing/`:

### config.json
Main billing system configuration:
```json
{
  "version": "1.0.0",
  "business": {
    "name": "Your Game Hosting",
    "email": "billing@example.com",
    "website": "https://example.com",
    "support_email": "support@example.com",
    "currency": "USD",
    "tax": {
      "enabled": true,
      "rate": 10,
      "name": "Sales Tax"
    }
  },
  "paypal": {
    "mode": "sandbox",
    "api_url": "https://api-m.sandbox.paypal.com",
    "client_id": "YOUR_CLIENT_ID",
    "secret": "YOUR_SECRET"
  }
}
```

### plans.json
Game server plans configuration:
```json
{
  "plans": [
    {
      "name": "Minecraft",
      "slug": "minecraft",
      "resources": {
        "ram_mb": 2048,
        "cpu_cores": 2,
        "disk_mb": 10240,
        "databases": 1,
        "backups": 2
      },
      "pricing": {
        "monthly": 10.00,
        "setup_fee": 0.00,
        "currency": "USD"
      },
      "slots": {
        "min": 10,
        "max": 100,
        "price_per_slot": 0.50
      }
    }
  ]
}
```

### addons.json
Optional add-ons configuration:
```json
{
  "addons": [
    {
      "type": "ram",
      "name": "Additional RAM",
      "quantity": 1024,
      "price": 2.00,
      "currency": "USD",
      "billing_cycle": "monthly"
    }
  ]
}
```

### database.conf
Database connection details:
```
DB_HOST=localhost
DB_NAME=ptero_billing
DB_USER=billing_user
DB_PASS=GENERATED_PASSWORD
```

## Billing Portal

The billing portal is installed at `/var/www/ptero-billing/` and accessible via your configured domain.

### Portal Features

#### Customer Features
- Browse game server plans
- View pricing and specifications
- Order servers with PayPal checkout
- Manage active servers
- View invoices and payment history
- Upgrade/downgrade plans
- Purchase add-ons
- Refer friends for credits

#### Admin Features (Coming Soon)
- View all orders
- Manage customers
- Generate reports
- Configure plans
- Process refunds
- Send announcements

### Portal Pages

- **Home** - Landing page with featured plans
- **Plans** - Browse all available game server plans
- **Checkout** - PayPal payment integration
- **Dashboard** - Customer account management
- **Invoices** - View and pay invoices
- **Servers** - Manage active game servers

## Database Schema

The billing system creates these tables:

### users
Customer accounts:
- id, email, password
- first_name, last_name
- created_at, email_verified

### orders
Purchase records:
- id, user_id, plan_slug
- amount, currency, status
- paypal_order_id, created_at

### servers
Provisioned game servers:
- id, user_id, order_id
- ptero_server_id, plan_slug
- status, created_at, expires_at

### invoices
Billing invoices:
- id, user_id, server_id
- amount, currency, status
- due_date, paid_at, created_at

## Automation

### Automatic Server Provisioning

When enabled, servers are automatically created in Pterodactyl Panel after successful payment:

1. Customer completes PayPal checkout
2. PayPal webhook notifies billing system
3. Order status updated to "paid"
4. API call to Pterodactyl Panel creates server
5. Server credentials emailed to customer
6. Server status set to "active"

### Automatic Suspension

Unpaid servers are automatically suspended:

1. Invoice becomes overdue
2. Wait configured days (default: 3)
3. Server suspended in Pterodactyl Panel
4. Customer notified via email
5. Customer can pay to reactivate

### Automatic Termination

Suspended servers are automatically terminated:

1. Server suspended for configured days (default: 7)
2. Final warning email sent
3. Server deleted from Pterodactyl Panel
4. Backups retained for 30 days
5. Customer notified

### Invoice Reminders

Automatic email reminders before due date:

1. Invoice created for renewal
2. Reminder sent X days before due (configurable)
3. Reminder sent on due date
4. Overdue notice sent after due date

## Pricing Examples

### Basic Minecraft Server
- Base: $10/month
- 2GB RAM, 2 CPU cores, 10GB disk
- 20 player slots included
- +$0.50 per additional slot
- Customer wants 50 slots = 30 extra slots
- Total: $10 + (30 × $0.50) = $25/month

### With Add-ons
- Base Minecraft: $10/month
- +2GB RAM add-on: $2/month
- +DDoS Protection: $5/month
- Total: $17/month

### With Billing Cycle Discount
- Base: $10/month
- Annual billing: 15% discount
- Total: $10 × 12 × 0.85 = $102/year ($8.50/month)

### With Tax
- Base: $10/month
- Sales Tax (10%): $1/month
- Total: $11/month

## Customization

### Modify Plans

Edit `/etc/ptero-billing/plans.json`:

```bash
sudo nano /etc/ptero-billing/plans.json
```

Changes take effect immediately.

### Modify Pricing

Update plan pricing in plans.json:

```json
"pricing": {
  "monthly": 15.00,
  "setup_fee": 5.00,
  "currency": "USD"
}
```

### Add New Game

Add new plan to plans.json:

```json
{
  "name": "Rust",
  "slug": "rust",
  "resources": {
    "ram_mb": 4096,
    "cpu_cores": 4,
    "disk_mb": 20480,
    "databases": 1,
    "backups": 3
  },
  "pricing": {
    "monthly": 20.00,
    "setup_fee": 0.00,
    "currency": "USD"
  },
  "slots": {
    "min": 50,
    "max": 200,
    "price_per_slot": 0.25
  }
}
```

### Customize Portal Design

Edit CSS in `/var/www/ptero-billing/assets/css/style.css`:

```bash
sudo nano /var/www/ptero-billing/assets/css/style.css
```

### Add Custom Pages

Create new PHP files in `/var/www/ptero-billing/pages/`:

```bash
sudo nano /var/www/ptero-billing/pages/custom.php
```

## Testing

### Test in Sandbox Mode

1. Use PayPal Sandbox credentials
2. Create test buyer account at https://developer.paypal.com
3. Place test order
4. Complete payment with test account
5. Verify server provisioning
6. Check email notifications

### Test Scenarios

- [ ] New customer registration
- [ ] Email verification
- [ ] Browse plans
- [ ] Add to cart
- [ ] PayPal checkout
- [ ] Payment success
- [ ] Server provisioning
- [ ] Invoice generation
- [ ] Payment reminder
- [ ] Overdue suspension
- [ ] Termination
- [ ] Referral credits
- [ ] Add-on purchase
- [ ] Plan upgrade

## Going Live

### Pre-Launch Checklist

- [ ] Test all features in sandbox mode
- [ ] Configure live PayPal credentials
- [ ] Setup SSL certificate for billing domain
- [ ] Configure email server (SMTP)
- [ ] Test email notifications
- [ ] Review pricing and plans
- [ ] Setup backup system
- [ ] Configure firewall rules
- [ ] Test payment flow end-to-end
- [ ] Create terms of service
- [ ] Create privacy policy
- [ ] Setup support system

### Switch to Live Mode

1. Edit `/etc/ptero-billing/config.json`
2. Change PayPal mode to "live"
3. Update PayPal credentials to live keys
4. Update API URL to live endpoint
5. Restart web server

```bash
sudo nano /etc/ptero-billing/config.json
# Change "mode": "sandbox" to "mode": "live"
# Update client_id and secret
sudo systemctl restart nginx
```

## Troubleshooting

### PayPal Payment Fails

**Check:**
- PayPal credentials are correct
- PayPal mode matches credentials (sandbox/live)
- Customer has sufficient funds
- PayPal account is in good standing

**Logs:**
```bash
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

### Server Not Provisioning

**Check:**
- Pterodactyl Panel API is accessible
- API credentials are correct
- Sufficient resources available
- Node is online

**Test API:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://panel.example.com/api/application/servers
```

### Emails Not Sending

**Check:**
- SMTP server configured
- SMTP credentials correct
- Firewall allows SMTP port
- Email templates exist

**Test SMTP:**
```bash
telnet smtp.example.com 587
```

### Database Connection Error

**Check:**
- MySQL is running
- Database exists
- User has permissions
- Credentials in database.conf are correct

**Test Connection:**
```bash
mysql -u billing_user -p ptero_billing
```

## Security

### Best Practices

1. **Use HTTPS** - Always use SSL for billing portal
2. **Strong Passwords** - Enforce minimum password requirements
3. **Email Verification** - Require email verification
4. **Rate Limiting** - Prevent brute force attacks
5. **Input Validation** - Sanitize all user inputs
6. **SQL Injection** - Use prepared statements
7. **XSS Protection** - Escape output
8. **CSRF Protection** - Use tokens for forms
9. **Backup Regularly** - Backup database daily
10. **Monitor Logs** - Check for suspicious activity

### Secure Configuration Files

```bash
chmod 600 /etc/ptero-billing/*.json
chmod 600 /etc/ptero-billing/database.conf
chown www-data:www-data /etc/ptero-billing/*
```

### PayPal Webhook Verification

Always verify PayPal webhooks to prevent fraud:

1. Verify webhook signature
2. Verify webhook source IP
3. Verify order details match
4. Check for duplicate notifications

## Support

### Log Files

```bash
# Nginx access log
tail -f /var/log/nginx/access.log

# Nginx error log
tail -f /var/log/nginx/error.log

# PHP error log
tail -f /var/log/php8.1-fpm.log

# MySQL error log
tail -f /var/log/mysql/error.log
```

### Common Issues

**Issue:** "PayPal button not showing"
**Solution:** Check browser console for JavaScript errors, verify PayPal SDK loaded

**Issue:** "Database connection failed"
**Solution:** Check database.conf credentials, verify MySQL is running

**Issue:** "Server not created after payment"
**Solution:** Check Pterodactyl API credentials, verify node has resources

**Issue:** "Emails not received"
**Solution:** Check spam folder, verify SMTP configuration, check email logs

## Advanced Features

### Referral Program

Customers can refer friends and earn credits:

1. Customer gets unique referral link
2. Friend signs up using link
3. Friend gets discount on first order
4. Customer gets credit after friend's first payment
5. Credit applied to next invoice

### Free Trial

Offer free trial to attract customers:

1. Customer signs up
2. Optionally requires payment method
3. Server provisioned immediately
4. Trial expires after X days
5. Automatically converts to paid or terminates

### Promotional Codes

Create discount codes:

1. Admin creates promo code
2. Customer enters code at checkout
3. Discount applied to order
4. Usage tracked and limited

### Volume Discounts

Automatic discounts for multiple servers:

1. Customer orders multiple servers
2. Discount applied based on quantity
3. Tiered pricing structure
4. Encourages bulk orders

## API Integration

The billing system provides a REST API for integration:

### Endpoints

```
GET  /api/plans - List all plans
GET  /api/plans/{slug} - Get plan details
POST /api/orders - Create new order
GET  /api/orders/{id} - Get order status
POST /api/webhooks/paypal - PayPal webhook handler
```

### Authentication

API uses Bearer token authentication:

```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://billing.example.com/api/plans
```

## Maintenance

### Regular Tasks

**Daily:**
- Check payment processing
- Monitor server provisioning
- Review error logs

**Weekly:**
- Backup database
- Review unpaid invoices
- Check system resources

**Monthly:**
- Generate revenue reports
- Review customer feedback
- Update pricing if needed
- Check for software updates

### Database Backup

```bash
# Manual backup
mysqldump -u billing_user -p ptero_billing > backup.sql

# Automated daily backup (cron)
0 2 * * * mysqldump -u billing_user -p'PASSWORD' ptero_billing > /backups/billing_$(date +\%Y\%m\%d).sql
```

## Conclusion

The Ptero Billing System provides everything you need to run a successful game server hosting business. With automated payment processing, server provisioning, and customer management, you can focus on growing your business while the system handles the technical details.

For additional support, check the documentation or contact support.
