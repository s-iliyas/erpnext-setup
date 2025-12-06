#!/bin/bash
# Clear MES Data Script
# Clears all data from Melting Batch and PPC Casting Plan tables
# Usage: ./clear-mes-data.sh

set -e

# Configuration
CONTAINER="frappe-mes"
SITE="mes.swynix.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  MES Data Clearing Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo -e "${RED}Error: Container '${CONTAINER}' is not running!${NC}"
    echo "Start the container first with: docker compose -f docker-compose-mes.yml up -d"
    exit 1
fi

# Get database credentials
echo -e "${YELLOW}Fetching database credentials...${NC}"
DB_CONFIG=$(docker exec ${CONTAINER} bash -c "cat /home/frappe/frappe-bench/sites/${SITE}/site_config.json")
DB_NAME=$(echo "$DB_CONFIG" | grep -o '"db_name": "[^"]*"' | cut -d'"' -f4)
DB_PASS=$(echo "$DB_CONFIG" | grep -o '"db_password": "[^"]*"' | cut -d'"' -f4)

if [ -z "$DB_NAME" ] || [ -z "$DB_PASS" ]; then
    echo -e "${RED}Error: Could not retrieve database credentials!${NC}"
    exit 1
fi

echo -e "${GREEN}Database: ${DB_NAME}${NC}"
echo ""

# Confirmation prompt
echo -e "${RED}WARNING: This will DELETE ALL data from:${NC}"
echo "  - Melting Batch (and child tables)"
echo "  - PPC Casting Plan (and child tables)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Clearing tables...${NC}"

# Execute SQL to clear tables
docker exec ${CONTAINER} bash -c "mysql -h 127.0.0.1 -u ${DB_NAME} -p'${DB_PASS}' ${DB_NAME} -e \"
-- Clear Melting Batch child tables first (foreign key dependencies)
DELETE FROM \\\`tabMelting Batch Raw Material\\\`;
DELETE FROM \\\`tabMelting Batch Process Log\\\`;
DELETE FROM \\\`tabMelting Batch Spectro Sample\\\`;

-- Clear Melting Batch parent table
DELETE FROM \\\`tabMelting Batch\\\`;

-- Clear PPC Casting Plan child tables
DELETE FROM \\\`tabPPC Casting Plan SO\\\`;

-- Clear PPC Casting Plan parent table
DELETE FROM \\\`tabPPC Casting Plan\\\`;
\""

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Tables cleared successfully!${NC}"
else
    echo -e "${RED}✗ Error clearing tables!${NC}"
    exit 1
fi

# Verify counts
echo ""
echo -e "${YELLOW}Verifying table counts...${NC}"
docker exec ${CONTAINER} bash -c "mysql -h 127.0.0.1 -u ${DB_NAME} -p'${DB_PASS}' ${DB_NAME} -e \"
SELECT 'Melting Batch' as DocType, COUNT(*) as Count FROM \\\`tabMelting Batch\\\`
UNION ALL SELECT 'Melting Batch Raw Material', COUNT(*) FROM \\\`tabMelting Batch Raw Material\\\`
UNION ALL SELECT 'Melting Batch Process Log', COUNT(*) FROM \\\`tabMelting Batch Process Log\\\`
UNION ALL SELECT 'Melting Batch Spectro Sample', COUNT(*) FROM \\\`tabMelting Batch Spectro Sample\\\`
UNION ALL SELECT 'PPC Casting Plan', COUNT(*) FROM \\\`tabPPC Casting Plan\\\`
UNION ALL SELECT 'PPC Casting Plan SO', COUNT(*) FROM \\\`tabPPC Casting Plan SO\\\`;
\""

# Clear cache
echo ""
echo -e "${YELLOW}Clearing Frappe cache...${NC}"
docker exec ${CONTAINER} bash -c "cd /home/frappe/frappe-bench && /home/frappe/env/bin/bench --site ${SITE} clear-cache" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Cache cleared!${NC}"
else
    echo -e "${YELLOW}⚠ Cache clear returned non-zero (may still be ok)${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All MES data has been cleared!${NC}"
echo -e "${GREEN}========================================${NC}"







