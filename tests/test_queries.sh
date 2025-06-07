#!/bin/bash
# Test various SQL queries to validate functionality

set -e

DB_HOST="localhost"
DB_USER="test_user"
DB_PASSWORD="test_password"
DB_NAME="test_db"
TEST_RESULTS_DIR="/tmp/test_results"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

echo "Testing various SQL queries..."

# Test 1: SELECT with WHERE clause
echo "Test 1: SELECT with WHERE clause"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT * FROM test_db.test_table WHERE id > 2;" > "$TEST_RESULTS_DIR/query_where.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ WHERE clause query test passed"
else
    echo "✗ WHERE clause query test failed"
    exit 1
fi

# Test 2: JOIN query (simulate with subquery since we only have one table)
echo "Test 2: Complex SELECT with subquery"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT t1.name, t1.id FROM test_db.test_table t1 WHERE t1.id IN (SELECT id FROM test_db.test_table WHERE id <= 3);" > "$TEST_RESULTS_DIR/query_subquery.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Subquery test passed"
else
    echo "✗ Subquery test failed"
    exit 1
fi

# Test 3: INSERT query
echo "Test 3: INSERT query"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 3 -q "INSERT INTO test_db.test_table (name) VALUES ('Test Insert');" > "$TEST_RESULTS_DIR/query_insert.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ INSERT query test passed"
else
    echo "✗ INSERT query test failed"
    exit 1
fi

# Test 4: UPDATE query
echo "Test 4: UPDATE query"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 2 -q "UPDATE test_db.test_table SET name = 'Updated Name' WHERE id = 1;" > "$TEST_RESULTS_DIR/query_update.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ UPDATE query test passed"
else
    echo "✗ UPDATE query test failed"
    exit 1
fi

# Test 5: ORDER BY query
echo "Test 5: ORDER BY query"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT * FROM test_db.test_table ORDER BY id DESC LIMIT 3;" > "$TEST_RESULTS_DIR/query_order_by.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ ORDER BY query test passed"
else
    echo "✗ ORDER BY query test failed"
    exit 1
fi

echo "All query tests passed!"