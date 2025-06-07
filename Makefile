# Makefile for mysql_looper build and testing

.PHONY: all build package test clean docker-build docker-test help

# Default target
all: build

# Build the executables
build:
	mkdir -p build
	cd build && cmake .. && make

# Create .deb package
package: build
	gem install fpm || echo "fpm already installed"
	rm -f *.deb
	fpm -t deb -v 0.1.0

# Build Docker image for testing
docker-build: package
	docker build -f Dockerfile.test -t mysql_looper:test .

# Run Docker-based tests
docker-test: docker-build
	docker run --rm mysql_looper:test

# Run Docker tests with interactive shell for debugging
docker-debug: docker-build
	docker run --rm -it mysql_looper:test /bin/bash

# Clean build artifacts
clean:
	rm -rf build/
	rm -f *.deb
	docker rmi mysql_looper:test 2>/dev/null || true

# Install dependencies (requires sudo)
install-deps:
	sudo apt-get update
	sudo apt-get install -y build-essential cmake libmariadb-dev ruby ruby-dev rubygems

# Quick local test (requires local MariaDB)
local-test: build
	@echo "Note: This requires a local MariaDB server running"
	@echo "Creating test database and user..."
	mysql -u root -e "CREATE DATABASE IF NOT EXISTS test_db;" || true
	mysql -u root -e "CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'test_password';" || true
	mysql -u root -e "GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'localhost';" || true
	mysql -u root -e "FLUSH PRIVILEGES;" || true
	mysql -u root test_db -e "CREATE TABLE IF NOT EXISTS test_table (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);" || true
	mysql -u root test_db -e "INSERT IGNORE INTO test_table (id, name) VALUES (1, 'Test Record 1'), (2, 'Test Record 2'), (3, 'Test Record 3');" || true
	@echo "Running basic connectivity test..."
	./build/mysql_looper -h localhost -u test_user -p test_password -l 5 -q "SELECT 1;"

# Display help
help:
	@echo "Available targets:"
	@echo "  all          - Build the project (default)"
	@echo "  build        - Build mysql_looper and mysql_looperd executables"
	@echo "  package      - Create .deb package"
	@echo "  docker-build - Build Docker test image"
	@echo "  docker-test  - Run full test suite in Docker"
	@echo "  docker-debug - Run Docker container with shell for debugging"
	@echo "  local-test   - Run basic test against local MariaDB (requires setup)"
	@echo "  install-deps - Install build dependencies"
	@echo "  clean        - Clean build artifacts and Docker images"
	@echo "  help         - Show this help message"