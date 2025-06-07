# Docker Testing Guide for mysql_looper

This document describes the Docker-based unit testing setup for mysql_looper, which uses Debian 12, MariaDB, and the .deb artifact for comprehensive testing.

## Overview

The testing infrastructure validates:
- Database connectivity and authentication
- Query execution and performance measurement  
- Both mysql_looper and mysql_looperd functionality
- Output formats (human-readable and JSON)
- Error handling and edge cases

## Quick Start

### Prerequisites
- Docker
- Make
- Build tools (cmake, gcc, ruby, fpm)

### Running Tests

```bash
# Run the complete Docker test suite
make docker-test

# Or run individual components
make build          # Build the executables
make package        # Create .deb package
make docker-build   # Build Docker test image
```

### Available Make Targets

- `make build` - Build mysql_looper and mysql_looperd executables
- `make package` - Create .deb package with both executables
- `make docker-build` - Build Docker test image with MariaDB and .deb installation
- `make docker-test` - Run complete test suite in Docker container
- `make docker-debug` - Start Docker container with interactive shell for debugging
- `make clean` - Clean build artifacts and Docker images
- `make help` - Show available targets

## Test Architecture

### Docker Environment
- **Base Image**: Debian 12 (bookworm)
- **Database**: MariaDB server and client
- **Package Installation**: mysql_looper .deb artifact via dpkg
- **Test Database**: `test_db` with sample data in `test_table`
- **Test User**: `test_user` with password `test_password`

### Test Categories

1. **Connectivity Tests**
   - Basic database connection
   - Table queries with qualified names
   - Authentication validation

2. **Performance Tests**
   - Simple SELECT queries with timing measurement
   - Table operations with multiple loops
   - Aggregate functions (COUNT, MAX, MIN)
   - Performance with --only-total flag

3. **Query Tests**
   - WHERE clause filtering
   - Subqueries and complex SELECT statements
   - INSERT operations
   - UPDATE operations
   - ORDER BY with LIMIT

4. **Daemon Tests**
   - mysql_looperd basic functionality
   - Custom interval execution
   - JSON output format for daemon

5. **Output Format Tests**
   - JSON output validation
   - --show-output flag functionality
   - --only-total flag behavior
   - Custom port specification
   - Combined option flags

### Test Database Schema

```sql
CREATE DATABASE test_db;
CREATE USER 'test_user'@'localhost' IDENTIFIED BY 'test_password';
GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'localhost';

CREATE TABLE test_table (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO test_table (name) VALUES 
  ('Test Record 1'), ('Test Record 2'), ('Test Record 3'), 
  ('Test Record 4'), ('Test Record 5');
```

## Sample Test Output

```bash
=== MySQL Looper Docker Test Suite ===
✓ MariaDB started successfully
Testing basic connectivity... PASS
Testing database operations... PASS
Testing JSON output... PASS
Testing INSERT operations... PASS
Testing daemon functionality... PASS (timeout expected)
✓ All tests completed successfully!
✓ MySQL Looper Docker environment is working correctly

=== Sample mysql_looper output ===
Query: SELECT COUNT(*) FROM test_db.test_table;
Looped 3 times
Hostname: container-id
DB Host: localhost
DB User: test_user
Connect Time: 0.00022000 seconds
Loop Time: 0.00038200 seconds
Finish Time: 0.00001400 seconds
Total Time: 0.00061600 seconds

=== Sample mysql_looper JSON output ===
{
  "hostname": "container-id",
  "dbHost": "localhost", 
  "dbUser": "test_user",
  "dbPort": 3306,
  "loop": 2,
  "connectTime": 0.00014800,
  "loopTime": 0.00011600,
  "finishTime": 0.00001100,
  "totalTime": 0.00027500
}
```

## Debugging

### Interactive Debugging
```bash
make docker-debug
# Inside container:
service mariadb start
mysql_looper -h localhost -u test_user -p test_password -l 5 -q "SELECT 1;"
```

### Manual Testing
```bash
# Test .deb package installation
dpkg -l | grep mysql-looper

# Test executables
which mysql_looper mysql_looperd

# Test database connectivity  
mysql -u test_user -p test_password test_db -e "SELECT COUNT(*) FROM test_table;"
```

## Files and Structure

```
mysql_looper/
├── Dockerfile.test           # Docker test environment
├── docker-init-db.sh         # Database initialization script
├── Makefile                  # Build and test automation
├── tests/
│   ├── simple_test.sh        # Main test suite (simplified)
│   ├── run_tests.sh          # Comprehensive test runner
│   ├── test_connectivity.sh  # Database connection tests
│   ├── test_performance.sh   # Performance measurement tests
│   ├── test_queries.sh       # SQL query validation tests
│   ├── test_daemon.sh        # mysql_looperd functionality tests
│   └── test_output_formats.sh # Output format validation tests
├── CMakeLists.txt            # Build configuration (updated for both executables)
└── .fpm                      # Package configuration (updated for both executables)
```

## Integration with CI/CD

The Docker testing setup is designed to work with GitHub Actions or other CI/CD systems:

```yaml
# Example GitHub Actions workflow
- name: Run Docker Tests
  run: make docker-test
```

## Package Validation

The tests validate that the .deb package:
- Installs without dependency errors
- Provides both mysql_looper and mysql_looperd executables
- Works correctly with MariaDB client libraries
- Handles all command-line options properly
- Produces expected output formats

## Performance Metrics

The test suite measures and validates:
- Connection time to database
- Query execution time across multiple loops
- Total operation time including setup and teardown
- Performance consistency across different query types

This comprehensive testing ensures that mysql_looper works correctly in production Debian environments with MariaDB databases.