#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'  # Warna ungu untuk ASCII art RAIMAN
NC='\033[0m' # No Color

# Direktori asal
ORIGINAL_DIR=$(pwd)

# Fungsi untuk menampilkan header
print_header() {
    clear
    echo -e "${PURPLE}██████╗  █████╗ ██╗███╗   ███╗ █████╗ ███╗   ██╗${NC}"
    echo -e "${PURPLE}██╔══██╗██╔══██╗██║████╗ ████║██╔══██╗████╗  ██║${NC}"
    echo -e "${PURPLE}██████╔╝███████║██║██╔████╔██║███████║██╔██╗ ██║${NC}"
    echo -e "${PURPLE}██╔══██╗██╔══██║██║██║╚██╔╝██║██╔══██║██║╚██╗██║${NC}"
    echo -e "${PURPLE}██║  ██║██║  ██║██║██║ ╚═╝ ██║██║  ██║██║ ╚████║${NC}"
    echo -e "${PURPLE}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "${YELLOW}     NOCKCHAIN INSTALLER       ${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}Mining starts: May 19th, 2025${NC}"
    echo ""
}

# Fungsi untuk menampilkan informasi
show_info() {
    print_header
    echo -e "${YELLOW}INFORMASI NOCKCHAIN:${NC}"
    echo -e "• Mining dimulai: 19 Mei 2025"
    echo -e "• Total Supply: 2^32 nocks (sekitar 4,29 miliar)"
    echo -e "• Fair launch: 100% $NOCK akan diberikan kepada Miners"
    echo -e "• $NOCK digunakan untuk membayar blockspace di Nockchain"
    echo -e "• Block time: 10 menit (seperti Bitcoin)"
    echo ""
    echo -e "${YELLOW}REKOMENDASI HARDWARE:${NC}"
    echo -e "• RAM: 16 GB"
    echo -e "• CPU: 6 cores atau lebih (lebih banyak core = lebih banyak hashrate)"
    echo -e "• Disk: 50-200 GB SSD"
    echo ""
    echo -e "${YELLOW}CATATAN PENTING:${NC}"
    echo -e "• Miner awalnya berbasis CPU dan nantinya akan beralih ke GPU dan ASIC"
    echo -e "• Semakin awal mining, semakin BESAR rewards yang akan didapatkan"
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu utama"
}

# Fungsi untuk mengecek dependensi
check_dependencies() {
    print_header
    echo -e "${YELLOW}Mengecek dependensi sistem...${NC}"
    
    # Cek apakah git terinstall
    if command -v git >/dev/null 2>&1; then
        echo -e "✅ Git sudah terinstall"
    else
        echo -e "❌ Git belum terinstall"
        return 1
    fi
    
    # Cek apakah rust terinstall
    if command -v rustc >/dev/null 2>&1; then
        echo -e "✅ Rust sudah terinstall"
    else
        echo -e "❌ Rust belum terinstall"
        return 1
    fi
    
    # Cek apakah docker terinstall (opsional untuk Mainnet)
    if command -v docker >/dev/null 2>&1; then
        echo -e "✅ Docker sudah terinstall"
    else
        echo -e "⚠️ Docker belum terinstall (opsional untuk Mainnet)"
    fi
    
    return 0
}

# Fungsi untuk menginstall dependensi
install_dependencies() {
    print_header
    echo -e "${YELLOW}Menginstall dependensi...${NC}"
    
    echo -e "${GREEN}Step 1: Update Packages${NC}"
    echo -e "Menjalankan: sudo apt-get update && sudo apt-get upgrade -y"
    sudo apt-get update && sudo apt-get upgrade -y
    
    echo -e "\n${GREEN}Step 2: Install Packages${NC}"
    echo -e "Menjalankan: sudo apt install curl iptables build-essential git wget..."
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
    
    echo -e "\n${GREEN}Step 3: Install Rust${NC}"
    echo -e "Menjalankan: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source Rust environment setelah installasi
    echo -e "\n${GREEN}Sourcing Rust environment...${NC}"
    source "$HOME/.cargo/env"
    echo -e "Rust is installed now. Great! Rust environment has been sourced."
    echo -e "Paths have been configured. You can verify with 'rustc --version'"
    
    echo -e "\n${GREEN}Step 4: Install Docker (Opsional untuk Mainnet)${NC}"
    read -p "Apakah Anda ingin menginstall Docker? (y/n): " install_docker
    if [[ "$install_docker" == "y" || "$install_docker" == "Y" ]]; then
        echo -e "Menginstall Docker..."
        sudo apt update -y && sudo apt upgrade -y
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update -y && sudo apt upgrade -y

        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Test Docker
        echo -e "Testing Docker..."
        sudo docker run hello-world

        sudo systemctl enable docker
        sudo systemctl restart docker
    fi
    
    echo -e "\n${GREEN}Semua dependensi berhasil diinstall!${NC}"
    read -p "Tekan ENTER untuk kembali ke menu utama"
}

# Fungsi untuk menginstall Nockchain
install_nockchain() {
    print_header
    echo -e "${YELLOW}Memulai installasi Nockchain...${NC}"
    
    # Cek apakah dependensi sudah terpenuhi
    if ! check_dependencies; then
        echo -e "${RED}Beberapa dependensi belum terinstall. Install dependensi terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu utama"
        return
    fi
    
    # Source Rust environment untuk memastikan cargo tersedia
    source "$HOME/.cargo/env"
    
    echo -e "${GREEN}Step 1: Clone NockChain Repo${NC}"
    if [ -d "nockchain" ]; then
        echo -e "Direktori nockchain sudah ada. Masuk ke direktori..."
        cd nockchain
    else
        echo -e "Menjalankan: git clone https://github.com/zorp-corp/nockchain"
        git clone https://github.com/zorp-corp/nockchain
        cd nockchain
    fi
    
    echo -e "\n${GREEN}Step 2: Install Choo (Jock/Hoon Compiler)${NC}"
    echo -e "Menjalankan: make install-choo"
    make install-choo
    
    echo -e "\n${GREEN}Step 3: Build (Proses ini mungkin memakan waktu lebih dari 15 menit)${NC}"
    echo -e "Menjalankan: make build-hoon-all"
    make build-hoon-all
    
    echo -e "Menjalankan: make build"
    make build
    
    echo -e "\n${GREEN}Nockchain berhasil diinstall!${NC}"
    read -p "Tekan ENTER untuk kembali ke menu utama"
}

# Fungsi untuk membuat wallet
setup_wallet() {
    print_header
    echo -e "${YELLOW}Membuat wallet Nockchain...${NC}"
    
    # Pastikan kita berada di direktori nockchain
    if [ ! -d "nockchain" ]; then
        echo -e "${RED}Direktori nockchain tidak ditemukan. Install Nockchain terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu utama"
        return
    fi
    
    cd nockchain
    
    # Source Rust environment untuk memastikan wallet command tersedia
    source "$HOME/.cargo/env"
    
    echo -e "${GREEN}Step 1: Set PATH${NC}"
    echo -e "Menjalankan: export PATH=\"\$PATH:\$(pwd)/target/release\""
    export PATH="$PATH:$(pwd)/target/release"
    
    echo -e "\n${GREEN}Step 2: Create wallet${NC}"
    echo -e "Menjalankan: wallet keygen"
    echo -e "${RED}PENTING: SIMPAN memo, private key & public key wallet Anda!${NC}"
    read -p "Tekan ENTER untuk membuat wallet"
    
    wallet_output=$(wallet keygen)
    echo -e "$wallet_output"
    
    # Ekstrak public key dari output
    pubkey=$(echo "$wallet_output" | grep -o "Public key: [^ ]*" | cut -d' ' -f3)
    
    echo -e "\n${YELLOW}Public key Anda: ${GREEN}$pubkey${NC}"
    echo -e "${RED}SIMPAN INFORMASI INI DI TEMPAT YANG AMAN!${NC}"
    
    # Tanyakan apakah ingin mengkonfigurasi Makefile secara otomatis
    echo ""
    read -p "Apakah Anda ingin mengkonfigurasi Makefile dengan public key ini? (y/n): " configure_makefile
    
    if [[ "$configure_makefile" == "y" || "$configure_makefile" == "Y" ]]; then
        echo -e "\n${GREEN}Mengkonfigurasi Makefile...${NC}"
        # Backup Makefile asli
        cp Makefile Makefile.backup
        
        # Update public key di Makefile
        sed -i "s/MINING_PUBKEY := .*/MINING_PUBKEY := $pubkey/" Makefile
        
        echo -e "Makefile berhasil dikonfigurasi dengan public key Anda."
    fi
    
    read -p "Tekan ENTER untuk kembali ke menu utama"
}

# Fungsi untuk menjalankan node
run_nodes() {
    print_header
    echo -e "${YELLOW}Menu Menjalankan Node:${NC}"
    echo -e "1. Run Leader Node (Testnet Node)"
    echo -e "2. Run Follower Node (Miner Node)"
    echo -e "3. Cek Status Node"
    echo -e "4. Cek Balance Wallet"
    echo -e "5. Kembali ke Menu Utama"
    echo ""
    read -p "Pilih opsi: " node_option
    
    case $node_option in
        1)
            run_leader_node
            ;;
        2)
            run_follower_node
            ;;
        3)
            check_node_status
            ;;
        4)
            check_wallet_balance
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}Opsi tidak valid!${NC}"
            sleep 2
            run_nodes
            ;;
    esac
}

# Fungsi untuk menjalankan leader node
run_leader_node() {
    print_header
    echo -e "${YELLOW}Menjalankan Leader Node...${NC}"
    
    # Pastikan kita berada di direktori nockchain
    cd nockchain 2>/dev/null || { 
        echo -e "${RED}Direktori nockchain tidak ditemukan. Install Nockchain terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu"
        run_nodes
        return
    }
    
    # Source Rust environment
    source "$HOME/.cargo/env"
    
    echo -e "${GREEN}Memulai Leader Node dalam screen...${NC}"
    echo -e "${YELLOW}Untuk melihat log: ${GREEN}screen -r leader${NC}"
    echo -e "${YELLOW}Untuk keluar dari screen: ${GREEN}Ctrl+A+D${NC}"
    
    # Cek apakah screen leader sudah ada
    if screen -list | grep -q "leader"; then
        echo -e "${YELLOW}Screen leader sudah berjalan. Menghentikan screen yang lama...${NC}"
        screen -XS leader quit
    fi
    
    # Jalankan leader node dalam screen baru
    screen -dmS leader bash -c "cd $(pwd) && source $HOME/.cargo/env && make run-nockchain-leader; exec bash"
    
    echo -e "${GREEN}Leader Node berhasil dijalankan dalam screen dengan nama 'leader'${NC}"
    read -p "Tekan ENTER untuk kembali ke menu"
    run_nodes
}

# Fungsi untuk menjalankan follower node
run_follower_node() {
    print_header
    echo -e "${YELLOW}Menjalankan Follower Node...${NC}"
    
    # Pastikan kita berada di direktori nockchain
    cd nockchain 2>/dev/null || { 
        echo -e "${RED}Direktori nockchain tidak ditemukan. Install Nockchain terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu"
        run_nodes
        return
    }
    
    # Source Rust environment
    source "$HOME/.cargo/env"
    
    # Periksa apakah leader node sudah berjalan
    if ! screen -list | grep -q "leader"; then
        echo -e "${RED}Leader Node belum dijalankan. Jalankan Leader Node terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu"
        run_nodes
        return
    fi
    
    echo -e "${GREEN}Memulai Follower Node dalam screen...${NC}"
    echo -e "${YELLOW}Untuk melihat log: ${GREEN}screen -r follower${NC}"
    echo -e "${YELLOW}Untuk keluar dari screen: ${GREEN}Ctrl+A+D${NC}"
    
    # Cek apakah screen follower sudah ada
    if screen -list | grep -q "follower"; then
        echo -e "${YELLOW}Screen follower sudah berjalan. Menghentikan screen yang lama...${NC}"
        screen -XS follower quit
    fi
    
    # Jalankan follower node dalam screen baru
    screen -dmS follower bash -c "cd $(pwd) && source $HOME/.cargo/env && make run-nockchain-follower; exec bash"
    
    echo -e "${GREEN}Follower Node berhasil dijalankan dalam screen dengan nama 'follower'${NC}"
    read -p "Tekan ENTER untuk kembali ke menu"
    run_nodes
}

# Fungsi untuk mengecek status node
check_node_status() {
    print_header
    echo -e "${YELLOW}Status Node:${NC}"
    
    # Cek screen yang berjalan
    screen_output=$(screen -list)
    
    echo -e "${GREEN}Daftar Screen yang Berjalan:${NC}"
    echo -e "$screen_output"
    echo ""
    
    # Cek status leader node
    if echo "$screen_output" | grep -q "leader"; then
        echo -e "Leader Node: ${GREEN}RUNNING${NC}"
    else
        echo -e "Leader Node: ${RED}STOPPED${NC}"
    fi
    
    # Cek status follower node
    if echo "$screen_output" | grep -q "follower"; then
        echo -e "Follower Node: ${GREEN}RUNNING${NC}"
    else
        echo -e "Follower Node: ${RED}STOPPED${NC}"
    fi
    
    read -p "Tekan ENTER untuk kembali ke menu"
    run_nodes
}

# Fungsi untuk mengecek balance wallet
check_wallet_balance() {
    print_header
    echo -e "${YELLOW}Mengecek Balance Wallet...${NC}"
    
    # Pastikan kita berada di direktori nockchain
    cd nockchain 2>/dev/null || { 
        echo -e "${RED}Direktori nockchain tidak ditemukan. Install Nockchain terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu"
        run_nodes
        return
    }
    
    # Source Rust environment
    source "$HOME/.cargo/env"
    
    # Set PATH
    export PATH="$PATH:$(pwd)/target/release"
    
    # Periksa apakah leader node sudah berjalan
    if ! screen -list | grep -q "leader"; then
        echo -e "${RED}Leader Node belum dijalankan. Jalankan Leader Node terlebih dahulu.${NC}"
        read -p "Tekan ENTER untuk kembali ke menu"
        run_nodes
        return
    fi
    
    echo -e "Menjalankan: wallet --nockchain-socket ./test-leader/nockchain.sock balance"
    wallet_balance=$(wallet --nockchain-socket ./test-leader/nockchain.sock balance 2>&1)
    
    echo -e "\n${GREEN}Balance Wallet:${NC}"
    echo -e "$wallet_balance"
    echo -e "\nCatatan: ~ berarti 0, balance akan 0 sampai Anda berhasil mine block."
    
    read -p "Tekan ENTER untuk kembali ke menu"
    run_nodes
}

# Menu utama
main_menu() {
    while true; do
        print_header
        echo -e "${YELLOW}MENU UTAMA:${NC}"
        echo -e "1. Informasi Nockchain"
        echo -e "2. Cek Dependensi"
        echo -e "3. Install Dependensi"
        echo -e "4. Install Nockchain"
        echo -e "5. Setup Wallet"
        echo -e "6. Jalankan/Kelola Node"
        echo -e "7. Keluar"
        echo ""
        read -p "Pilih opsi: " option
        
        case $option in
            1)
                show_info
                ;;
            2)
                check_dependencies
                read -p "Tekan ENTER untuk kembali ke menu utama"
                ;;
            3)
                install_dependencies
                ;;
            4)
                install_nockchain
                ;;
            5)
                setup_wallet
                ;;
            6)
                run_nodes
                ;;
            7)
                echo -e "${GREEN}Terima kasih telah menggunakan Nockchain Installer!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opsi tidak valid!${NC}"
                sleep 2
                ;;
        esac
    done
}

# Mulai program
main_menu
