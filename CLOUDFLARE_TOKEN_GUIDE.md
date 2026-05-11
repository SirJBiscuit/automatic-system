# Cloudflare API Token Setup Guide

Complete guide for creating a Cloudflare API token for SSH Tunnel setup.

---

## 📋 Quick Steps

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click **"Create Token"**
3. Click **"Create Custom Token"**
4. Configure permissions (see below)
5. Copy the token
6. Paste it in the installer

---

## 🔐 Detailed Instructions

### Step 1: Access API Tokens Page

Open your browser and go to:
```
https://dash.cloudflare.com/profile/api-tokens
```

Or navigate manually:
1. Log in to Cloudflare Dashboard
2. Click your profile icon (top right)
3. Select **"My Profile"**
4. Click **"API Tokens"** in the left sidebar

### Step 2: Create New Token

Click the blue **"Create Token"** button at the top right.

### Step 3: Choose Custom Token

**Don't use a template!** Instead:

1. Scroll down past the templates
2. Click **"Create Custom Token"** at the bottom
3. Or click **"Get started"** next to "Custom token"

### Step 4: Configure Token

Fill in the following:

#### **Token Name:**
```
Cloudflare SSH Tunnel
```
(or any name you prefer)

#### **Permissions:**

Add these two permissions:

**Permission 1:**
- **Type:** Account
- **Permission:** Cloudflare Tunnel
- **Access:** Edit

**Permission 2:**
- **Type:** Zone
- **Permission:** DNS
- **Access:** Edit

#### **Account Resources:**
- Select: **All accounts**
- Or: **Specific account** (choose your account)

#### **Zone Resources:**
- Select: **All zones**
- Or: **Specific zone** (choose your domain)

#### **IP Address Filtering (Optional):**
- Leave blank for access from anywhere
- Or add your server's IP for extra security

#### **TTL (Optional):**
- Leave as default (no expiration)
- Or set an expiration date

### Step 5: Review and Create

1. Click **"Continue to summary"**
2. Review the permissions
3. Click **"Create Token"**

### Step 6: Copy Token

**IMPORTANT:** The token is only shown once!

1. Copy the token immediately
2. Store it securely (password manager recommended)
3. Click **"View"** if you need to see it again before closing

---

## 📸 Visual Guide

### What You'll See:

```
┌─────────────────────────────────────────────────┐
│ Create Custom Token                             │
├─────────────────────────────────────────────────┤
│                                                 │
│ Token name: [Cloudflare SSH Tunnel]            │
│                                                 │
│ Permissions:                                    │
│  ┌─────────────────────────────────────────┐   │
│  │ Account | Cloudflare Tunnel | Edit     │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │ Zone    | DNS              | Edit     │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│ Account Resources: All accounts                 │
│ Zone Resources: All zones                       │
│                                                 │
│         [Continue to summary]                   │
└─────────────────────────────────────────────────┘
```

---

## ✅ Verification

After creating the token, you should see:

```
✅ Success! Token created

Your token: cf_1234567890abcdef...

⚠️  Make sure to copy your token now.
   You won't be able to see it again!

[Copy] [View] [Done]
```

---

## 🔧 Alternative: Using Automatic Authentication

If manual token creation is too complex, use the automatic method:

1. Choose **"Automatic (shows URL to copy)"** in the installer
2. Copy the URL that appears
3. Open it on your phone/computer
4. Log in and authorize
5. Return to terminal

The URL will look like:
```
https://dash.cloudflare.com/argotunnel?callback=https://...
```

---

## 🚨 Troubleshooting

### "Can't find Cloudflare Tunnel permission"

**Solution:**
1. Make sure you're on the **Account** level, not Zone
2. Look for **"Cloudflare Tunnel"** in the dropdown
3. If not available, your account may not have Zero Trust enabled
4. Try using the automatic authentication method instead

### "Token doesn't work"

**Check:**
- ✅ Copied the entire token (no spaces)
- ✅ Token has both permissions (Tunnel + DNS)
- ✅ Account/Zone resources are correct
- ✅ Token hasn't expired

### "Permission denied"

**Fix:**
1. Delete the old token
2. Create a new token with correct permissions
3. Make sure to select **"Edit"** not **"Read"**

---

## 📱 Mobile-Friendly Instructions

If you're setting this up from your phone:

1. **Open Cloudflare app** or browser
2. Go to **Profile → API Tokens**
3. Tap **"Create Token"**
4. Tap **"Create Custom Token"**
5. Add permissions:
   - Account → Cloudflare Tunnel → Edit
   - Zone → DNS → Edit
6. Tap **"Create Token"**
7. **Copy immediately** (long-press to copy)
8. Switch to Termux and paste

---

## 🔒 Security Best Practices

### ✅ Do:
- Store token in a password manager
- Use specific account/zone if possible
- Set IP restrictions if you have a static IP
- Set an expiration date for temporary use
- Delete unused tokens

### ❌ Don't:
- Share your token publicly
- Commit token to git repositories
- Use the same token for multiple purposes
- Leave tokens without expiration indefinitely

---

## 📊 Required Permissions Summary

| Permission Type | Resource | Access Level | Required |
|----------------|----------|--------------|----------|
| Account | Cloudflare Tunnel | Edit | ✅ Yes |
| Zone | DNS | Edit | ✅ Yes |
| Zone | Zone | Read | ❌ Optional |
| Account | Account Settings | Read | ❌ Optional |

---

## 🔗 Useful Links

- **API Tokens Page:** https://dash.cloudflare.com/profile/api-tokens
- **Cloudflare Tunnel Docs:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **API Token Docs:** https://developers.cloudflare.com/fundamentals/api/get-started/create-token/

---

## 💡 Quick Reference

**Minimum Required Permissions:**
```
Account | Cloudflare Tunnel | Edit
Zone    | DNS              | Edit
```

**Token Format:**
```
Starts with: cf_
Length: ~40 characters
Example: cf_1234567890abcdefghijklmnopqrstuvwxyz1234
```

**Where to Use:**
```bash
# When prompted by installer, paste your token:
Paste your Cloudflare API token: [paste here]
```

---

## 🎯 Summary

1. ✅ Go to API Tokens page
2. ✅ Create Custom Token
3. ✅ Add Tunnel + DNS permissions
4. ✅ Copy token immediately
5. ✅ Paste in installer
6. ✅ Done!

**Need help?** Use the automatic authentication method instead - it's easier!
