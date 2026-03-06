#!/bin/bash

# ================================================
# AUTO INSTALLER THEMA PTERODACTYL
# SUPPORT NODE 20-24
# © WINDAHOSTING
# ================================================

set -e  # Exit on error

# =============== COLOR DEFINITIONS ==============
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

# ================ CONFIGURATION =================
PTERODACTYL_DIR="/var/www/pterodactyl"
TEMP_DIR="/root/pterodactyl-temp"
NODE_MAJOR=20  # Default Node version 20 (LTS)
SCRIPT_VERSION="2.0.0"

# ================ GITHUB RAW URLS ===============
REPO_BASE="https://raw.githubusercontent.com/gitfdil1248/thema/main"
THEME_URLS=(
    "stellar|https://github.com/gitfdil1248/thema/raw/main/C2.zip"
    "billing|https://github.com/DITZZ112/foxxhostt/raw/main/C1.zip"
    "enigma|https://github.com/gitfdil1248/thema/raw/main/C3.zip"
)

# ================ HELPER FUNCTIONS ==============
print_banner() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          AUTO INSTALLER THEMA PTERODACTYL v2.0          ║${NC}"
    echo -e "${BLUE}║                   © WINDAHOSTING 2025                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}┌────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${WHITE} $1${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────┘${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️ $1${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_progress() {
    echo -e "${CYAN}  → $1${NC}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

check_system() {
    print_step "Memeriksa sistem..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        print_info "Sistem terdeteksi: $OS $VER"
    else
        print_error "Tidak dapat mendeteksi sistem operasi"
        exit 1
    fi

    # Check if running on Ubuntu/Debian
    if [[ ! "$OS" =~ (Ubuntu|Debian) ]]; then
        print_error "Script ini hanya mendukung Ubuntu/Debian!"
        exit 1
    fi

    print_success "Sistem kompatibel"
}

install_dependencies() {
    print_step "Menginstall dependencies..."
    
    print_progress "Updating package list..."
    apt update -qq > /dev/null 2>&1
    
    print_progress "Installing required packages..."
    apt install -y -qq curl wget git unzip zip tar gzip jq nodejs npm build-essential > /dev/null 2>&1
    
    print_success "Dependencies berhasil diinstall"
}

setup_nodejs() {
    print_step "Menginstall Node.js v$NODE_MAJOR..."
    
    # Remove old Node.js if exists
    if command -v node &> /dev/null; then
        local current_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $current_version -ge 20 && $current_version -le 24 ]]; then
            print_info "Node.js v$current_version sudah terinstall dan kompatibel"
            return 0
        fi
    fi
    
    print_progress "Menambahkan NodeSource repository..."
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - > /dev/null 2>&1
    
    print_progress "Menginstall Node.js..."
    apt install -y -qq nodejs > /dev/null 2>&1
    
    # Install yarn globally
    print_progress "Menginstall Yarn..."
    npm install -g yarn --silent > /dev/null 2>&1
    
    print_success "Node.js $(node -v) dan Yarn $(yarn -v) berhasil diinstall"
}

check_pterodactyl() {
    print_step "Memeriksa instalasi Pterodactyl..."
    
    if [[ ! -d "$PTERODACTYL_DIR" ]]; then
        print_error "Direktori Pterodactyl tidak ditemukan!"
        print_info "Pastikan Panel Pterodactyl sudah terinstall"
        return 1
    fi
    
    if [[ ! -f "$PTERODACTYL_DIR/artisan" ]]; then
        print_error "File artisan tidak ditemukan!"
        return 1
    fi
    
    print_success "Pterodactyl ditemukan"
    return 0
}

backup_pterodactyl() {
    print_step "Membackup Pterodactyl..."
    
    local backup_dir="/root/pterodactyl-backup-$(date +%Y%m%d-%H%M%S)"
    
    print_progress "Membackup ke $backup_dir"
    cp -rf "$PTERODACTYL_DIR" "$backup_dir" > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_success "Backup berhasil disimpan di $backup_dir"
    else
        print_error "Backup gagal!"
        exit 1
    fi
}

download_theme() {
    local theme_name=$1
    local theme_url=$2
    local zip_file="/root/${theme_name}.zip"
    
    print_step "Mendownload theme $theme_name..."
    
    # Download theme
    print_progress "Downloading from $theme_url"
    if wget -q --show-progress --progress=bar:force "$theme_url" -O "$zip_file" 2>&1; then
        print_success "Download selesai"
    else
        print_error "Download gagal!"
        return 1
    fi
    
    # Extract theme
    print_progress "Extracting files..."
    rm -rf "$TEMP_DIR" > /dev/null 2>&1
    mkdir -p "$TEMP_DIR"
    
    if unzip -q "$zip_file" -d "$TEMP_DIR" > /dev/null 2>&1; then
        print_success "Extract selesai"
        rm -f "$zip_file"
    else
        print_error "Extract gagal!"
        rm -f "$zip_file"
        return 1
    fi
    
    return 0
}

apply_theme() {
    local theme_name=$1
    
    print_step "Mengaplikasikan theme $theme_name..."
    
    # Copy theme files
    print_progress "Copying files to Pterodactyl directory..."
    cp -rfT "$TEMP_DIR" "$PTERODACTYL_DIR" > /dev/null 2>&1
    
    cd "$PTERODACTYL_DIR"
    
    # Install dependencies
    print_progress "Installing PHP dependencies..."
    composer install --no-dev --optimize-autoloader --quiet > /dev/null 2>&1
    
    # Install Node dependencies
    print_progress "Installing Node dependencies..."
    yarn install --silent > /dev/null 2>&1
    
    # Add react-feather if needed
    if [[ "$theme_name" != "billing" ]]; then
        print_progress "Adding react-feather..."
        yarn add react-feather --silent > /dev/null 2>&1
    fi
    
    # Run migrations
    print_progress "Running database migrations..."
    php artisan migrate --force --quiet > /dev/null 2>&1
    
    # Build assets
    print_progress "Building assets (this may take a while)..."
    if [[ "$theme_name" == "billing" ]]; then
        php artisan billing:install stable --quiet > /dev/null 2>&1
    fi
    
    yarn build:production --silent > /dev/null 2>&1
    
    # Clear cache
    print_progress "Clearing cache..."
    php artisan view:clear --quiet > /dev/null 2>&1
    php artisan config:clear --quiet > /dev/null 2>&1
    php artisan cache:clear --quiet > /dev/null 2>&1
    
    print_success "Theme berhasil diaplikasikan!"
}

cleanup_temp() {
    print_step "Membersihkan file temporary..."
    rm -rf "$TEMP_DIR" > /dev/null 2>&1
    print_success "Bersih!"
}

configure_enigma() {
    print_step "Konfigurasi Theme Enigma"
    
    echo -e "${YELLOW}Masukkan link WhatsApp (https://wa.me/...):${NC}"
    read -r LINK_WA
    
    echo -e "${YELLOW}Masukkan link Group:${NC}"
    read -r LINK_GROUP
    
    echo -e "${YELLOW}Masukkan link Channel:${NC}"
    read -r LINK_CHNL
    
    local dashboard_file="$TEMP_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx"
    
    if [[ -f "$dashboard_file" ]]; then
        print_progress "Mengganti placeholder dengan nilai yang dimasukkan..."
        sed -i "s|LINK_WA|$LINK_WA|g" "$dashboard_file"
        sed -i "s|LINK_GROUP|$LINK_GROUP|g" "$dashboard_file"
        sed -i "s|LINK_CHNL|$LINK_CHNL|g" "$dashboard_file"
        print_success "Konfigurasi selesai"
    else
        print_error "File konfigurasi tidak ditemukan!"
    fi
}

install_theme() {
    print_banner
    print_section "INSTALL THEME PTERODACTYL"
    
    # Check requirements
    check_root
    check_system
    check_pterodactyl
    if [[ $? -ne 0 ]]; then
        print_error "Pterodactyl tidak terinstall. Install panel terlebih dahulu."
        sleep 3
        return
    fi
    
    # Ask for Node version
    echo ""
    echo -e "${YELLOW}Pilih versi Node.js (default: 20 LTS):${NC}"
    echo "1. Node.js 20 (LTS - Recommended)"
    echo "2. Node.js 21"
    echo "3. Node.js 22"
    echo "4. Node.js 23"
    echo "5. Node.js 24"
    echo -n "Pilihan [1-5] (default: 1): "
    read -r node_choice
    
    case $node_choice in
        2) NODE_MAJOR=21 ;;
        3) NODE_MAJOR=22 ;;
        4) NODE_MAJOR=23 ;;
        5) NODE_MAJOR=24 ;;
        *) NODE_MAJOR=20 ;;
    esac
    
    # Theme selection
    echo ""
    echo -e "${YELLOW}Pilih theme yang ingin diinstall:${NC}"
    echo "1. Stellar Theme"
    echo "2. Billing Theme"
    echo "3. Enigma Theme"
    echo -n "Pilihan [1-3]: "
    read -r theme_choice
    
    case $theme_choice in
        1) theme_name="stellar"; theme_url=$(echo "${THEME_URLS[0]}" | cut -d'|' -f2) ;;
        2) theme_name="billing"; theme_url=$(echo "${THEME_URLS[1]}" | cut -d'|' -f2) ;;
        3) theme_name="enigma"; theme_url=$(echo "${THEME_URLS[2]}" | cut -d'|' -f2) ;;
        *) print_error "Pilihan tidak valid!"; sleep 2; return ;;
    esac
    
    echo ""
    print_info "Theme: $theme_name"
    print_info "Node.js: v$NODE_MAJOR"
    echo ""
    echo -n "Lanjutkan install? (y/n): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Install dibatalkan"
        return
    fi
    
    # Installation process
    echo ""
    backup_pterodactyl
    install_dependencies
    setup_nodejs
    
    if ! download_theme "$theme_name" "$theme_url"; then
        print_error "Gagal mendownload theme"
        cleanup_temp
        sleep 3
        return
    fi
    
    # Configure Enigma if selected
    if [[ "$theme_name" == "enigma" ]]; then
        configure_enigma
    fi
    
    apply_theme "$theme_name"
    cleanup_temp
    
    echo ""
    print_success "✅ INSTALLASI SELESAI!"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Theme $theme_name berhasil diinstall!"
    echo -e "Backup disimpan di /root/pterodactyl-backup-*"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 3
}

uninstall_theme() {
    print_banner
    print_section "UNINSTALL THEME"
    
    echo -e "${RED}⚠️ PERINGATAN: Tindakan ini akan menghapus semua modifikasi theme!${NC}"
    echo -n "Lanjutkan? (y/n): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Uninstall dibatalkan"
        return
    fi
    
    print_step "Menjalankan script repair..."
    
    if bash <(curl -s "${REPO_BASE}/repair.sh"); then
        print_success "Theme berhasil diuninstall!"
    else
        print_error "Gagal menguninstall theme!"
    fi
    
    sleep 3
}

configure_wings() {
    print_banner
    print_section "CONFIGURE WINGS"
    
    echo -e "${YELLOW}Masukkan token Wings:${NC}"
    read -r wings_token
    
    if [[ -z "$wings_token" ]]; then
        print_error "Token tidak boleh kosong!"
        sleep 2
        return
    fi
    
    print_step "Menjalankan perintah Wings..."
    eval "$wings_token"
    
    print_step "Menjalankan service Wings..."
    systemctl start wings
    systemctl enable wings > /dev/null 2>&1
    
    print_success "Wings berhasil dikonfigurasi dan dijalankan!"
    sleep 3
}

create_node() {
    print_banner
    print_section "CREATE NODE & LOCATION"
    
    if [[ ! -d "$PTERODACTYL_DIR" ]]; then
        print_error "Pterodactyl tidak ditemukan!"
        sleep 2
        return
    fi
    
    cd "$PTERODACTYL_DIR"
    
    # Input location
    echo -e "${YELLOW}--- Informasi Location ---${NC}"
    echo -n "Nama Location: "
    read -r location_name
    echo -n "Deskripsi Location: "
    read -r location_desc
    echo -n "Short Code: "
    read -r short_code
    
    # Create location
    print_step "Membuat location baru..."
    php artisan p:location:make <<EOF
$location_name
$location_desc
$short_code
EOF
    
    # Get location ID
    location_id=$(php artisan tinker --execute="echo DB::table('locations')->orderBy('id', 'desc')->first()->id ?? '1';" 2>/dev/null | tail -n1)
    
    # Input node
    echo ""
    echo -e "${YELLOW}--- Informasi Node ---${NC}"
    echo -n "Nama Node: "
    read -r node_name
    echo -n "Deskripsi Node: "
    read -r node_desc
    echo -n "Domain/IP: "
    read -r domain
    echo -n "RAM (MB): "
    read -r ram
    echo -n "Disk Space (MB): "
    read -r disk
    echo -n "Daemon Port (default: 8080): "
    read -r daemon_port
    daemon_port=${daemon_port:-8080}
    
    # Create node
    print_step "Membuat node baru..."
    php artisan p:node:make <<EOF
$node_name
$node_desc
$location_id
https
$domain
yes
no
no
$ram
$ram
$disk
$disk
100
$daemon_port
2022
/var/lib/pterodactyl/volumes
EOF
    
    print_success "Node dan Location berhasil dibuat!"
    sleep 3
}

uninstall_panel() {
    print_banner
    print_section "UNINSTALL PANEL"
    
    echo -e "${RED}⚠️ PERINGATAN: Tindakan ini akan menghapus SELURUH PANEL beserta datanya!${NC}"
    echo -e "${YELLOW}Pastikan Anda sudah membackup data penting.${NC}"
    echo -n "LANJUTKAN UNINSTALL? (ketik 'UNINSTALL' untuk konfirmasi): "
    read -r confirm
    
    if [[ "$confirm" != "UNINSTALL" ]]; then
        print_info "Uninstall dibatalkan"
        return
    fi
    
    print_step "Menjalankan script uninstall..."
    
    bash <(curl -s https://pterodactyl-installer.se) <<EOF
y
y
y
y
EOF
    
    print_success "Panel berhasil diuninstall!"
    sleep 3
}

hackback_panel() {
    print_banner
    print_section "CREATE ADMIN USER"
    
    if [[ ! -d "$PTERODACTYL_DIR" ]]; then
        print_error "Pterodactyl tidak ditemukan!"
        sleep 2
        return
    fi
    
    cd "$PTERODACTYL_DIR"
    
    echo -e "${YELLOW}Masukkan informasi admin baru:${NC}"
    echo -n "Username: "
    read -r username
    echo -n "Email: "
    read -r email
    echo -n "Password: "
    read -rs password
    echo ""
    echo -n "First Name: "
    read -r first_name
    echo -n "Last Name: "
    read -r last_name
    
    print_step "Membuat user admin..."
    
    php artisan p:user:make <<EOF
yes
$email
$username
$first_name
$last_name
$password
EOF
    
    print_success "User admin berhasil dibuat!"
    sleep 3
}

ubahpw_vps() {
    print_banner
    print_section "UBAH PASSWORD VPS"
    
    echo -e "${YELLOW}Masukkan password baru:${NC}"
    read -rs new_password
    echo ""
    echo -e "${YELLOW}Masukkan ulang password baru:${NC}"
    read -rs confirm_password
    echo ""
    
    if [[ "$new_password" != "$confirm_password" ]]; then
        print_error "Password tidak cocok!"
        sleep 2
        return
    fi
    
    if [[ ${#new_password} -lt 8 ]]; then
        print_error "Password minimal 8 karakter!"
        sleep 2
        return
    fi
    
    print_step "Mengubah password VPS..."
    
    echo "root:$new_password" | chpasswd
    
    if [[ $? -eq 0 ]]; then
        print_success "Password VPS berhasil diubah!"
    else
        print_error "Gagal mengubah password!"
    fi
    
    sleep 3
}

show_menu() {
    print_banner
    echo -e "${BOLD}${WHITE}MENU UTAMA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}[1]${NC}  Install Theme"
    echo -e "  ${WHITE}[2]${NC}  Uninstall Theme"
    echo -e "  ${WHITE}[3]${NC}  Configure Wings"
    echo -e "  ${WHITE}[4]${NC}  Create Node & Location"
    echo -e "  ${WHITE}[5]${NC}  Uninstall Panel"
    echo -e "  ${WHITE}[6]${NC}  Create Admin User"
    echo -e "  ${WHITE}[7]${NC}  Ubah Password VPS"
    echo -e "  ${WHITE}[8]${NC}  Cek Versi Node.js"
    echo -e "  ${WHITE}[9]${NC}  Restart Wings"
    echo -e "  ${WHITE}[10]${NC} Cek Status Service"
    echo -e "  ${WHITE}[x]${NC}  Exit"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -n "Pilih menu [1-10/x]: "
}

check_node_version() {
    print_banner
    print_section "CEK VERSI NODE.JS"
    
    if command -v node &> /dev/null; then
        node_version=$(node -v)
        npm_version=$(npm -v)
        yarn_version=$(yarn -v 2>/dev/null || echo "Not installed")
        
        echo -e "${GREEN}Node.js:${NC} $node_version"
        echo -e "${GREEN}NPM:${NC} $npm_version"
        echo -e "${GREEN}Yarn:${NC} $yarn_version"
    else
        print_error "Node.js tidak terinstall!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali..."
    read -r
}

restart_wings() {
    print_banner
    print_section "RESTART WINGS"
    
    if systemctl is-active --quiet wings; then
        print_step "Merestart service wings..."
        systemctl restart wings
        print_success "Wings berhasil direstart!"
    else
        print_error "Service wings tidak aktif!"
    fi
    
    sleep 3
}

check_services() {
    print_banner
    print_section "CEK STATUS SERVICE"
    
    services=("nginx" "php8.1-fpm" "mysql" "redis-server" "wings")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}✅ $service: Running${NC}"
        else
            echo -e "${RED}❌ $service: Stopped/Not Found${NC}"
        fi
    done
    
    echo ""
    echo -n "Tekan Enter untuk kembali..."
    read -r
}

# ================ MAIN EXECUTION ================
main() {
    # Check root immediately
    check_root
    
    while true; do
        show_menu
        read -r MENU_CHOICE
        
        case "$MENU_CHOICE" in
            1) install_theme ;;
            2) uninstall_theme ;;
            3) configure_wings ;;
            4) create_node ;;
            5) uninstall_panel ;;
            6) hackback_panel ;;
            7) ubahpw_vps ;;
            8) check_node_version ;;
            9) restart_wings ;;
            10) check_services ;;
            x|X) 
                echo -e "${GREEN}Terima kasih telah menggunakan script ini!${NC}"
                exit 0 
                ;;
            *)
                print_error "Pilihan tidak valid!"
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"
