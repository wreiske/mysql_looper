#!/bin/bash
# Test query execution and performance measurement

set -e

DB_HOST="localhost"
DB_USER="test_user"
DB_PASSWORD="test_password"
DB_NAME="test_db"
TEST_RESULTS_DIR="/tmp/test_results"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

echo "Testing query execution and performance..."

# Test 1: Simple SELECT query performance
echo "Test 1: Simple SELECT query (100 loops)"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 100 -q "SELECT 1;" > "$TEST_RESULTS_DIR/performance_simple.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Simple SELECT performance test passed"
    # Extract timing information
    grep "Total Time:" "$TEST_RESULTS_DIR/performance_simple.log" || echo "Warning: Could not extract timing info"
else
    echo "✗ Simple SELECT performance test failed"
    exit 1
fi

# Test 2: Table query performance
echo "Test 2: Table query performance (50 loops)"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 50 -q "SELECT * FROM test_db.test_table;" > "$TEST_RESULTS_DIR/performance_table.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Table query performance test passed"
    grep "Total Time:" "$TEST_RESULTS_DIR/performance_table.log" || echo "Warning: Could not extract timing info"
else
    echo "✗ Table query performance test failed"
    exit 1
fi

# Test 3: Aggregate query performance
echo "Test 3: Aggregate query performance (25 loops)"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 25 -q "SELECT COUNT(*), MAX(id), MIN(id) FROM test_db.test_table;" > "$TEST_RESULTS_DIR/performance_aggregate.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Aggregate query performance test passed"
    grep "Total Time:" "$TEST_RESULTS_DIR/performance_aggregate.log" || echo "Warning: Could not extract timing info"
else
    echo "✗ Aggregate query performance test failed"
    exit 1
fi

# Test 4: Performance with --only-total flag
echo "Test 4: Performance with --only-total flag (10 loops)"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 10 -q "SELECT 1;" --only-total > "$TEST_RESULTS_DIR/performance_only_total.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Only-total performance test passed"
    grep "Total Time:" "$TEST_RESULTS_DIR/performance_only_total.log" || echo "Warning: Could not extract timing info"
else
    echo "✗ Only-total performance test failed"
    exit 1
fi

echo "All performance tests passed!"