#!/bin/bash
# Test suite for mysql_looper utilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
DB_HOST="localhost"
DB_USER="test_user"
DB_PASSWORD="test_password"
DB_NAME="test_db"
TEST_RESULTS_DIR="/tmp/test_results"

# Create results directory
mkdir -p "$TEST_RESULTS_DIR"

echo -e "${YELLOW}Starting mysql_looper test suite...${NC}"

# Start MariaDB service
echo "Starting MariaDB service..."
service mariadb start
sleep 2

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -u root -e "SELECT 1" >/dev/null 2>&1; do
    echo "Waiting for MariaDB to start..."
    sleep 1
done

echo -e "${GREEN}MariaDB is ready!${NC}"

# Run individual tests
echo -e "${YELLOW}Running connectivity test...${NC}"
/tests/test_connectivity.sh

echo -e "${YELLOW}Running performance tests...${NC}"
/tests/test_performance.sh

echo -e "${YELLOW}Running query tests...${NC}"
/tests/test_queries.sh

echo -e "${YELLOW}Running daemon test...${NC}"
/tests/test_daemon.sh

echo -e "${YELLOW}Running output format tests...${NC}"
/tests/test_output_formats.sh

echo -e "${GREEN}All tests completed successfully!${NC}"

# Display test results summary
echo -e "${YELLOW}Test Results Summary:${NC}"
if [ -d "$TEST_RESULTS_DIR" ]; then
    for result_file in "$TEST_RESULTS_DIR"/*.log; do
        if [ -f "$result_file" ]; then
            echo "=== $(basename "$result_file") ==="
            cat "$result_file"
            echo ""
        fi
    done
fi

echo -e "${GREEN}Test suite finished!${NC}"