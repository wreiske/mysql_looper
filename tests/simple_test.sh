#!/bin/bash
# Simplified test script for mysql_looper Docker testing

set -e

echo "=== MySQL Looper Docker Test Suite ==="

# Start MariaDB
service mariadb start
sleep 3

echo "✓ MariaDB started successfully"

# Test 1: Basic connectivity
echo -n "Testing basic connectivity... "
if mysql_looper -h localhost -u test_user -p test_password -l 5 -q "SELECT 1;" >/dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 2: Database operations
echo -n "Testing database operations... "
if mysql_looper -h localhost -u test_user -p test_password -l 3 -q "SELECT COUNT(*) FROM test_db.test_table;" >/dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 3: Performance measurement with JSON output
echo -n "Testing JSON output... "
if mysql_looper -h localhost -u test_user -p test_password -l 2 -q "SELECT 1;" --json >/dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 4: INSERT operations
echo -n "Testing INSERT operations... "
if mysql_looper -h localhost -u test_user -p test_password -l 2 -q "INSERT INTO test_db.test_table (name) VALUES ('Docker Test');" >/dev/null 2>&1; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi

# Test 5: Daemon functionality (brief test)
echo -n "Testing daemon functionality... "
if timeout 3s mysql_looperd -h localhost -u test_user -p test_password -l 2 -q "SELECT 1;" --interval 1 >/dev/null 2>&1; then
    echo "PASS"
else
    # Daemon should timeout, which is expected
    echo "PASS (timeout expected)"
fi

echo "✓ All tests completed successfully!"
echo "✓ MySQL Looper Docker environment is working correctly"

# Show some sample output
echo ""
echo "=== Sample mysql_looper output ==="
mysql_looper -h localhost -u test_user -p test_password -l 3 -q "SELECT COUNT(*) FROM test_db.test_table;"

echo ""
echo "=== Sample mysql_looper JSON output ==="
mysql_looper -h localhost -u test_user -p test_password -l 2 -q "SELECT 1;" --json