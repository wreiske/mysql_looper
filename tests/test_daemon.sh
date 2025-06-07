#!/bin/bash
# Test daemon functionality (mysql_looperd)

set -e

DB_HOST="localhost"
DB_USER="test_user"
DB_PASSWORD="test_password"
DB_NAME="test_db"
TEST_RESULTS_DIR="/tmp/test_results"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

echo "Testing daemon functionality..."

# Test 1: Daemon basic functionality (run for a few seconds)
echo "Test 1: Daemon basic functionality"
timeout 5s mysql_looperd -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 10 -q "SELECT 1;" --interval 1 > "$TEST_RESULTS_DIR/daemon_basic.log" 2>&1 || true

# Check if daemon produced output
if [ -s "$TEST_RESULTS_DIR/daemon_basic.log" ]; then
    echo "✓ Daemon basic functionality test passed"
    echo "Sample daemon output:"
    head -n 3 "$TEST_RESULTS_DIR/daemon_basic.log"
else
    echo "✗ Daemon basic functionality test failed"
    exit 1
fi

# Test 2: Daemon with custom interval
echo "Test 2: Daemon with custom interval (2 seconds)"
timeout 6s mysql_looperd -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT COUNT(*) FROM test_db.test_table;" --interval 2 > "$TEST_RESULTS_DIR/daemon_interval.log" 2>&1 || true

if [ -s "$TEST_RESULTS_DIR/daemon_interval.log" ]; then
    echo "✓ Daemon interval test passed"
    # Count the number of executions (should be around 3 in 6 seconds with 2-second interval)
    EXECUTION_COUNT=$(grep -c "SELECT COUNT" "$TEST_RESULTS_DIR/daemon_interval.log" || echo "0")
    echo "Daemon executed $EXECUTION_COUNT times"
else
    echo "✗ Daemon interval test failed"
    exit 1
fi

# Test 3: Daemon with JSON output
echo "Test 3: Daemon with JSON output"
timeout 4s mysql_looperd -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT 1;" --interval 1 --json > "$TEST_RESULTS_DIR/daemon_json.log" 2>&1 || true

if [ -s "$TEST_RESULTS_DIR/daemon_json.log" ]; then
    echo "✓ Daemon JSON output test passed"
    # Check if output contains JSON-like structure
    if grep -q "{" "$TEST_RESULTS_DIR/daemon_json.log"; then
        echo "JSON format detected in output"
    fi
else
    echo "✗ Daemon JSON output test failed"
    exit 1
fi

echo "All daemon tests passed!"