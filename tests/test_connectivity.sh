#!/bin/bash
# Test database connectivity and basic functionality

set -e

DB_HOST="localhost"
DB_USER="test_user"
DB_PASSWORD="test_password"
DB_NAME="test_db"
TEST_RESULTS_DIR="/tmp/test_results"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

echo "Testing database connectivity..."

# Test 1: Basic connectivity test
echo "Test 1: Basic connectivity with simple query"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 1 -q "SELECT 1;" > "$TEST_RESULTS_DIR/connectivity_basic.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Basic connectivity test passed"
else
    echo "✗ Basic connectivity test failed"
    exit 1
fi

# Test 2: Database selection test
echo "Test 2: Database selection and table query"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 1 -q "SELECT COUNT(*) FROM test_db.test_table;" > "$TEST_RESULTS_DIR/connectivity_db_select.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Database selection test passed"
else
    echo "✗ Database selection test failed"
    exit 1
fi

# Test 3: Invalid credentials should fail
echo "Test 3: Invalid credentials handling"
timeout 10s mysql_looper -h "$DB_HOST" -u "invalid_user" -p "invalid_password" -l 1 -q "SELECT 1;" > "$TEST_RESULTS_DIR/connectivity_invalid.log" 2>&1

if [ $? -ne 0 ]; then
    echo "✓ Invalid credentials test passed (correctly failed)"
else
    echo "✗ Invalid credentials test failed (should have failed)"
    exit 1
fi

echo "All connectivity tests passed!"