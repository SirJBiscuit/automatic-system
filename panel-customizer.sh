#!/bin/bash

set -e

CUSTOMIZER_VERSION="1.0.0"
PANEL_DIR="/var/www/pterodactyl"
THEMES_DIR="$PANEL_DIR/resources/themes"
CUSTOM_CSS="$PANEL_DIR/public/themes/pterodactyl/css/custom.css"
CUSTOM_JS="$PANEL_DIR/public/themes/pterodactyl/js/custom.js"
LOGO_DIR="$PANEL_DIR/public/assets/logos"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[CUSTOMIZER]${NC} $1"
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

show_customizer_banner() {
    cat <<'EOF'

╔════════════════════════════════════════════════════════════════════════╗
║                   PTERO PANEL CUSTOMIZATION WIZARD                     ║
║                    Make Your Panel Look Amazing!                       ║
╚════════════════════════════════════════════════════════════════════════╝

This wizard will help you customize the appearance of your Pterodactyl Panel:
  • Color schemes and themes
  • Custom logo and branding
  • Background images
  • Custom CSS styling
  • Login page customization
  • Navigation bar styling
  • Footer customization

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

show_color_preview() {
    local color="$1"
    local name="$2"
    echo -e "${color}████${NC} $name"
}

select_color_scheme() {
    log_info "Step 1: Color Scheme Selection"
    echo ""
    log_info "EXPLANATION: Choose a color scheme for your panel."
    log_info "This affects buttons, links, headers, and accents throughout the panel."
    echo ""
    
    echo "Available Color Schemes:"
    echo ""
    echo "1) Default Blue (Pterodactyl Original)"
    show_color_preview "\033[48;5;27m" "   Primary: #0e4c92"
    echo ""
    echo "2) Modern Purple"
    show_color_preview "\033[48;5;93m" "   Primary: #7c3aed"
    echo ""
    echo "3) Vibrant Green"
    show_color_preview "\033[48;5;34m" "   Primary: #10b981"
    echo ""
    echo "4) Professional Dark"
    show_color_preview "\033[48;5;236m" "   Primary: #1f2937"
    echo ""
    echo "5) Ocean Blue"
    show_color_preview "\033[48;5;39m" "   Primary: #0ea5e9"
    echo ""
    echo "6) Sunset Orange"
    show_color_preview "\033[48;5;208m" "   Primary: #f97316"
    echo ""
    echo "7) Rose Red"
    show_color_preview "\033[48;5;161m" "   Primary: #e11d48"
    echo ""
    echo "8) Custom (Enter your own hex color)"
    echo ""
    
    read -p "Select color scheme [1-8]: " color_choice
    
    case $color_choice in
        1)
            PRIMARY_COLOR="#0e4c92"
            SECONDARY_COLOR="#1a5fa8"
            ACCENT_COLOR="#2563eb"
            SCHEME_NAME="Default Blue"
            ;;
        2)
            PRIMARY_COLOR="#7c3aed"
            SECONDARY_COLOR="#8b5cf6"
            ACCENT_COLOR="#a78bfa"
            SCHEME_NAME="Modern Purple"
            ;;
        3)
            PRIMARY_COLOR="#10b981"
            SECONDARY_COLOR="#34d399"
            ACCENT_COLOR="#6ee7b7"
            SCHEME_NAME="Vibrant Green"
            ;;
        4)
            PRIMARY_COLOR="#1f2937"
            SECONDARY_COLOR="#374151"
            ACCENT_COLOR="#4b5563"
            SCHEME_NAME="Professional Dark"
            ;;
        5)
            PRIMARY_COLOR="#0ea5e9"
            SECONDARY_COLOR="#38bdf8"
            ACCENT_COLOR="#7dd3fc"
            SCHEME_NAME="Ocean Blue"
            ;;
        6)
            PRIMARY_COLOR="#f97316"
            SECONDARY_COLOR="#fb923c"
            ACCENT_COLOR="#fdba74"
            SCHEME_NAME="Sunset Orange"
            ;;
        7)
            PRIMARY_COLOR="#e11d48"
            SECONDARY_COLOR="#f43f5e"
            ACCENT_COLOR="#fb7185"
            SCHEME_NAME="Rose Red"
            ;;
        8)
            PRIMARY_COLOR=$(prompt_input "Enter primary color (hex)" "#0e4c92")
            SECONDARY_COLOR=$(prompt_input "Enter secondary color (hex)" "#1a5fa8")
            ACCENT_COLOR=$(prompt_input "Enter accent color (hex)" "#2563eb")
            SCHEME_NAME="Custom"
            ;;
        *)
            PRIMARY_COLOR="#0e4c92"
            SECONDARY_COLOR="#1a5fa8"
            ACCENT_COLOR="#2563eb"
            SCHEME_NAME="Default Blue"
            ;;
    esac
    
    log_success "Color scheme selected: $SCHEME_NAME"
}

customize_logo() {
    log_info "Step 2: Logo and Branding"
    echo ""
    log_info "EXPLANATION: Upload your custom logo to replace the Pterodactyl logo."
    log_info "Recommended size: 200x50 pixels (PNG with transparent background)"
    echo ""
    log_info "TIP: You can host your images on:"
    log_info "  • GitHub: Upload to repo, use raw.githubusercontent.com URL"
    log_info "  • Imgur: https://imgur.com (free image hosting)"
    log_info "  • Cloudinary: https://cloudinary.com (CDN with free tier)"
    log_info "  • Discord: Upload to channel, copy image URL"
    log_info "  • Your own web server or CDN"
    echo ""
    
    if prompt_yes_no "Do you want to upload a custom logo?"; then
        echo ""
        echo "Logo Source:"
        echo "1) Local file path"
        echo "2) Download from URL"
        echo ""
        read -p "Select option [1-2]: " logo_source
        
        mkdir -p "$LOGO_DIR"
        
        case $logo_source in
            1)
                LOGO_PATH=$(prompt_input "Enter path to your logo file (PNG/SVG)")
                
                if [ -f "$LOGO_PATH" ]; then
                    # Detect file extension
                    LOGO_EXT="${LOGO_PATH##*.}"
                    cp "$LOGO_PATH" "$LOGO_DIR/custom-logo.$LOGO_EXT"
                    CUSTOM_LOGO="true"
                    log_success "Logo uploaded successfully"
                else
                    log_error "Logo file not found: $LOGO_PATH"
                    CUSTOM_LOGO="false"
                fi
                ;;
            2)
                LOGO_URL=$(prompt_input "Enter logo URL (e.g., https://example.com/logo.png)")
                
                log_info "Downloading logo from URL..."
                if curl -sSL -f "$LOGO_URL" -o "$LOGO_DIR/custom-logo-temp" 2>/dev/null; then
                    # Detect image type from file
                    FILE_TYPE=$(file -b --mime-type "$LOGO_DIR/custom-logo-temp")
                    
                    case $FILE_TYPE in
                        image/png)
                            mv "$LOGO_DIR/custom-logo-temp" "$LOGO_DIR/custom-logo.png"
                            CUSTOM_LOGO="true"
                            log_success "Logo downloaded successfully (PNG)"
                            ;;
                        image/svg+xml)
                            mv "$LOGO_DIR/custom-logo-temp" "$LOGO_DIR/custom-logo.svg"
                            CUSTOM_LOGO="true"
                            log_success "Logo downloaded successfully (SVG)"
                            ;;
                        image/jpeg|image/jpg)
                            mv "$LOGO_DIR/custom-logo-temp" "$LOGO_DIR/custom-logo.jpg"
                            CUSTOM_LOGO="true"
                            log_success "Logo downloaded successfully (JPG)"
                            ;;
                        *)
                            log_error "Unsupported image format: $FILE_TYPE"
                            rm -f "$LOGO_DIR/custom-logo-temp"
                            CUSTOM_LOGO="false"
                            ;;
                    esac
                else
                    log_error "Failed to download logo from URL: $LOGO_URL"
                    CUSTOM_LOGO="false"
                fi
                ;;
            *)
                log_warning "Invalid selection, skipping logo upload"
                CUSTOM_LOGO="false"
                ;;
        esac
    else
        CUSTOM_LOGO="false"
        log_info "Skipping logo upload - using default Pterodactyl logo"
        log_info "You can add a custom logo later by editing:"
        log_info "  $LOGO_DIR/custom-logo.png"
    fi
    
    COMPANY_NAME=$(prompt_input "Enter your company/brand name" "My Game Hosting")
    TAGLINE=$(prompt_input "Enter tagline (optional)" "")
    
    # Create a simple text-based placeholder logo if no custom logo
    if [ "$CUSTOM_LOGO" == "false" ] && prompt_yes_no "Create a simple text-based logo with your company name?"; then
        mkdir -p "$LOGO_DIR"
        log_info "Generating text-based logo..."
        
        # Create SVG logo with company name
        cat > "$LOGO_DIR/custom-logo.svg" <<EOF
<svg width="200" height="50" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:$PRIMARY_COLOR;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$SECONDARY_COLOR;stop-opacity:1" />
    </linearGradient>
  </defs>
  <text x="10" y="35" font-family="Arial, sans-serif" font-size="24" font-weight="bold" fill="url(#grad1)">$COMPANY_NAME</text>
</svg>
EOF
        CUSTOM_LOGO="true"
        log_success "Text-based logo created with your company name"
    fi
}

customize_background() {
    log_info "Step 3: Background Customization"
    echo ""
    log_info "EXPLANATION: Customize the login page and panel background."
    echo ""
    
    echo "Background Options:"
    echo "1) Solid Color"
    echo "2) Gradient"
    echo "3) Custom Image"
    echo "4) Animated Particles"
    echo "5) Keep Default"
    echo ""
    
    read -p "Select background option [1-5]: " bg_choice
    
    case $bg_choice in
        1)
            BG_TYPE="solid"
            BG_COLOR=$(prompt_input "Enter background color (hex)" "#1a202c")
            log_success "Solid color background selected"
            ;;
        2)
            BG_TYPE="gradient"
            BG_COLOR1=$(prompt_input "Enter first gradient color (hex)" "#1a202c")
            BG_COLOR2=$(prompt_input "Enter second gradient color (hex)" "#2d3748")
            BG_DIRECTION=$(prompt_input "Enter gradient direction (to right/to bottom/135deg)" "135deg")
            log_success "Gradient background selected"
            ;;
        3)
            BG_TYPE="image"
            echo ""
            log_info "TIP: Free background image sources:"
            log_info "  • Unsplash: https://unsplash.com (free high-quality photos)"
            log_info "  • Pexels: https://pexels.com (free stock photos)"
            log_info "  • Pixabay: https://pixabay.com (free images)"
            log_info "  • GitHub: Upload to repo, use raw URL"
            log_info "  • Imgur: https://imgur.com (free image hosting)"
            echo ""
            echo "Background Image Source:"
            echo "1) Local file path"
            echo "2) Download from URL"
            echo ""
            read -p "Select option [1-2]: " bg_source
            
            mkdir -p "$PANEL_DIR/public/assets"
            
            case $bg_source in
                1)
                    BG_IMAGE_PATH=$(prompt_input "Enter path to background image")
                    if [ -f "$BG_IMAGE_PATH" ]; then
                        # Detect file extension
                        BG_EXT="${BG_IMAGE_PATH##*.}"
                        cp "$BG_IMAGE_PATH" "$PANEL_DIR/public/assets/bg-custom.$BG_EXT"
                        log_success "Background image uploaded"
                    else
                        log_error "Image not found, using default"
                        BG_TYPE="default"
                    fi
                    ;;
                2)
                    BG_IMAGE_URL=$(prompt_input "Enter background image URL (e.g., https://example.com/bg.jpg)")
                    
                    log_info "Downloading background image from URL..."
                    if curl -sSL -f "$BG_IMAGE_URL" -o "$PANEL_DIR/public/assets/bg-custom-temp" 2>/dev/null; then
                        # Detect image type
                        FILE_TYPE=$(file -b --mime-type "$PANEL_DIR/public/assets/bg-custom-temp")
                        
                        case $FILE_TYPE in
                            image/jpeg|image/jpg)
                                mv "$PANEL_DIR/public/assets/bg-custom-temp" "$PANEL_DIR/public/assets/bg-custom.jpg"
                                log_success "Background image downloaded successfully (JPG)"
                                ;;
                            image/png)
                                mv "$PANEL_DIR/public/assets/bg-custom-temp" "$PANEL_DIR/public/assets/bg-custom.png"
                                log_success "Background image downloaded successfully (PNG)"
                                ;;
                            image/webp)
                                mv "$PANEL_DIR/public/assets/bg-custom-temp" "$PANEL_DIR/public/assets/bg-custom.webp"
                                log_success "Background image downloaded successfully (WebP)"
                                ;;
                            *)
                                log_error "Unsupported image format: $FILE_TYPE"
                                log_error "Supported formats: JPG, PNG, WebP"
                                rm -f "$PANEL_DIR/public/assets/bg-custom-temp"
                                BG_TYPE="default"
                                ;;
                        esac
                        
                        # Check file size
                        if [ -f "$PANEL_DIR/public/assets/bg-custom.jpg" ] || \
                           [ -f "$PANEL_DIR/public/assets/bg-custom.png" ] || \
                           [ -f "$PANEL_DIR/public/assets/bg-custom.webp" ]; then
                            FILE_SIZE=$(du -k "$PANEL_DIR/public/assets/bg-custom."* 2>/dev/null | cut -f1)
                            if [ "$FILE_SIZE" -gt 2048 ]; then
                                log_warning "Background image is large (${FILE_SIZE}KB). Consider optimizing for better performance."
                            fi
                        fi
                    else
                        log_error "Failed to download background image from URL: $BG_IMAGE_URL"
                        BG_TYPE="default"
                    fi
                    ;;
                *)
                    log_warning "Invalid selection, using default background"
                    BG_TYPE="default"
                    ;;
            esac
            
            # If no image was uploaded/downloaded, offer to create a gradient placeholder
            if [ "$BG_TYPE" == "image" ] && [ ! -f "$PANEL_DIR/public/assets/bg-custom.jpg" ] && \
               [ ! -f "$PANEL_DIR/public/assets/bg-custom.png" ] && \
               [ ! -f "$PANEL_DIR/public/assets/bg-custom.webp" ]; then
                log_warning "No background image was set"
                if prompt_yes_no "Create a gradient background instead?"; then
                    BG_TYPE="gradient"
                    BG_COLOR1="$PRIMARY_COLOR"
                    BG_COLOR2="$SECONDARY_COLOR"
                    BG_DIRECTION="135deg"
                    log_success "Using gradient background with your color scheme"
                else
                    BG_TYPE="default"
                fi
            fi
            ;;
        4)
            BG_TYPE="particles"
            PARTICLE_COLOR=$(prompt_input "Enter particle color (hex)" "#ffffff")
            log_success "Animated particles background selected"
            ;;
        *)
            BG_TYPE="default"
            log_info "Using default background"
            ;;
    esac
}

customize_login_page() {
    log_info "Step 4: Login Page Customization"
    echo ""
    log_info "EXPLANATION: Customize the login page appearance."
    echo ""
    
    LOGIN_BOX_STYLE=$(prompt_input "Login box style (modern/glass/minimal)" "modern")
    
    if prompt_yes_no "Show welcome message on login page?"; then
        SHOW_WELCOME="true"
        WELCOME_TITLE=$(prompt_input "Welcome title" "Welcome Back!")
        WELCOME_MESSAGE=$(prompt_input "Welcome message" "Sign in to manage your game servers")
    else
        SHOW_WELCOME="false"
    fi
    
    if prompt_yes_no "Add social login buttons (Discord, Google)?"; then
        SOCIAL_LOGIN="true"
    else
        SOCIAL_LOGIN="false"
    fi
    
    log_success "Login page customization configured"
}

customize_navigation() {
    log_info "Step 5: Navigation Bar Customization"
    echo ""
    log_info "EXPLANATION: Customize the top navigation bar."
    echo ""
    
    echo "Navigation Style:"
    echo "1) Default (Light)"
    echo "2) Dark"
    echo "3) Transparent"
    echo "4) Colored (uses primary color)"
    echo ""
    
    read -p "Select navigation style [1-4]: " nav_choice
    
    case $nav_choice in
        1) NAV_STYLE="light";;
        2) NAV_STYLE="dark";;
        3) NAV_STYLE="transparent";;
        4) NAV_STYLE="colored";;
        *) NAV_STYLE="light";;
    esac
    
    if prompt_yes_no "Show company logo in navigation?"; then
        NAV_SHOW_LOGO="true"
    else
        NAV_SHOW_LOGO="false"
    fi
    
    log_success "Navigation bar customization configured"
}

customize_footer() {
    log_info "Step 6: Footer Customization"
    echo ""
    log_info "EXPLANATION: Customize the footer content and links."
    echo ""
    
    if prompt_yes_no "Customize footer?"; then
        FOOTER_TEXT=$(prompt_input "Footer text" "© 2024 $COMPANY_NAME. All rights reserved.")
        
        if prompt_yes_no "Add custom footer links?"; then
            FOOTER_LINK1_TEXT=$(prompt_input "Link 1 text" "Terms of Service")
            FOOTER_LINK1_URL=$(prompt_input "Link 1 URL" "/terms")
            
            FOOTER_LINK2_TEXT=$(prompt_input "Link 2 text" "Privacy Policy")
            FOOTER_LINK2_URL=$(prompt_input "Link 2 URL" "/privacy")
            
            FOOTER_LINK3_TEXT=$(prompt_input "Link 3 text" "Support")
            FOOTER_LINK3_URL=$(prompt_input "Link 3 URL" "/support")
            
            CUSTOM_FOOTER_LINKS="true"
        else
            CUSTOM_FOOTER_LINKS="false"
        fi
    else
        FOOTER_TEXT=""
        CUSTOM_FOOTER_LINKS="false"
    fi
    
    log_success "Footer customization configured"
}

advanced_customization() {
    log_info "Step 7: Advanced Customization"
    echo ""
    log_info "EXPLANATION: Additional styling options for advanced users."
    echo ""
    
    if prompt_yes_no "Enable dark mode by default?"; then
        DARK_MODE_DEFAULT="true"
    else
        DARK_MODE_DEFAULT="false"
    fi
    
    if prompt_yes_no "Add custom CSS?"; then
        log_info "You can add custom CSS after installation by editing:"
        log_info "$CUSTOM_CSS"
        CUSTOM_CSS_ENABLED="true"
    else
        CUSTOM_CSS_ENABLED="false"
    fi
    
    if prompt_yes_no "Rounded corners for UI elements?"; then
        BORDER_RADIUS=$(prompt_input "Border radius (px)" "8")
    else
        BORDER_RADIUS="0"
    fi
    
    if prompt_yes_no "Add subtle animations?"; then
        ANIMATIONS_ENABLED="true"
    else
        ANIMATIONS_ENABLED="false"
    fi
    
    log_success "Advanced customization configured"
}

generate_custom_css() {
    log_info "Generating custom CSS..."
    
    mkdir -p "$(dirname $CUSTOM_CSS)"
    
    cat > "$CUSTOM_CSS" <<EOF
/* Ptero Panel Custom Styling */
/* Generated by Panel Customizer v$CUSTOMIZER_VERSION */
/* Generated on: $(date) */

:root {
    --primary-color: $PRIMARY_COLOR;
    --secondary-color: $SECONDARY_COLOR;
    --accent-color: $ACCENT_COLOR;
    --border-radius: ${BORDER_RADIUS}px;
}

/* Primary Color Overrides */
.btn-primary,
.bg-primary,
.badge-primary {
    background-color: var(--primary-color) !important;
    border-color: var(--primary-color) !important;
}

.btn-primary:hover {
    background-color: var(--secondary-color) !important;
    border-color: var(--secondary-color) !important;
}

.text-primary,
a:not(.btn) {
    color: var(--primary-color) !important;
}

a:not(.btn):hover {
    color: var(--secondary-color) !important;
}

/* Border Radius */
.btn, .card, .form-control, .modal-content, .alert {
    border-radius: var(--border-radius) !important;
}

EOF

    # Navigation styling
    if [ "$NAV_STYLE" == "dark" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Dark Navigation */
.navbar {
    background-color: #1a202c !important;
    border-bottom: 1px solid #2d3748;
}

.navbar-brand, .nav-link {
    color: #ffffff !important;
}

.nav-link:hover {
    color: var(--accent-color) !important;
}

EOF
    elif [ "$NAV_STYLE" == "transparent" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Transparent Navigation */
.navbar {
    background-color: transparent !important;
    backdrop-filter: blur(10px);
    border-bottom: 1px solid rgba(255,255,255,0.1);
}

EOF
    elif [ "$NAV_STYLE" == "colored" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Colored Navigation */
.navbar {
    background: linear-gradient(135deg, var(--primary-color), var(--secondary-color)) !important;
}

.navbar-brand, .nav-link {
    color: #ffffff !important;
}

EOF
    fi

    # Background styling
    case $BG_TYPE in
        solid)
            cat >> "$CUSTOM_CSS" <<EOF
/* Solid Background */
body {
    background-color: $BG_COLOR !important;
}

EOF
            ;;
        gradient)
            cat >> "$CUSTOM_CSS" <<EOF
/* Gradient Background */
body {
    background: linear-gradient($BG_DIRECTION, $BG_COLOR1, $BG_COLOR2) !important;
    background-attachment: fixed;
}

EOF
            ;;
        image)
            # Detect which image format was uploaded
            BG_IMAGE_FILE=""
            if [ -f "$PANEL_DIR/public/assets/bg-custom.jpg" ]; then
                BG_IMAGE_FILE="bg-custom.jpg"
            elif [ -f "$PANEL_DIR/public/assets/bg-custom.png" ]; then
                BG_IMAGE_FILE="bg-custom.png"
            elif [ -f "$PANEL_DIR/public/assets/bg-custom.webp" ]; then
                BG_IMAGE_FILE="bg-custom.webp"
            else
                BG_IMAGE_FILE="bg-custom.jpg"  # fallback
            fi
            
            cat >> "$CUSTOM_CSS" <<EOF
/* Image Background */
body {
    background-image: url('/assets/$BG_IMAGE_FILE') !important;
    background-size: cover;
    background-position: center;
    background-attachment: fixed;
}

EOF
            ;;
        particles)
            cat >> "$CUSTOM_CSS" <<EOF
/* Particles Background */
body {
    background-color: #0a0e27;
    position: relative;
}

#particles-js {
    position: fixed;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    z-index: -1;
}

EOF
            ;;
    esac

    # Login page styling
    if [ "$LOGIN_BOX_STYLE" == "glass" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Glass Login Box */
.login-box {
    background: rgba(255, 255, 255, 0.1) !important;
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
    box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
}

EOF
    elif [ "$LOGIN_BOX_STYLE" == "minimal" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Minimal Login Box */
.login-box {
    background: transparent !important;
    border: none;
    box-shadow: none;
}

.login-box .card {
    background: rgba(255, 255, 255, 0.95);
}

EOF
    fi

    # Animations
    if [ "$ANIMATIONS_ENABLED" == "true" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Smooth Animations */
* {
    transition: all 0.3s ease;
}

.btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(0,0,0,0.15);
}

EOF
    fi

    # Custom logo
    if [ "$CUSTOM_LOGO" == "true" ]; then
        # Detect which logo format was uploaded
        LOGO_FILE=""
        if [ -f "$LOGO_DIR/custom-logo.png" ]; then
            LOGO_FILE="custom-logo.png"
        elif [ -f "$LOGO_DIR/custom-logo.svg" ]; then
            LOGO_FILE="custom-logo.svg"
        elif [ -f "$LOGO_DIR/custom-logo.jpg" ]; then
            LOGO_FILE="custom-logo.jpg"
        else
            LOGO_FILE="custom-logo.png"  # fallback
        fi
        
        cat >> "$CUSTOM_CSS" <<EOF
/* Custom Logo */
.navbar-brand img,
.login-logo img {
    content: url('/assets/logos/$LOGO_FILE');
    max-height: 50px;
    width: auto;
}

EOF
    fi

    # Footer styling
    if [ -n "$FOOTER_TEXT" ]; then
        cat >> "$CUSTOM_CSS" <<EOF
/* Custom Footer */
.footer {
    background-color: var(--primary-color);
    color: #ffffff;
    padding: 20px 0;
    margin-top: 50px;
}

.footer a {
    color: #ffffff !important;
    opacity: 0.8;
}

.footer a:hover {
    opacity: 1;
}

EOF
    fi

    chmod 644 "$CUSTOM_CSS"
    log_success "Custom CSS generated"
}

generate_custom_js() {
    if [ "$BG_TYPE" == "particles" ]; then
        log_info "Generating particles.js configuration..."
        
        mkdir -p "$(dirname $CUSTOM_JS)"
        
        cat > "$CUSTOM_JS" <<EOF
/* Ptero Panel Custom JavaScript */
/* Generated by Panel Customizer v$CUSTOMIZER_VERSION */

// Particles.js Configuration
particlesJS('particles-js', {
    particles: {
        number: { value: 80, density: { enable: true, value_area: 800 } },
        color: { value: '$PARTICLE_COLOR' },
        shape: { type: 'circle' },
        opacity: { value: 0.5, random: false },
        size: { value: 3, random: true },
        line_linked: {
            enable: true,
            distance: 150,
            color: '$PARTICLE_COLOR',
            opacity: 0.4,
            width: 1
        },
        move: {
            enable: true,
            speed: 2,
            direction: 'none',
            random: false,
            straight: false,
            out_mode: 'out',
            bounce: false
        }
    },
    interactivity: {
        detect_on: 'canvas',
        events: {
            onhover: { enable: true, mode: 'repulse' },
            onclick: { enable: true, mode: 'push' },
            resize: true
        }
    },
    retina_detect: true
});
EOF
        
        chmod 644 "$CUSTOM_JS"
        log_success "Custom JavaScript generated"
    fi
}

inject_customizations() {
    log_info "Injecting customizations into panel..."
    
    # Backup original files
    if [ ! -f "$PANEL_DIR/resources/views/templates/wrapper.blade.php.backup" ]; then
        cp "$PANEL_DIR/resources/views/templates/wrapper.blade.php" \
           "$PANEL_DIR/resources/views/templates/wrapper.blade.php.backup"
    fi
    
    # Inject custom CSS link
    if ! grep -q "custom.css" "$PANEL_DIR/resources/views/templates/wrapper.blade.php"; then
        sed -i '/<\/head>/i \    <link rel="stylesheet" href="{{ asset('"'"'themes/pterodactyl/css/custom.css'"'"') }}">' \
            "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
    fi
    
    # Inject custom JS if particles enabled
    if [ "$BG_TYPE" == "particles" ]; then
        if ! grep -q "particles.js" "$PANEL_DIR/resources/views/templates/wrapper.blade.php"; then
            sed -i '/<\/body>/i \    <div id="particles-js"></div>' \
                "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
            sed -i '/<\/body>/i \    <script src="https://cdn.jsdelivr.net/particles.js/2.0.0/particles.min.js"></script>' \
                "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
            sed -i '/<\/body>/i \    <script src="{{ asset('"'"'themes/pterodactyl/js/custom.js'"'"') }}"></script>' \
                "$PANEL_DIR/resources/views/templates/wrapper.blade.php"
        fi
    fi
    
    log_success "Customizations injected"
}

clear_cache() {
    log_info "Clearing panel cache..."
    
    cd "$PANEL_DIR"
    php artisan view:clear
    php artisan config:clear
    php artisan cache:clear
    
    log_success "Cache cleared"
}

save_customization_config() {
    log_info "Saving customization configuration..."
    
    mkdir -p /etc/ptero-customizer
    
    cat > /etc/ptero-customizer/config.json <<EOF
{
    "version": "$CUSTOMIZER_VERSION",
    "generated": "$(date -Iseconds)",
    "color_scheme": {
        "name": "$SCHEME_NAME",
        "primary": "$PRIMARY_COLOR",
        "secondary": "$SECONDARY_COLOR",
        "accent": "$ACCENT_COLOR"
    },
    "branding": {
        "company_name": "$COMPANY_NAME",
        "tagline": "$TAGLINE",
        "custom_logo": $CUSTOM_LOGO
    },
    "background": {
        "type": "$BG_TYPE"
    },
    "navigation": {
        "style": "$NAV_STYLE",
        "show_logo": $NAV_SHOW_LOGO
    },
    "advanced": {
        "dark_mode_default": $DARK_MODE_DEFAULT,
        "border_radius": "$BORDER_RADIUS",
        "animations": $ANIMATIONS_ENABLED
    }
}
EOF
    
    chmod 600 /etc/ptero-customizer/config.json
    log_success "Configuration saved to /etc/ptero-customizer/config.json"
}

show_summary() {
    clear
    cat <<EOF

╔════════════════════════════════════════════════════════════════════════╗
║                  PANEL CUSTOMIZATION COMPLETE!                         ║
╚════════════════════════════════════════════════════════════════════════╝

Customization Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Color Scheme: $SCHEME_NAME
  Primary: $PRIMARY_COLOR
  Secondary: $SECONDARY_COLOR
  Accent: $ACCENT_COLOR

Branding:
  Company: $COMPANY_NAME
  Custom Logo: $CUSTOM_LOGO

Background: $BG_TYPE
Navigation: $NAV_STYLE style
Border Radius: ${BORDER_RADIUS}px
Animations: $ANIMATIONS_ENABLED

Files Created:
  • $CUSTOM_CSS
  • /etc/ptero-customizer/config.json

Next Steps:
  1. Visit your panel to see the changes
  2. Further customize by editing $CUSTOM_CSS
  3. To revert changes, restore from backups
  4. Run this script again to change customization

Backup Files:
  • $PANEL_DIR/resources/views/templates/wrapper.blade.php.backup

To restore original appearance:
  sudo cp $PANEL_DIR/resources/views/templates/wrapper.blade.php.backup \\
         $PANEL_DIR/resources/views/templates/wrapper.blade.php
  sudo rm $CUSTOM_CSS
  sudo php artisan view:clear

EOF
    
    log_success "Your panel has been customized!"
    log_info "Refresh your browser to see the changes."
}

main() {
    if [ ! -d "$PANEL_DIR" ]; then
        log_error "Pterodactyl Panel not found at $PANEL_DIR"
        log_error "Please install the panel first"
        exit 1
    fi
    
    show_customizer_banner
    
    select_color_scheme
    customize_logo
    customize_background
    customize_login_page
    customize_navigation
    customize_footer
    advanced_customization
    
    generate_custom_css
    generate_custom_js
    inject_customizations
    clear_cache
    save_customization_config
    
    show_summary
}

main "$@"
