#!/bin/bash

# ================================================
# AUTO INSTALLER THEMA PTERODACTYL
# SUPPORT NODE 20-24
# © WINDAHOSTING
# ================================================

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
NODE_MAJOR=20
SCRIPT_VERSION="2.0.1"

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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

# ================ CHECK TOKEN ==============
check_token() {
    print_banner
    print_section "LICENSY WINDAHOSTING"
    echo ""
    echo -e "${YELLOW}MASUKAN AKSES TOKEN :${NC}"
    echo -e "${WHITE}(default: windaslebew)${NC}"
    read -r USER_TOKEN
    
    if [ -z "$USER_TOKEN" ]; then
        USER_TOKEN="windaslebew"
    fi

    if [ "$USER_TOKEN" = "windaslebew" ]; then
        echo ""
        print_success "AKSES BERHASIL"
        echo -e "${GREEN}Selamat datang di auto install by windhost${NC}"
        echo -e "${YELLOW}selamat memakai script dari windhost${NC}"
        echo -e "${YELLOW}ini script free ya buat kalian${NC}"
        echo -e "${YELLOW}jangan di jual belikan${NC}"
        echo -e "${YELLOW}©WindHost${NC}"
        sleep 3
    else
        echo ""
        print_error "TOKEN SALAH!"
        echo -e "${YELLOW}Silahkan coba lagi${NC}"
        sleep 2
        check_token
    fi
}

# ================ DISPLAY WELCOME ==============
display_welcome() {
    print_banner
    echo -e "${BLUE}[+] =============================================== [+]${NC}"
    echo -e "${BLUE}[+]                AUTO INSTALLER THEMA             [+]${NC}"
    echo -e "${BLUE}[+]                  © WINDAHOSTING                 [+]${NC}"
    echo -e "${RED}[+] =============================================== [+]${NC}"
    echo -e ""
    echo -e "script ini free untuk kalian pakai sesuka hati kalian,"
    echo -e "semoga membantu pekerjaan anda ©windhost"
    echo -e ""
    echo -e "𝗧𝗘𝗟𝗘𝗚𝗥𝗔𝗠 :"
    echo -e "@OsideGirl"
    echo -e "𝗖𝗥𝗘𝗗𝗜𝗧𝗦 :"
    echo -e "@windhost"
    echo -e ""
    echo -n "Tekan Enter untuk melanjutkan..."
    read
}

# ================ CHECK SYSTEM ==============
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
    sleep 1
}

# ================ INSTALL DEPENDENCIES ==============
install_dependencies() {
    print_step "Menginstall dependencies..."
    
    print_progress "Updating package list..."
    apt update -y > /dev/null 2>&1
    
    print_progress "Installing required packages (curl, wget, unzip, git, jq)..."
    apt install -y curl wget unzip zip git jq software-properties-common apt-transport-https ca-certificates gnupg lsb-release > /dev/null 2>&1
    
    # Check if installation was successful
    if [ $? -eq 0 ]; then
        print_success "Dependencies berhasil diinstall"
    else
        print_error "Gagal menginstall dependencies"
        exit 1
    fi
    sleep 1
}

# ================ SETUP NODE.JS ==============
setup_nodejs() {
    print_step "Menginstall Node.js v$NODE_MAJOR..."
    
    # Remove old Node.js if exists
    if command -v node &> /dev/null; then
        local current_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        print_info "Node.js v$current_version sudah terinstall"
        
        if [[ $current_version -ge $NODE_MAJOR ]]; then
            print_success "Menggunakan Node.js yang sudah ada"
            return 0
        fi
    fi
    
    print_progress "Menambahkan NodeSource repository..."
    
    # Remove existing nodesource repo if any
    rm -f /etc/apt/sources.list.d/nodesource.list
    
    # Download and run nodesource setup script with more verbose output
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Gagal menambahkan repository NodeSource"
        exit 1
    fi
    
    print_progress "Menginstall Node.js..."
    apt install -y nodejs > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Gagal menginstall Node.js"
        exit 1
    fi
    
    # Install yarn globally
    print_progress "Menginstall Yarn..."
    npm install -g yarn --silent > /dev/null 2>&1
    
    if command -v yarn &> /dev/null; then
        print_success "Node.js $(node -v) dan Yarn $(yarn -v) berhasil diinstall"
    else
        print_success "Node.js $(node -v) berhasil diinstall"
    fi
    sleep 1
}

# ================ CHECK PTERODACTYL ==============
check_pterodactyl() {
    print_step "Memeriksa instalasi Pterodactyl..."
    
    if [[ ! -d "$PTERODACTYL_DIR" ]]; then
        print_error "Direktori Pterodactyl tidak ditemukan!"
        print_info "Pastikan Panel Pterodactyl sudah terinstall"
        echo ""
        echo -e "${YELLOW}Apakah Anda ingin menginstall Panel Pterodactyl dulu? (y/n)${NC}"
        read -r install_panel
        
        if [[ "$install_panel" =~ ^[Yy]$ ]]; then
            install_panel_dulu
        else
            exit 1
        fi
    else
        print_success "Pterodactyl ditemukan"
    fi
    sleep 1
}

# ================ INSTALL PANEL ==============
install_panel_dulu() {
    print_step "Menginstall Panel Pterodactyl..."
    print_info "Menggunakan script installer resmi"
    
    bash <(curl -s https://pterodactyl-installer.se) <<EOF
0
y
y
y
y
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Panel berhasil diinstall"
    else
        print_error "Gagal menginstall panel"
        exit 1
    fi
}

# ================ BACKUP PTERODACTYL ==============
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
    sleep 1
}

# ================ DOWNLOAD THEME ==============
download_theme() {
    local theme_name=$1
    local theme_url=$2
    local zip_file="/root/${theme_name}.zip"
    
    print_step "Mendownload theme $theme_name..."
    
    # Download theme with progress
    print_progress "Downloading from $theme_url"
    
    # Use wget with progress bar
    wget -q --show-progress "$theme_url" -O "$zip_file"
    
    if [ $? -eq 0 ] && [ -f "$zip_file" ]; then
        print_success "Download selesai"
    else
        print_error "Download gagal!"
        return 1
    fi
    
    # Extract theme
    print_progress "Extracting files..."
    rm -rf "$TEMP_DIR" > /dev/null 2>&1
    mkdir -p "$TEMP_DIR"
    
    unzip -q "$zip_file" -d "$TEMP_DIR" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Extract selesai"
        rm -f "$zip_file"
        
        # Check if extracted folder contains pterodactyl folder
        if [ -d "$TEMP_DIR/pterodactyl" ]; then
            mv "$TEMP_DIR/pterodactyl"/* "$TEMP_DIR/" 2>/dev/null
            rm -rf "$TEMP_DIR/pterodactyl"
        fi
    else
        print_error "Extract gagal!"
        rm -f "$zip_file"
        return 1
    fi
    
    return 0
}

# ================ APPLY THEME ==============
apply_theme() {
    local theme_name=$1
    
    print_step "Mengaplikasikan theme $theme_name..."
    
    # Copy theme files
    print_progress "Copying files to Pterodactyl directory..."
    cp -rfT "$TEMP_DIR" "$PTERODACTYL_DIR" > /dev/null 2>&1
    
    cd "$PTERODACTYL_DIR"
    
    # Install PHP dependencies
    print_progress "Installing PHP dependencies..."
    composer install --no-dev --optimize-autoloader --quiet > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Gagal install PHP dependencies"
        return 1
    fi
    
    # Install Node dependencies
    print_progress "Installing Node dependencies (this may take 2-3 minutes)..."
    yarn install --silent > /dev/null 2>&1 &
    
    # Show spinner while yarn installs
    local pid=$!
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "\r  → Installing... ${spin:$i:1} "
        sleep 0.1
    done
    printf "\r  → Installing... Done!   \n"
    
    # Add react-feather if needed
    if [[ "$theme_name" == "stellar" || "$theme_name" == "enigma" ]]; then
        print_progress "Adding react-feather..."
        yarn add react-feather --silent > /dev/null 2>&1
    fi
    
    # Run migrations
    print_progress "Running database migrations..."
    php artisan migrate --force --quiet > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        print_error "Gagal menjalankan migrasi"
        return 1
    fi
    
    # Special for billing theme
    if [[ "$theme_name" == "billing" ]]; then
        print_progress "Installing billing module..."
        php artisan billing:install stable --quiet > /dev/null 2>&1
    fi
    
    # Build assets
    print_progress "Building assets (this may take 3-5 minutes)..."
    
    # Try yarn build:production with fallback to yarn build
    if yarn build:production --silent > /dev/null 2>&1; then
        print_success "Assets berhasil dibuild"
    else
        print_progress "Mencoba metode build alternatif..."
        yarn build --silent > /dev/null 2>&1
    fi
    
    # Clear cache
    print_progress "Clearing cache..."
    php artisan view:clear --quiet > /dev/null 2>&1
    php artisan config:clear --quiet > /dev/null 2>&1
    php artisan cache:clear --quiet > /dev/null 2>&1
    
    # Set permissions
    print_progress "Setting permissions..."
    chown -R www-data:www-data "$PTERODACTYL_DIR"
    chmod -R 755 "$PTERODACTYL_DIR/storage" "$PTERODACTYL_DIR/bootstrap/cache"
    
    print_success "Theme berhasil diaplikasikan!"
    return 0
}

# ================ CLEANUP ==============
cleanup_temp() {
    print_step "Membersihkan file temporary..."
    rm -rf "$TEMP_DIR" > /dev/null 2>&1
    print_success "Bersih!"
    sleep 1
}

# ================ CONFIGURE ENIGMA ==============
configure_enigma() {
    print_step "Konfigurasi Theme Enigma"
    echo ""
    
    echo -e "${YELLOW}Masukkan link WhatsApp (https://wa.me/...):${NC}"
    read -r LINK_WA
    
    echo -e "${YELLOW}Masukkan link Group:${NC}"
    read -r LINK_GROUP
    
    echo -e "${YELLOW}Masukkan link Channel:${NC}"
    read -r LINK_CHNL
    
    local dashboard_file="$TEMP_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx"
    
    # Try to find the file in different possible locations
    if [[ ! -f "$dashboard_file" ]]; then
        dashboard_file="$TEMP_DIR/pterodactyl/resources/scripts/components/dashboard/DashboardContainer.tsx"
    fi
    
    if [[ -f "$dashboard_file" ]]; then
        print_progress "Mengganti placeholder dengan nilai yang dimasukkan..."
        sed -i "s|LINK_WA|$LINK_WA|g" "$dashboard_file"
        sed -i "s|LINK_GROUP|$LINK_GROUP|g" "$dashboard_file"
        sed -i "s|LINK_CHNL|$LINK_CHNL|g" "$dashboard_file"
        print_success "Konfigurasi selesai"
    else
        print_error "File konfigurasi tidak ditemukan!"
        print_info "Melanjutkan tanpa konfigurasi..."
    fi
}

# ================ INSTALL THEME ==============
install_theme() {
    print_banner
    print_section "INSTALL THEME PTERODACTYL"
    
    # Check requirements
    check_root
    check_system
    check_pterodactyl
    
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
        1) theme_name="stellar"; theme_url="${THEME_URLS[0]##*|}" ;;
        2) theme_name="billing"; theme_url="${THEME_URLS[1]##*|}" ;;
        3) theme_name="enigma"; theme_url="${THEME_URLS[2]##*|}" ;;
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
        echo ""
        echo -n "Tekan Enter untuk kembali ke menu..."
        read
        return
    fi
    
    # Configure Enigma if selected
    if [[ "$theme_name" == "enigma" ]]; then
        configure_enigma
    fi
    
    if apply_theme "$theme_name"; then
        cleanup_temp
        
        echo ""
        print_success "✅ INSTALLASI SELESAI!"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "Theme $theme_name berhasil diinstall!"
        echo -e "Backup disimpan di /root/pterodactyl-backup-*"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Restart services
        print_step "Merestart services..."
        systemctl restart nginx php8.1-fpm 2>/dev/null || systemctl restart nginx php8.0-fpm 2>/dev/null
    else
        print_error "Installasi gagal!"
        print_info "Mengembalikan dari backup..."
        
        # Restore from backup
        latest_backup=$(ls -d /root/pterodactyl-backup-* 2>/dev/null | tail -1)
        if [ -n "$latest_backup" ]; then
            rm -rf "$PTERODACTYL_DIR"
            cp -rf "$latest_backup" "$PTERODACTYL_DIR"
            print_success "Backup dikembalikan"
        fi
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ UNINSTALL THEME ==============
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
        
        # Clear cache
        cd "$PTERODACTYL_DIR"
        php artisan view:clear
        php artisan config:clear
        
        # Restart services
        systemctl restart nginx php8.1-fpm 2>/dev/null || systemctl restart nginx php8.0-fpm 2>/dev/null
    else
        print_error "Gagal menguninstall theme!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ CONFIGURE WINGS ==============
configure_wings() {
    print_banner
    print_section "CONFIGURE WINGS"
    
    echo -e "${YELLOW}Masukkan token Wings:${NC}"
    read -r wings_token
    
    if [[ -z "$wings_token" ]]; then
        print_error "Token tidak boleh kosong!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    print_step "Menjalankan perintah Wings..."
    eval "$wings_token"
    
    if [ $? -eq 0 ]; then
        print_step "Menjalankan service Wings..."
        systemctl daemon-reload
        systemctl start wings
        systemctl enable wings > /dev/null 2>&1
        
        print_success "Wings berhasil dikonfigurasi dan dijalankan!"
    else
        print_error "Gagal mengkonfigurasi Wings"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ CREATE NODE ==============
create_node() {
    print_banner
    print_section "CREATE NODE & LOCATION"
    
    if [[ ! -d "$PTERODACTYL_DIR" ]]; then
        print_error "Pterodactyl tidak ditemukan!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    cd "$PTERODACTYL_DIR" || exit
    
    # Input location
    echo -e "${YELLOW}--- Informasi Location ---${NC}"
    echo -n "Nama Location: "
    read -r location_name
    echo -n "Deskripsi Location: "
    read -r location_desc
    echo -n "Short Code: "
    read -r short_code
    
    if [[ -z "$location_name" || -z "$short_code" ]]; then
        print_error "Nama dan Short Code wajib diisi!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    # Create location
    print_step "Membuat location baru..."
    php artisan p:location:make <<EOF
$location_name
$location_desc
$short_code
EOF
    
    # Get location ID
    location_id=$(php artisan tinker --execute="echo DB::table('locations')->orderBy('id', 'desc')->first()->id ?? '1';" 2>/dev/null | tail -n1)
    
    if [[ -z "$location_id" ]]; then
        location_id=1
    fi
    
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
    
    if [[ -z "$node_name" || -z "$domain" || -z "$ram" || -z "$disk" ]]; then
        print_error "Data node wajib diisi lengkap!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
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
    
    if [ $? -eq 0 ]; then
        print_success "Node dan Location berhasil dibuat!"
    else
        print_error "Gagal membuat node!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ UNINSTALL PANEL ==============
uninstall_panel() {
    print_banner
    print_section "UNINSTALL PANEL"
    
    echo -e "${RED}⚠️ PERINGATAN: Tindakan ini akan menghapus SELURUH PANEL beserta datanya!${NC}"
    echo -e "${YELLOW}Pastikan Anda sudah membackup data penting.${NC}"
    echo ""
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
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ HACKBACK PANEL ==============
hackback_panel() {
    print_banner
    print_section "CREATE ADMIN USER"
    
    if [[ ! -d "$PTERODACTYL_DIR" ]]; then
        print_error "Pterodactyl tidak ditemukan!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    cd "$PTERODACTYL_DIR" || exit
    
    echo -e "${YELLOW}Masukkan informasi admin baru:${NC}"
    echo ""
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
    
    if [[ -z "$username" || -z "$email" || -z "$password" ]]; then
        print_error "Username, Email, dan Password wajib diisi!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    print_step "Membuat user admin..."
    
    php artisan p:user:make <<EOF
yes
$email
$username
$first_name
$last_name
$password
EOF
    
    if [ $? -eq 0 ]; then
        print_success "User admin berhasil dibuat!"
    else
        print_error "Gagal membuat user admin!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ UBAH PASSWORD VPS ==============
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
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    if [[ ${#new_password} -lt 8 ]]; then
        print_error "Password minimal 8 karakter!"
        echo ""
        echo -n "Tekan Enter untuk kembali..."
        read
        return
    fi
    
    print_step "Mengubah password VPS..."
    
    echo "root:$new_password" | chpasswd
    
    if [[ $? -eq 0 ]]; then
        print_success "Password VPS berhasil diubah!"
    else
        print_error "Gagal mengubah password!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ CHECK NODE VERSION ==============
check_node_version() {
    print_banner
    print_section "CEK VERSI NODE.JS"
    
    if command -v node &> /dev/null; then
        node_version=$(node -v)
        npm_version=$(npm -v)
        
        echo -e "${GREEN}Node.js:${NC} $node_version"
        echo -e "${GREEN}NPM:${NC} $npm_version"
        
        if command -v yarn &> /dev/null; then
            yarn_version=$(yarn -v)
            echo -e "${GREEN}Yarn:${NC} $yarn_version"
        else
            echo -e "${RED}Yarn:${NC} Not installed"
        fi
    else
        print_error "Node.js tidak terinstall!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali..."
    read
}

# ================ RESTART WINGS ==============
restart_wings() {
    print_banner
    print_section "RESTART WINGS"
    
    if systemctl list-units --full -all | grep -Fq "wings.service"; then
        if systemctl is-active --quiet wings; then
            print_step "Merestart service wings..."
            systemctl restart wings
            sleep 2
            if systemctl is-active --quiet wings; then
                print_success "Wings berhasil direstart!"
            else
                print_error "Wings gagal direstart!"
            fi
        else
            print_step "Menjalankan service wings..."
            systemctl start wings
            sleep 2
            if systemctl is-active --quiet wings; then
                print_success "Wings berhasil dijalankan!"
            else
                print_error "Wings gagal dijalankan!"
            fi
        fi
    else
        print_error "Service wings tidak ditemukan!"
    fi
    
    echo ""
    echo -n "Tekan Enter untuk kembali ke menu..."
    read
}

# ================ CHECK SERVICES ==============
check_services() {
    print_banner
    print_section "CEK STATUS SERVICE"
    
    services=("nginx" "php8.1-fpm" "php8.0-fpm" "mysql" "mariadb" "redis-server" "wings")
    
    for service in "${services[@]}"; do
        if systemctl list-units --full -all | grep -Fq "$service.service"; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                echo -e "${GREEN}✅ $service: Running${NC}"
                systemctl status "$service" --no-pager | grep "Active:" | sed 's/^/     /'
            else
                echo -e "${RED}❌ $service: Stopped${NC}"
            fi
        fi
    done
    
    echo ""
    echo -n "Tekan Enter untuk kembali..."
    read
}

# ================ SHOW MENU ==============
show_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          AUTO INSTALLER THEMA PTERODACTYL v2.0          ║${NC}"
    echo -e "${BLUE}║                   © WINDAHOSTING 2025                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # ASCII Art Logo
    echo -e "${CYAN}        _,gggggggggg.                                     ${NC}"
    echo -e "${CYAN}    ,ggggggggggggggggg.                                   ${NC}"
    echo -e "${CYAN}  ,ggggg        gggggggg.                                 ${NC}"
    echo -e "${CYAN} ,ggg'               'ggg.                                ${NC}"
    echo -e "${CYAN}',gg       ,ggg.      'ggg:                               ${NC}"
    echo -e "${CYAN}'ggg      ,gg'''  .    ggg       Auto Installer WindaHosting${NC}"
    echo -e "${CYAN}gggg      gg     ,     ggg      ------------------------${NC}"
    echo -e "${CYAN}ggg:     gg.     -   ,ggg       • Telegram : @OsideGirl${NC}"
    echo -e "${CYAN} ggg:     ggg._    _,ggg        • Credits  : WINDAHOSTING${NC}"
    echo -e "${CYAN} ggg.    '.'''ggggggp           • Version   : v2.0.1${NC}"
    echo -e "${CYAN}  'ggg    '-.__                                           ${NC}"
    echo -e "${CYAN}    ggg                                                   ${NC}"
    echo -e "${CYAN}      ggg                                                 ${NC}"
    echo -e "${CYAN}        ggg.                                              ${NC}"
    echo -e "${CYAN}          ggg.                                            ${NC}"
    echo -e "${CYAN}             b.                                           ${NC}"
    echo ""
    echo -e "${BOLD}${WHITE}BERIKUT LIST INSTALL :${NC}"
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

# ================ MAIN FUNCTION ==============
main() {
    # Check root
    check_root
    
    # Display welcome and check token
    display_welcome
    check_token
    
    # Main menu loop
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
                echo -e "${GREEN}"
                echo "Terima kasih telah menggunakan script ini!"
                echo -e "${NC}"
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
