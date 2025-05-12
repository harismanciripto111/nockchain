#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art
show_ascii_art() {
cat << "EOF"
    _   __           __        __          _     
   / | / /___  _____/ /_______/ /_  ____ _(_)___ 
  /  |/ / __ \/ ___/ //_/ ___/ __ \/ __ `/ / __ \
 / /|  / /_/ / /__/ ,< / /__/ / / / /_/ / / / / /
/_/ |_/\____/\___/_/|_|\___/_/ /_/\__,_/_/_/ /_/ 
                                                  
  ZK-Proof of Work Mining Setup
EOF
}

# Check if Nockchain is already installed
check_nockchain_installed() {
  # Check if wallet and nockchain binaries exist
  if [ -f "target/release/wallet" ] && [ -f "target/release/nockchain" ]; then
    return 0  # Installed
  else
    return 1  # Not installed
  fi
}

# Check dependencies
# Check if the script is executed from the nockchain directory
check_directory() {
  if [ ! -f "Makefile" ] || [ ! -d ".git" ]; then
    echo -e "${RED}Error: This script must be run from the nockchain repository root directory.${NC}"
    echo -e "${YELLOW}Please navigate to the nockchain directory first.${NC}"
    echo -e "${CYAN}Current directory: $(pwd)${NC}"
    echo -e "${YELLOW}Would you like to:${NC}"
    echo -e "${CYAN}1.${NC} Navigate to a different directory"
    echo -e "${CYAN}2.${NC} Clone nockchain repository here"
    echo -e "${CYAN}3.${NC} Return to main menu"
    
    read -p "Enter your choice [1-3]: " choice
    
    case $choice in
      1)
        read -p "Enter the path to nockchain directory: " nockpath
        if [ -d "$nockpath" ]; then
          cd "$nockpath"
          if [ -f "Makefile" ] && [ -d ".git" ]; then
            echo -e "${GREEN}Successfully changed to nockchain directory.${NC}"
            return 0
          else
            echo -e "${RED}The specified directory does not appear to be a nockchain repository.${NC}"
            sleep 2
            return 1
          fi
        else
          echo -e "${RED}Directory does not exist.${NC}"
          sleep 2
          return 1
        fi
        ;;
      2)
        echo -e "${YELLOW}Cloning nockchain repository...${NC}"
        git clone https://github.com/zorp-corp/nockchain
        if [ $? -eq 0 ]; then
          echo -e "${GREEN}Repository cloned successfully!${NC}"
          cd nockchain
          return 0
        else
          echo -e "${RED}Failed to clone repository.${NC}"
          sleep 2
          return 1
        fi
        ;;
      3)
        return 1
        ;;
      *)
        echo -e "${RED}Invalid option.${NC}"
        sleep 2
        return 1
        ;;
    esac
  fi
  return 0
}

# Set necessary environment variables
set_environment() {
  echo -e "${BLUE}Setting environment variables...${NC}"
  
  # Check if target/release exists
  if [ ! -d "target/release" ]; then
    echo -e "${YELLOW}Warning: target/release directory does not exist.${NC}"
    echo -e "${YELLOW}This usually means Nockchain hasn't been built yet.${NC}"
    
    # Still set the path for future use
    export PATH="$PATH:$(pwd)/target/release"
    echo -e "${YELLOW}PATH set, but build may be required for commands to work.${NC}"
    return
  fi
  
  # Set Cargo environment if available
  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
    echo -e "${GREEN}Cargo environment loaded.${NC}"
  fi
  
  # Add target/release to PATH
  export PATH="$PATH:$(pwd)/target/release"
  
  echo -e "${GREEN}Environment variables set successfully!${NC}"
  echo -e "${YELLOW}PATH now includes: $(pwd)/target/release${NC}"
  echo -e "${CYAN}To make this permanent, add to your .bashrc:${NC}"
  echo -e "echo 'export PATH=\"\$PATH:$(pwd)/target/release\"' >> ~/.bashrc"
}

# Display wallet status if available
check_wallet_status() {
  if command -v wallet &> /dev/null; then
    echo -e "${CYAN}Checking wallet status...${NC}"
    wallet --nockchain-socket ./test-leader/nockchain.sock balance 2>/dev/null
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW}Wallet exists but cannot connect to nockchain socket.${NC}"
      echo -e "${YELLOW}Is your leader node running?${NC}"
    fi
  else
    echo -e "${YELLOW}Wallet command not found. You need to build Nockchain first.${NC}"
  fi
}

# Check if screens are running
check_screens() {
  leader_screen=$(screen -ls | grep leader)
  follower_screen=$(screen -ls | grep follower)
  
  echo -e "${CYAN}===== NODE STATUS =====${NC}"
  if [[ -n "$leader_screen" ]]; then
    echo -e "${GREEN}Leader node is running.${NC}"
  else
    echo -e "${RED}Leader node is NOT running.${NC}"
  fi
  
  if [[ -n "$follower_screen" ]]; then
    echo -e "${GREEN}Follower node (miner) is running.${NC}"
  else
    echo -e "${RED}Follower node (miner) is NOT running.${NC}"
  fi
}

# Install dependencies
install_dependencies() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== INSTALLING DEPENDENCIES =====${NC}"
  
  echo -e "${YELLOW}Updating packages...${NC}"
  sudo apt-get update && sudo apt-get upgrade -y
  
  echo -e "${YELLOW}Installing required packages...${NC}"
  sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
  
  echo -e "${YELLOW}Installing Rust...${NC}"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  source $HOME/.cargo/env
  
  echo -e "${YELLOW}Installing Docker...${NC}"
  sudo apt update -y && sudo apt upgrade -y
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
  
  sudo apt-get update
  sudo apt-get install ca-certificates curl gnupg -y
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  sudo apt update -y && sudo apt upgrade -y
  
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  
  echo -e "${YELLOW}Testing Docker...${NC}"
  sudo docker run hello-world
  
  sudo systemctl enable docker
  sudo systemctl restart docker
  
  echo -e "${GREEN}Dependencies installed successfully!${NC}"
  echo -e "${YELLOW}IMPORTANT: To ensure PATH is correctly set, please run:${NC}"
  echo -e "${CYAN}source \$HOME/.cargo/env${NC}"
  
  # Automatically set the PATH
  set_environment
  
  read -p "Press Enter to continue..."
  main_menu
}

# Clone repository
clone_repository() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== CLONING NOCKCHAIN REPOSITORY =====${NC}"
  
  # Check if we are already in a nockchain directory
  if [ -d ".git" ] && grep -q "nockchain" .git/config 2>/dev/null; then
    echo -e "${YELLOW}You appear to already be in a nockchain repository.${NC}"
    read -p "Do you want to re-clone the repository? (y/n): " answer
    if [[ "$answer" != "y" ]]; then
      main_menu
      return
    fi
    # If yes, move up one directory
    cd ..
  fi
  
  git clone https://github.com/zorp-corp/nockchain
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Repository cloned successfully!${NC}"
    cd nockchain
    
    # Set environment after changing directory
    set_environment
  else
    echo -e "${RED}Failed to clone repository.${NC}"
  fi
  
  read -p "Press Enter to continue..."
  main_menu
}

# Install Choo
install_choo() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== INSTALLING CHOO (JOCK/HOON COMPILER) =====${NC}"
  
  check_directory
  
  make install-choo
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Choo installed successfully!${NC}"
  else
    echo -e "${RED}Failed to install Choo.${NC}"
  fi
  
  read -p "Press Enter to continue..."
  main_menu
}

# Build Nockchain
build_nockchain() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== BUILDING NOCKCHAIN =====${NC}"
  
  if ! check_directory; then
    read -p "Press Enter to continue..."
    main_menu
    return
  fi
  
  # Check if Rust is installed
  if ! command -v rustc &> /dev/null; then
    echo -e "${RED}Rust is not installed or not in PATH.${NC}"
    echo -e "${YELLOW}Would you like to install Rust now? (y/n): ${NC}"
    read -p "" answer
    if [[ "$answer" == "y" ]]; then
      echo -e "${YELLOW}Installing Rust...${NC}"
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
      source $HOME/.cargo/env
    else
      echo -e "${RED}Cannot build without Rust installed.${NC}"
      read -p "Press Enter to continue..."
      main_menu
      return
    fi
  fi
  
  # Ensure Choo is installed
  if [ ! -f "choo" ]; then
    echo -e "${YELLOW}Choo compiler not found. Installing Choo first...${NC}"
    make install-choo
    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to install Choo. Cannot continue with build.${NC}"
      read -p "Press Enter to continue..."
      main_menu
      return
    fi
  fi
  
  echo -e "${YELLOW}Building Hoon components (this may take 15+ minutes)...${NC}"
  make build-hoon-all
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Hoon components.${NC}"
    echo -e "${YELLOW}Would you like to continue with Rust components anyway? (y/n): ${NC}"
    read -p "" answer
    if [[ "$answer" != "y" ]]; then
      read -p "Press Enter to continue..."
      main_menu
      return
    fi
  fi
  
  echo -e "${YELLOW}Building Rust components...${NC}"
  make build
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Nockchain built successfully!${NC}"
    
    # Verify the build produced the expected files
    if [ -f "target/release/wallet" ] && [ -f "target/release/nockchain" ]; then
      echo -e "${GREEN}Build verification passed. Required binaries found.${NC}"
    else
      echo -e "${YELLOW}Warning: Expected binaries not found in target/release. The build may not be complete.${NC}"
    fi
    
    # Set environment after build
    set_environment
    
    # Create a file to remember that the build was completed
    touch .build_completed
  else
    echo -e "${RED}Failed to build Nockchain.${NC}"
    echo -e "${YELLOW}Common build issues:${NC}"
    echo -e "1. Insufficient memory (need at least 4GB RAM)"
    echo -e "2. Missing dependencies"
    echo -e "3. Disk space issues"
  fi
  
  read -p "Press Enter to continue..."
  main_menu
}

# Setup wallet
setup_wallet() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== WALLET SETUP =====${NC}"
  
  if ! check_directory; then
    read -p "Press Enter to continue..."
    main_menu
    return
  fi
  
  # Set environment to ensure wallet command is available
  set_environment
  
  # Check if wallet command is available
  if ! command -v wallet &> /dev/null; then
    echo -e "${RED}Error: 'wallet' command not found.${NC}"
    echo -e "${YELLOW}Make sure you have built Nockchain first.${NC}"
    echo -e "${YELLOW}Would you like to try building Nockchain now? (y/n): ${NC}"
    read -p "" answer
    if [[ "$answer" == "y" ]]; then
      build_nockchain
      return
    else
      read -p "Press Enter to continue..."
      main_menu
      return
    fi
  fi
  
  echo -e "${YELLOW}Generating wallet keys...${NC}"
  wallet keygen
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Wallet setup complete!${NC}"
    echo -e "${YELLOW}IMPORTANT: Save your memo, private key & public key shown above!${NC}"
    echo -e "${YELLOW}After any terminal restart, run these commands before using wallet:${NC}"
    echo -e "${CYAN}cd $(pwd)${NC}"
    echo -e "${CYAN}export PATH=\"\$PATH:$(pwd)/target/release\"${NC}"
  else
    echo -e "${RED}Error generating wallet keys.${NC}"
    echo -e "${YELLOW}This could be due to target/release directory not being created yet.${NC}"
    echo -e "${YELLOW}Make sure you've completed the build step before setting up the wallet.${NC}"
  fi
  
  read -p "Press Enter to continue..."
  wallet_menu
}

# Configure nodes
configure_nodes() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== CONFIGURE NODES =====${NC}"
  
  check_directory
  
  echo -e "${YELLOW}Current Makefile configuration:${NC}"
  grep "MINING_PUBKEY" Makefile
  echo ""
  
  read -p "Enter your wallet public key: " pubkey
  
  if [[ -n "$pubkey" ]]; then
    # Create a backup of the original Makefile
    cp Makefile Makefile.bak
    
    # Use sed to replace the MINING_PUBKEY value
    sed -i "s/MINING_PUBKEY=.*/MINING_PUBKEY=$pubkey/" Makefile
    
    echo -e "${GREEN}Nodes configured successfully!${NC}"
    echo -e "${YELLOW}Your mining public key has been set to: ${pubkey}${NC}"
  else
    echo -e "${RED}No public key provided. Nodes configuration unchanged.${NC}"
  fi
  
  read -p "Press Enter to continue..."
  main_menu
}

# Run leader node
run_leader_node() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== RUN LEADER NODE =====${NC}"
  
  check_directory
  
  # Check if screen is already running
  if screen -ls | grep -q leader; then
    echo -e "${YELLOW}Leader node screen is already running.${NC}"
    read -p "Do you want to reconnect to it? (y/n): " answer
    if [[ "$answer" == "y" ]]; then
      screen -r leader
      main_menu
      return
    else
      read -p "Do you want to stop the current leader node and start a new one? (y/n): " answer
      if [[ "$answer" == "y" ]]; then
        screen -S leader -X quit
      else
        main_menu
        return
      fi
    fi
  fi
  
  echo -e "${YELLOW}Starting leader node in a new screen session...${NC}"
  echo -e "${YELLOW}To detach from the screen: Press Ctrl+A then D${NC}"
  echo -e "${YELLOW}Starting in 3 seconds...${NC}"
  sleep 3
  
  # Set environment before starting node
  set_environment
  
  screen -dmS leader bash -c "cd $(pwd) && make run-nockchain-leader; exec bash"
  
  echo -e "${GREEN}Leader node started in screen session 'leader'${NC}"
  echo -e "${YELLOW}To view the node logs later, run: screen -r leader${NC}"
  
  read -p "Press Enter to continue..."
  main_menu
}

# Run follower node
run_follower_node() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== RUN FOLLOWER NODE (MINER) =====${NC}"
  
  check_directory
  
  # Check if leader is running first
  if ! screen -ls | grep -q leader; then
    echo -e "${RED}Leader node does not appear to be running.${NC}"
    echo -e "${YELLOW}It is recommended to start the leader node first.${NC}"
    read -p "Do you want to continue anyway? (y/n): " answer
    if [[ "$answer" != "y" ]]; then
      main_menu
      return
    fi
  fi
  
  # Check if screen is already running
  if screen -ls | grep -q follower; then
    echo -e "${YELLOW}Follower node screen is already running.${NC}"
    read -p "Do you want to reconnect to it? (y/n): " answer
    if [[ "$answer" == "y" ]]; then
      screen -r follower
      main_menu
      return
    else
      read -p "Do you want to stop the current follower node and start a new one? (y/n): " answer
      if [[ "$answer" == "y" ]]; then
        screen -S follower -X quit
      else
        main_menu
        return
      fi
    fi
  fi
  
  echo -e "${YELLOW}Starting follower node (miner) in a new screen session...${NC}"
  echo -e "${YELLOW}To detach from the screen: Press Ctrl+A then D${NC}"
  echo -e "${YELLOW}Starting in 3 seconds...${NC}"
  sleep 3
  
  # Set environment before starting node
  set_environment
  
  screen -dmS follower bash -c "cd $(pwd) && make run-nockchain-follower; exec bash"
  
  echo -e "${GREEN}Follower node started in screen session 'follower'${NC}"
  echo -e "${YELLOW}To view the node logs later, run: screen -r follower${NC}"
  
  read -p "Press Enter to continue..."
  main_menu
}

# Check nodes status
check_nodes_status() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== NODES STATUS =====${NC}"
  
  check_screens
  
  echo -e "\n${CYAN}Wallet Status:${NC}"
  check_wallet_status
  
  read -p "Press Enter to continue..."
  main_menu
}

# Wallet menu
wallet_menu() {
  clear
  show_ascii_art
  
  echo -e "${CYAN}===== NOCKCHAIN WALLET MENU =====${NC}"
  echo -e "${YELLOW}Current directory: $(pwd)${NC}"
  check_wallet_status
  
  echo ""
  echo -e "${CYAN}1.${NC} Generate New Key Pair"
  echo -e "${CYAN}2.${NC} Check Wallet Balance"
  echo -e "${CYAN}3.${NC} List All Notes"
  echo -e "${CYAN}4.${NC} Import Private Key"
  echo -e "${CYAN}5.${NC} Generate Master Key from Seed Phrase"
  echo -e "${CYAN}6.${NC} Create Transaction Draft"
  echo -e "${CYAN}7.${NC} Make and Sign Transaction"
  echo -e "${CYAN}8.${NC} Advanced Wallet Commands"
  echo -e "${CYAN}9.${NC} Return to Main Menu"
  echo ""
  
  read -p "Enter your choice [1-9]: " choice
  
  case $choice in
    1)
      clear
      show_ascii_art
      echo -e "${CYAN}===== GENERATE NEW KEY PAIR =====${NC}"
      set_environment
      wallet keygen
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    2)
      clear
      show_ascii_art
      echo -e "${CYAN}===== CHECK WALLET BALANCE =====${NC}"
      set_environment
      wallet --nockchain-socket ./test-leader/nockchain.sock balance
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    3)
      clear
      show_ascii_art
      echo -e "${CYAN}===== LIST ALL NOTES =====${NC}"
      set_environment
      wallet list-notes
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    4)
      clear
      show_ascii_art
      echo -e "${CYAN}===== IMPORT PRIVATE KEY =====${NC}"
      set_environment
      read -p "Enter path to keys.jam file: " keypath
      if [[ -n "$keypath" ]]; then
        wallet import-keys --input "$keypath"
      else
        echo -e "${RED}No file path provided.${NC}"
      fi
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    5)
      clear
      show_ascii_art
      echo -e "${CYAN}===== GENERATE MASTER KEY FROM SEED PHRASE =====${NC}"
      set_environment
      read -p "Enter your seed phrase: " seedphrase
      if [[ -n "$seedphrase" ]]; then
        wallet gen-master-privkey --seedphrase "$seedphrase"
      else
        echo -e "${RED}No seed phrase provided.${NC}"
      fi
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    6)
      clear
      show_ascii_art
      echo -e "${CYAN}===== CREATE TRANSACTION DRAFT =====${NC}"
      set_environment
      echo -e "${YELLOW}This will create a simple transaction draft.${NC}"
      read -p "Enter recipient public key: " recipient
      read -p "Enter amount to send: " amount
      read -p "Enter transaction fee: " fee
      
      if [[ -n "$recipient" && -n "$amount" ]]; then
        wallet simple-spend \
          --recipients "[$amount $recipient]" \
          --gifts "$amount" \
          --fee "${fee:-10}"
      else
        echo -e "${RED}Missing required information.${NC}"
      fi
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    7)
      clear
      show_ascii_art
      echo -e "${CYAN}===== MAKE AND SIGN TRANSACTION =====${NC}"
      set_environment
      
      echo -e "${YELLOW}Available drafts:${NC}"
      ls -la ./drafts/ 2>/dev/null
      
      read -p "Enter draft filename: " draftname
      if [[ -n "$draftname" ]]; then
        echo -e "${YELLOW}Signing transaction...${NC}"
        wallet sign-tx --draft "./drafts/$draftname"
        
        echo -e "${YELLOW}Making and broadcasting transaction...${NC}"
        wallet make-tx --draft "./drafts/$draftname"
      else
        echo -e "${RED}No draft filename provided.${NC}"
      fi
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    8)
      clear
      show_ascii_art
      echo -e "${CYAN}===== ADVANCED WALLET COMMANDS =====${NC}"
      
      echo -e "${YELLOW}Enter a custom wallet command to execute:${NC}"
      echo -e "${CYAN}Example: wallet --nockchain-socket ./test-leader/nockchain.sock list-notes-by-pubkey --pubkey <public-key>${NC}"
      
      read -p "Command: " cmd
      
      if [[ -n "$cmd" ]]; then
        set_environment
        eval "$cmd"
      else
        echo -e "${RED}No command provided.${NC}"
      fi
      
      read -p "Press Enter to continue..."
      wallet_menu
      ;;
    9)
      main_menu
      ;;
    *)
      echo -e "${RED}Invalid option. Please try again.${NC}"
      sleep 2
      wallet_menu
      ;;
  esac
}

# Main menu
main_menu() {
  clear
  show_ascii_art
  
  echo -e "${CYAN}===== NOCKCHAIN SETUP INTERFACE =====${NC}"
  echo -e "${YELLOW}Current directory: $(pwd)${NC}"
  check_screens
  
  echo ""
  echo -e "${CYAN}1.${NC} Install Dependencies"
  echo -e "${CYAN}2.${NC} Clone Nockchain Repository"
  echo -e "${CYAN}3.${NC} Install Choo (Jock/Hoon Compiler)"
  echo -e "${CYAN}4.${NC} Build Nockchain"
  echo -e "${CYAN}5.${NC} Setup Wallet"
  echo -e "${CYAN}6.${NC} Configure Nodes"
  echo -e "${CYAN}7.${NC} Run Leader Node"
  echo -e "${CYAN}8.${NC} Run Follower Node (Miner)"
  echo -e "${CYAN}9.${NC} Check Nodes Status"
  echo -e "${CYAN}10.${NC} Wallet Management"
  echo -e "${CYAN}11.${NC} Exit"
  echo ""
  
  read -p "Enter your choice [1-11]: " choice
  
  case $choice in
    1) install_dependencies ;;
    2) clone_repository ;;
    3) install_choo ;;
    4) build_nockchain ;;
    5) setup_wallet ;;
    6) configure_nodes ;;
    7) run_leader_node ;;
    8) run_follower_node ;;
    9) check_nodes_status ;;
    10) wallet_menu ;;
    11) 
      clear
      show_ascii_art
      echo -e "${GREEN}Thank you for using the Nockchain Setup Interface!${NC}"
      echo -e "${YELLOW}Exiting...${NC}"
      exit 0
      ;;
    *) 
      echo -e "${RED}Invalid option. Please try again.${NC}"
      sleep 2
      main_menu
      ;;
  esac
}

# Function to check for nockchain installation and initialize if needed
initialize_script() {
  clear
  show_ascii_art
  echo -e "${CYAN}===== NOCKCHAIN SETUP WIZARD =====${NC}"
  
  # Check if we're in a nockchain directory
  if [ -f "Makefile" ] && [ -d ".git" ] && grep -q "nockchain" .git/config 2>/dev/null; then
    echo -e "${GREEN}Detected Nockchain repository at: $(pwd)${NC}"
    
    # Check if Nockchain is already built
    if check_nockchain_installed; then
      echo -e "${GREEN}Nockchain appears to be already installed!${NC}"
      echo -e "${YELLOW}Found binaries in target/release directory.${NC}"
    else
      echo -e "${YELLOW}Nockchain repository found but not fully built yet.${NC}"
      echo -e "${YELLOW}You'll need to build Nockchain before using it.${NC}"
    fi
    
    read -p "Press Enter to continue to main menu..."
    main_menu
    return
  fi
  
  echo -e "${YELLOW}Nockchain repository not detected in the current directory.${NC}"
  echo -e "${CYAN}Current directory: $(pwd)${NC}"
  echo -e "${YELLOW}How would you like to proceed?${NC}"
  echo -e "${CYAN}1.${NC} Find existing Nockchain directory"
  echo -e "${CYAN}2.${NC} Clone Nockchain repository here"
  echo -e "${CYAN}3.${NC} Continue to main menu anyway"
  
  read -p "Enter your choice [1-3]: " choice
  
  case $choice in
    1)
      read -p "Enter the path to existing Nockchain directory: " nockpath
      if [ -d "$nockpath" ]; then
        cd "$nockpath"
        if [ -f "Makefile" ] && [ -d ".git" ]; then
          echo -e "${GREEN}Successfully changed to Nockchain directory.${NC}"
          # Check if already built
          if check_nockchain_installed; then
            echo -e "${GREEN}Nockchain appears to be already installed!${NC}"
          else
            echo -e "${YELLOW}Nockchain repository found but not fully built yet.${NC}"
          fi
          read -p "Press Enter to continue..."
          main_menu
        else
          echo -e "${RED}The specified directory does not appear to be a Nockchain repository.${NC}"
          read -p "Press Enter to continue anyway..."
          main_menu
        fi
      else
        echo -e "${RED}Directory does not exist.${NC}"
        read -p "Press Enter to continue to main menu..."
        main_menu
      fi
      ;;
    2)
      echo -e "${YELLOW}Cloning Nockchain repository...${NC}"
      git clone https://github.com/zorp-corp/nockchain
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}Repository cloned successfully!${NC}"
        cd nockchain
        read -p "Press Enter to continue..."
        main_menu
      else
        echo -e "${RED}Failed to clone repository.${NC}"
        read -p "Press Enter to continue to main menu..."
        main_menu
      fi
      ;;
    3)
      echo -e "${YELLOW}Continuing to main menu without Nockchain repository...${NC}"
      echo -e "${YELLOW}Some functions may not work until you clone or navigate to the repository.${NC}"
      read -p "Press Enter to continue..."
      main_menu
      ;;
    *)
      echo -e "${RED}Invalid option. Continuing to main menu...${NC}"
      sleep 2
      main_menu
      ;;
  esac
}

# Start the script
initialize_script
