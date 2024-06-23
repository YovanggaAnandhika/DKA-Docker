<?php
$host = 'dka-mariadb'; // Docker service name
$user = 'root'; // Database username
$password = 'Cyberhack2010'; // Database password
$database = 'mysql'; // Database name
$port = 3306; // MariaDB port

// Create connection
$conn = new mysqli($host, $user, $password, $database, $port);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} else {
    echo "Connected successfully";
}
?>