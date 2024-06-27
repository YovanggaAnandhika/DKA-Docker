<?php

$host = 'dka-mariadb';        // MySQL host (change to your host)
$username = 'mysql_user';    // MySQL username (change to your username)
$password = 'mysql_password';// MySQL password (change to your password)
$database = 'mysql_database';// MySQL database name (change to your database name)

// Attempt to connect to MySQL database
$conn = new mysqli($host, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
die("Connection failed: " . $conn->connect_error);
}

echo "Connected successfully";

// Close connection
$conn->close();