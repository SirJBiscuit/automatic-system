# Ptero Panel Customization Guide

## Overview

The Panel Customizer allows you to completely transform the look and feel of your Pterodactyl Panel without any coding knowledge. Customize colors, logos, backgrounds, and more through an interactive wizard.

## Features

- **🎨 Color Schemes** - 8 pre-built themes or custom colors
- **🖼️ Custom Branding** - Upload your logo and set company name
- **🌄 Background Options** - Solid, gradient, image, or animated particles
- **🔐 Login Page Styling** - Modern, glass, or minimal designs
- **🧭 Navigation Customization** - Light, dark, transparent, or colored
- **📄 Footer Customization** - Custom text and links
- **⚡ Advanced Options** - Dark mode, animations, rounded corners

## Quick Start

### Automatic (During Installation)

The customizer runs automatically at the end of pteroanyinstall:

```bash
sudo ./pteroanyinstall.sh install-full
# At the end, you'll be asked:
# "Do you want to customize your panel's appearance?" -> Yes
```

### Manual (After Installation)

Run the customizer anytime:

```bash
cd /path/to/pteroanyinstall
sudo ./panel-customizer.sh
```

## Customization Options

### Step 1: Color Scheme Selection

Choose from 8 pre-built color schemes or create your own:

#### Pre-built Schemes

1. **Default Blue** (Pterodactyl Original)
   - Primary: `#0e4c92`
   - Best for: Professional, trustworthy look

2. **Modern Purple**
   - Primary: `#7c3aed`
   - Best for: Creative, modern brands

3. **Vibrant Green**
   - Primary: `#10b981`
   - Best for: Eco-friendly, growth-focused brands

4. **Professional Dark**
   - Primary: `#1f2937`
   - Best for: Sleek, minimalist design

5. **Ocean Blue**
   - Primary: `#0ea5e9`
   - Best for: Tech, gaming brands

6. **Sunset Orange**
   - Primary: `#f97316`
   - Best for: Energetic, bold brands

7. **Rose Red**
   - Primary: `#e11d48`
   - Best for: Passionate, attention-grabbing

8. **Custom**
   - Enter your own hex colors
   - Full control over primary, secondary, and accent colors

#### What Gets Colored

- **Primary Color**: Buttons, links, headers
- **Secondary Color**: Hover states, accents
- **Accent Color**: Badges, highlights, active states

### Step 2: Logo and Branding

#### Upload Custom Logo

**Requirements:**
- Format: PNG, SVG, or JPG (PNG with transparent background recommended)
- Size: 200x50 pixels (will auto-scale)
- Source: Local file path OR URL

**Option 1: Local File**
```
Logo Source:
1) Local file path
2) Download from URL

Select option [1-2]: 1
Enter path to your logo file: /home/user/my-logo.png
```

**Option 2: Download from URL**
```
Logo Source:
1) Local file path
2) Download from URL

Select option [1-2]: 2
Enter logo URL: https://example.com/logo.png
```

**Supported URL Sources:**
- Direct image URLs (https://example.com/logo.png)
- CDN links (https://cdn.example.com/images/logo.png)
- GitHub raw files (https://raw.githubusercontent.com/user/repo/main/logo.png)
- Image hosting services (Imgur, Cloudinary, etc.)

**Free Image Hosting Options:**
- **GitHub**: Upload to your repo, get raw URL (https://raw.githubusercontent.com/user/repo/main/logo.png)
- **Imgur**: https://imgur.com - Free, no account required
- **Cloudinary**: https://cloudinary.com - Free tier with CDN
- **Discord**: Upload to a channel, copy image URL
- **Your own server**: Any publicly accessible URL

**No Logo? No Problem!**
If you skip logo upload, the script offers to create a simple text-based SVG logo using your company name and color scheme. This provides a professional placeholder until you design a custom logo.

#### Company Name

This appears in:
- Page titles
- Footer
- Email notifications
- Meta tags

#### Tagline (Optional)

Appears on login page and marketing pages.

### Step 3: Background Customization

#### Option 1: Solid Color

Simple, clean background with single color.

**Best for:** Minimalist designs, fast loading

**Example:**
```
Background color: #1a202c (dark gray)
```

#### Option 2: Gradient

Two-color gradient with customizable direction.

**Best for:** Modern, dynamic look

**Example:**
```
First color: #1a202c
Second color: #2d3748
Direction: 135deg (diagonal)
```

**Direction Options:**
- `to right` - Left to right
- `to bottom` - Top to bottom
- `135deg` - Diagonal
- `to bottom right` - Corner to corner

#### Option 3: Custom Image

Upload your own background image from local file or URL.

**Requirements:**
- Format: JPG, PNG, WebP
- Size: 1920x1080 or higher
- File size: Under 2MB for fast loading
- Source: Local file path OR URL

**Best for:** Branded experience, gaming themes

**Option A: Local File**
```
Background Image Source:
1) Local file path
2) Download from URL

Select option [1-2]: 1
Enter path to background image: /home/user/background.jpg
```

**Option B: Download from URL**
```
Background Image Source:
1) Local file path
2) Download from URL

Select option [1-2]: 2
Enter background image URL: https://example.com/bg.jpg
```

**Supported URL Sources:**
- Direct image URLs
- CDN links
- Unsplash (https://unsplash.com/photos/ID/download?force=true)
- Pexels (https://images.pexels.com/photos/ID/photo.jpg)
- Custom image hosting

**Tips:**
- Use subtle, low-contrast images
- Ensure text remains readable
- Consider using overlay for better readability
- The script will automatically detect image format (JPG/PNG/WebP)
- Large images will trigger a size warning

**No Image? Automatic Fallback!**
If the image upload/download fails or you change your mind, the script automatically offers to create a gradient background using your selected color scheme instead. This ensures you always have a professional-looking background.

#### Option 4: Animated Particles

Interactive particle animation background.

**Best for:** Tech-focused, futuristic designs

**Customization:**
- Particle color
- Particle count (default: 80)
- Animation speed
- Interaction effects (hover, click)

**Performance Note:** May impact performance on older devices.

### Step 4: Login Page Customization

#### Login Box Styles

**Modern (Default)**
- Clean white box
- Subtle shadow
- Rounded corners

**Glass (Glassmorphism)**
- Semi-transparent background
- Blur effect
- Modern, premium look

**Minimal**
- No box border
- Transparent background
- Ultra-clean design

#### Welcome Message

Add custom welcome text to login page:

**Example:**
```
Title: "Welcome Back!"
Message: "Sign in to manage your game servers"
```

#### Social Login Buttons

Add Discord, Google, or other OAuth login buttons.

**Note:** Requires additional OAuth configuration in Panel settings.

### Step 5: Navigation Bar Customization

#### Navigation Styles

**Light (Default)**
- White background
- Dark text
- Professional look

**Dark**
- Dark background (#1a202c)
- Light text
- Modern, sleek

**Transparent**
- See-through background
- Blur effect
- Overlay style

**Colored**
- Uses your primary color
- Bold, branded look
- High visibility

#### Logo Display

Choose whether to show your custom logo in the navigation bar.

### Step 6: Footer Customization

#### Custom Footer Text

**Example:**
```
© 2024 My Game Hosting. All rights reserved.
```

#### Custom Links

Add up to 3 custom footer links:

**Example:**
```
Link 1: Terms of Service -> /terms
Link 2: Privacy Policy -> /privacy
Link 3: Support -> /support
```

### Step 7: Advanced Customization

#### Dark Mode Default

Enable dark mode by default for all users.

**Note:** Users can still toggle light/dark mode.

#### Border Radius

Control roundness of UI elements:

- `0px` - Sharp corners (minimal)
- `4px` - Slightly rounded
- `8px` - Rounded (default)
- `12px` - Very rounded
- `20px` - Pill-shaped

#### Animations

Enable smooth transitions and hover effects:

- Button hover lift
- Card hover shadow
- Smooth color transitions
- Page transition effects

**Performance Note:** Disable on slower servers.

#### Custom CSS

Enable custom CSS file for advanced users.

**Location:** `/var/www/pterodactyl/public/themes/pterodactyl/css/custom.css`

## Examples

### Example 1: Gaming Brand

```
Color Scheme: Ocean Blue (#0ea5e9)
Logo: Custom gaming logo
Background: Animated particles (blue)
Login Style: Glass
Navigation: Dark
Animations: Enabled
Border Radius: 8px
```

**Result:** Modern, tech-focused gaming panel

### Example 2: Professional Hosting

```
Color Scheme: Professional Dark (#1f2937)
Logo: Company logo
Background: Solid color (#1a202c)
Login Style: Modern
Navigation: Light
Animations: Disabled
Border Radius: 4px
```

**Result:** Clean, professional business panel

### Example 3: Creative Agency

```
Color Scheme: Modern Purple (#7c3aed)
Logo: Agency logo
Background: Gradient (purple to pink)
Login Style: Glass
Navigation: Transparent
Animations: Enabled
Border Radius: 12px
```

**Result:** Creative, eye-catching panel

### Example 4: Minecraft Server

```
Color Scheme: Vibrant Green (#10b981)
Logo: Minecraft-themed logo
Background: Custom image (Minecraft landscape)
Login Style: Modern
Navigation: Colored (green)
Animations: Enabled
Border Radius: 0px (blocky, like Minecraft)
```

**Result:** Themed Minecraft hosting panel

## Files Created

### Configuration

```
/etc/ptero-customizer/config.json
```

Stores your customization settings for future reference.

### Styling Files

```
/var/www/pterodactyl/public/themes/pterodactyl/css/custom.css
/var/www/pterodactyl/public/themes/pterodactyl/js/custom.js
```

Generated CSS and JavaScript for your customizations.

### Assets

```
/var/www/pterodactyl/public/assets/logos/custom-logo.png
/var/www/pterodactyl/public/assets/bg-custom.jpg
```

Uploaded logo and background images.

### Backups

```
/var/www/pterodactyl/resources/views/templates/wrapper.blade.php.backup
```

Backup of original template file.

## Advanced Customization

### Manual CSS Editing

For advanced users, edit the custom CSS file:

```bash
sudo nano /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css
```

#### Common Customizations

**Change button hover color:**
```css
.btn-primary:hover {
    background-color: #your-color !important;
}
```

**Customize card shadows:**
```css
.card {
    box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
}
```

**Add custom fonts:**
```css
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap');

body {
    font-family: 'Poppins', sans-serif !important;
}
```

**Customize scrollbar:**
```css
::-webkit-scrollbar {
    width: 10px;
}

::-webkit-scrollbar-track {
    background: #1a202c;
}

::-webkit-scrollbar-thumb {
    background: var(--primary-color);
    border-radius: 5px;
}
```

### Adding Custom JavaScript

Edit the custom JS file:

```bash
sudo nano /var/www/pterodactyl/public/themes/pterodactyl/js/custom.js
```

#### Examples

**Add console message:**
```javascript
console.log('Welcome to My Game Hosting!');
```

**Custom page load animation:**
```javascript
document.addEventListener('DOMContentLoaded', function() {
    document.body.style.opacity = '0';
    setTimeout(() => {
        document.body.style.transition = 'opacity 0.5s';
        document.body.style.opacity = '1';
    }, 100);
});
```

## Troubleshooting

### Changes Not Appearing

**Solution 1: Clear browser cache**
```
Ctrl + Shift + R (Windows/Linux)
Cmd + Shift + R (Mac)
```

**Solution 2: Clear panel cache**
```bash
cd /var/www/pterodactyl
php artisan view:clear
php artisan config:clear
php artisan cache:clear
```

**Solution 3: Check file permissions**
```bash
sudo chown -R www-data:www-data /var/www/pterodactyl/public/themes
sudo chmod -R 755 /var/www/pterodactyl/public/themes
```

### Logo Not Displaying

**Check:**
- File exists at `/var/www/pterodactyl/public/assets/logos/custom-logo.png`
- File permissions are correct (644)
- File format is PNG or SVG
- Browser cache is cleared

**Fix:**
```bash
sudo chmod 644 /var/www/pterodactyl/public/assets/logos/custom-logo.png
sudo chown www-data:www-data /var/www/pterodactyl/public/assets/logos/custom-logo.png
```

### Background Image Not Loading

**Check:**
- File exists at `/var/www/pterodactyl/public/assets/bg-custom.jpg`
- File size is reasonable (under 2MB)
- File permissions are correct

**Fix:**
```bash
sudo chmod 644 /var/www/pterodactyl/public/assets/bg-custom.jpg
```

### Particles Not Animating

**Check:**
- JavaScript is enabled in browser
- particles.js library is loading
- No console errors

**Fix:**
```bash
# Check custom.js exists
ls -la /var/www/pterodactyl/public/themes/pterodactyl/js/custom.js

# Check wrapper.blade.php includes particles
grep "particles" /var/www/pterodactyl/resources/views/templates/wrapper.blade.php
```

### Colors Not Applying

**Check:**
- custom.css file exists and is not empty
- CSS is linked in wrapper.blade.php
- No syntax errors in CSS

**Fix:**
```bash
# Verify CSS file
cat /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css

# Clear cache
cd /var/www/pterodactyl
php artisan view:clear
```

## Reverting Changes

### Restore Original Appearance

```bash
# Restore original template
sudo cp /var/www/pterodactyl/resources/views/templates/wrapper.blade.php.backup \
       /var/www/pterodactyl/resources/views/templates/wrapper.blade.php

# Remove custom CSS
sudo rm /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css

# Remove custom JS
sudo rm /var/www/pterodactyl/public/themes/pterodactyl/js/custom.js

# Clear cache
cd /var/www/pterodactyl
php artisan view:clear
php artisan config:clear
php artisan cache:clear
```

### Restore Specific Elements

**Remove custom logo:**
```bash
sudo rm /var/www/pterodactyl/public/assets/logos/custom-logo.png
```

**Remove background image:**
```bash
sudo rm /var/www/pterodactyl/public/assets/bg-custom.jpg
```

## Re-running Customizer

You can run the customizer again anytime to change your customization:

```bash
cd /path/to/pteroanyinstall
sudo ./panel-customizer.sh
```

**Note:** This will overwrite your previous customizations. Manual CSS edits will be preserved unless you select "Add custom CSS" again.

## Best Practices

### Performance

1. **Optimize Images**
   - Compress logos and backgrounds
   - Use WebP format when possible
   - Keep file sizes under 500KB

2. **Limit Animations**
   - Disable on slower servers
   - Use CSS transitions instead of JavaScript
   - Test on mobile devices

3. **Cache Management**
   - Clear cache after changes
   - Use browser dev tools to debug
   - Monitor server resources

### Design

1. **Color Contrast**
   - Ensure text is readable
   - Test with color blindness simulators
   - Use WCAG contrast guidelines

2. **Branding Consistency**
   - Match your website colors
   - Use same logo across platforms
   - Maintain consistent typography

3. **User Experience**
   - Keep navigation clear
   - Don't overcomplicate design
   - Test on multiple devices
   - Get user feedback

### Security

1. **File Permissions**
   - Keep CSS/JS files readable (644)
   - Protect config files (600)
   - Use www-data ownership

2. **Input Validation**
   - Only use trusted images
   - Validate hex color codes
   - Sanitize custom CSS

3. **Backup**
   - Keep original files backed up
   - Test changes in staging first
   - Document customizations

## Support

### Getting Help

1. Check this guide first
2. Review troubleshooting section
3. Check panel logs: `/var/log/nginx/error.log`
4. Clear all caches
5. Test in incognito mode

### Reporting Issues

When reporting issues, include:
- Customization settings used
- Browser and version
- Console errors (F12)
- Screenshots
- Steps to reproduce

## Conclusion

The Panel Customizer makes it easy to create a unique, branded Pterodactyl Panel without any coding knowledge. Experiment with different combinations to find the perfect look for your hosting business!

For more advanced customization, consider hiring a web developer or learning CSS/JavaScript basics.
