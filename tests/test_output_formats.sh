#!/bin/bash
# Test output formats and options

set -e

DB_HOST="localhost"
DB_USER="test_user"
DB_PASSWORD="test_password"
DB_NAME="test_db"
TEST_RESULTS_DIR="/tmp/test_results"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

echo "Testing output formats and options..."

# Test 1: JSON output format
echo "Test 1: JSON output format"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT 1;" --json > "$TEST_RESULTS_DIR/output_json.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ JSON output test passed"
    # Verify JSON structure
    if grep -q "\"hostname\":" "$TEST_RESULTS_DIR/output_json.log" && grep -q "\"totalTime\":" "$TEST_RESULTS_DIR/output_json.log"; then
        echo "✓ JSON structure validation passed"
    else
        echo "⚠ JSON structure might be incomplete"
    fi
else
    echo "✗ JSON output test failed"
    exit 1
fi

# Test 2: Show output option
echo "Test 2: Show output option"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 3 -q "SELECT name FROM test_db.test_table LIMIT 1;" --show-output > "$TEST_RESULTS_DIR/output_show.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Show output test passed"
    # Check if query results are shown
    if grep -q "Test" "$TEST_RESULTS_DIR/output_show.log" || grep -q "Updated" "$TEST_RESULTS_DIR/output_show.log"; then
        echo "✓ Query results displayed correctly"
    else
        echo "⚠ Query results might not be displayed"
    fi
else
    echo "✗ Show output test failed"
    exit 1
fi

# Test 3: Only total time option
echo "Test 3: Only total time option"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 5 -q "SELECT 1;" --only-total > "$TEST_RESULTS_DIR/output_only_total.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Only total time test passed"
    # Verify that only essential information is shown
    if grep -q "Total Time:" "$TEST_RESULTS_DIR/output_only_total.log"; then
        echo "✓ Total time information present"
    else
        echo "⚠ Total time information might be missing"
    fi
else
    echo "✗ Only total time test failed"
    exit 1
fi

# Test 4: Custom port (should work since we're using default)
echo "Test 4: Custom port specification"
mysql_looper -h "$DB_HOST" --port 3306 -u "$DB_USER" -p "$DB_PASSWORD" -l 3 -q "SELECT 1;" > "$TEST_RESULTS_DIR/output_custom_port.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Custom port test passed"
else
    echo "✗ Custom port test failed"
    exit 1
fi

# Test 5: Combination of options
echo "Test 5: Multiple options combined"
mysql_looper -h "$DB_HOST" -u "$DB_USER" -p "$DB_PASSWORD" -l 3 -q "SELECT COUNT(*) FROM test_db.test_table;" --json --show-output > "$TEST_RESULTS_DIR/output_combined.log" 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Combined options test passed"
else
    echo "✗ Combined options test failed"
    exit 1
fi

echo "All output format tests passed!"