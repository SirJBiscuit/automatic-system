# Pterodactyl Panel Animation Fix Guide

## Problem
The Pterodactyl Panel's CSS animations can cause server stats and UI elements to zoom in and out continuously, creating a distracting and unusable interface. Text may also appear too small on some displays.

## Solution
This fix disables problematic CSS animations and transforms while improving text readability.

## Automatic Fix (Recommended)
Run the panel customizer script which now includes the animation fix:

```bash
cd /path/to/pteroanyinstall
sudo bash panel-customizer.sh
```

The script will automatically:
- Inject inline CSS to disable problematic animations
- Create custom.css with optimized styles
- Increase font sizes for better readability
- Backup original files before making changes

## Manual Fix
If you prefer to apply the fix manually:

### Step 1: Create Custom CSS
```bash
sudo nano /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css
```

Add this CSS:
```css
/* Fix Animation Issues - Prevent Zooming/Flickering */
*, *::before, *::after {
    animation: none !important;
    animation-duration: 0s !important;
    transition: none !important;
    transform: none !important;
}

/* Disable problematic transforms */
*:hover, *:focus, *:active {
    transform: none !important;
    animation: none !important;
}

/* Improve Text Readability */
body { font-size: 16px !important; }
[class*="text-3xl"] { font-size: 2rem !important; }
[class*="text-2xl"] { font-size: 1.75rem !important; }
[class*="text-xl"] { font-size: 1.5rem !important; }
[class*="text-lg"] { font-size: 1.25rem !important; }
[class*="text-sm"] { font-size: 0.95rem !important; }
[class*="text-xs"] { font-size: 0.85rem !important; }
```

### Step 2: Inject Inline CSS (Highest Priority)
```bash
sudo nano /var/www/pterodactyl/resources/views/templates/wrapper.blade.php
```

Add this right after the `<head>` tag:
```html
<head>
    <style>
        /* NUCLEAR OPTION - Inline styles have highest priority */
        *, *::before, *::after {
            animation: none !important;
            animation-duration: 0s !important;
            transition: none !important;
            transform: none !important;
        }
        
        *:hover, *:focus, *:active {
            transform: none !important;
            animation: none !important;
        }
        
        body { font-size: 16px !important; }
        [class*="text-3xl"] { font-size: 2rem !important; }
        [class*="text-2xl"] { font-size: 1.75rem !important; }
        [class*="text-xl"] { font-size: 1.5rem !important; }
        [class*="text-lg"] { font-size: 1.25rem !important; }
        [class*="text-sm"] { font-size: 0.95rem !important; }
        [class*="text-xs"] { font-size: 0.85rem !important; }
    </style>
```

### Step 3: Link Custom CSS
Add this before the `</head>` tag:
```html
    <link rel="stylesheet" href="{{ asset('themes/pterodactyl/css/custom.css') }}">
    <link rel="stylesheet" href="/custom.css">
</head>
```

### Step 4: Create Fallback CSS
```bash
sudo cp /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css /var/www/pterodactyl/public/custom.css
```

### Step 5: Clear Cache
```bash
cd /var/www/pterodactyl
sudo php artisan view:clear
sudo php artisan config:clear
sudo php artisan cache:clear
sudo service nginx restart  # or: sudo service apache2 restart
```

### Step 6: Clear Browser Cache
In your browser:
- Press **F12** to open Developer Tools
- Right-click the refresh button
- Select **"Empty Cache and Hard Reload"**
- Or press **Ctrl+Shift+R** or **Ctrl+F5**

## Verification
After applying the fix:
1. Server stats should no longer zoom in/out
2. Text should be larger and more readable
3. Hover effects should be smooth without transforms
4. No flickering or animation loops

## Troubleshooting

### Fix Not Working
1. Verify the inline CSS is in wrapper.blade.php:
   ```bash
   head -30 /var/www/pterodactyl/resources/views/templates/wrapper.blade.php
   ```
   You should see the `<style>` tag with "NUCLEAR OPTION" comment

2. Check if custom.css exists:
   ```bash
   ls -la /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css
   ls -la /var/www/pterodactyl/public/custom.css
   ```

3. Verify file permissions:
   ```bash
   sudo chown -R www-data:www-data /var/www/pterodactyl/public/
   sudo chmod 644 /var/www/pterodactyl/public/custom.css
   ```

4. Clear all caches again:
   ```bash
   cd /var/www/pterodactyl
   sudo php artisan view:clear
   sudo php artisan config:clear
   sudo php artisan cache:clear
   sudo service nginx restart
   ```

5. Close browser completely and reopen

### Still Having Issues?
If animations persist, they may be JavaScript-based. Check browser console (F12) for errors and report them.

## Reverting Changes
To restore original appearance:

```bash
# Restore backup
sudo cp /var/www/pterodactyl/resources/views/templates/wrapper.blade.php.backup \
       /var/www/pterodactyl/resources/views/templates/wrapper.blade.php

# Remove custom CSS
sudo rm /var/www/pterodactyl/public/themes/pterodactyl/css/custom.css
sudo rm /var/www/pterodactyl/public/custom.css

# Clear cache
cd /var/www/pterodactyl
sudo php artisan view:clear
sudo php artisan config:clear
sudo php artisan cache:clear
```

## What This Fix Does

### Disables
- CSS animations that cause zooming
- Transform effects on hover
- Transition animations that flicker
- All keyframe animations

### Preserves
- Basic hover color changes
- Opacity transitions (0.2s)
- Functionality of all buttons and links
- Panel responsiveness

### Improves
- Text readability with larger font sizes
- Visual stability
- Performance (fewer animations = less CPU)
- User experience

## Technical Details

The fix works by:
1. **Inline CSS** - Highest specificity, loads first
2. **!important flags** - Override all other styles
3. **Universal selector (*)** - Applies to all elements
4. **Multiple CSS locations** - Ensures at least one loads

This "nuclear option" approach ensures the fix works regardless of:
- Theme customizations
- Plugin CSS
- Cached stylesheets
- CDN delays

## Support
If you encounter issues with this fix:
1. Check the troubleshooting section above
2. Review browser console for errors (F12)
3. Verify Pterodactyl Panel version compatibility
4. Report issues to the pteroanyinstall repository

## Credits
- Fix developed for pteroanyinstall project
- Addresses common Pterodactyl Panel CSS animation issues
- Compatible with Pterodactyl Panel v1.x

---
**Last Updated:** 2026-05-11
**Version:** 1.0.0
