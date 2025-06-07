#!/bin/bash
# Database initialization script for Docker testing

# Create database and user
mysql -u root -e "CREATE DATABASE IF NOT EXISTS test_db;"
mysql -u root -e "CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'test_password';"
mysql -u root -e "GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Create test table and insert test data
mysql -u root test_db -e "CREATE TABLE test_table (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
mysql -u root test_db -e "INSERT INTO test_table (name) VALUES ('Test Record 1'), ('Test Record 2'), ('Test Record 3'), ('Test Record 4'), ('Test Record 5');"

echo "Database initialization completed successfully!"