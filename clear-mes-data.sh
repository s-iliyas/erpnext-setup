#!/bin/bash
# Clear MES Data Script
# Clears all data from MES operational tables (All Kiosks)
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
echo -e "${YELLOW}  (All Kiosk Data)${NC}"
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
echo ""
echo "  [Melting Kiosk]"
echo "    - Melting Batch (and child tables)"
echo ""
echo "  [Casting Kiosk]"
echo "    - PPC Casting Plan (and child tables)"
echo "    - Casting Run (and child tables)"
echo "    - Mother Coil (Coils)"
echo ""
echo "  [QC Kiosk]"
echo "    - Coil QC (and child tables)"
echo "    - QC Samples (melting / casting)"
echo ""
echo "  [Rolling Plan Kiosk]"
echo "    - PPC Rolling Plan (and child tables)"
echo ""
echo "  [CRM Kiosk]"
echo "    - CRM Pass / CRM Pass Log"
echo "    - Rolling Route Plan (and child tables)"
echo ""
echo "  [Annealing Kiosk]"
echo "    - Annealing Cycle Log"
echo "    - Annealing Charge (and child tables)"
echo ""
echo "  [Stock]"
echo "    - Stock Entry (and child tables)"
echo ""
echo "  [Common]"
echo "    - Coil Process Logs"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Clearing tables...${NC}"

# Execute SQL to clear tables (in dependency order - children first, parents last)
docker exec ${CONTAINER} bash -c "mysql -h 127.0.0.1 -u ${DB_NAME} -p'${DB_PASS}' ${DB_NAME} -e \"
-- ========================================
-- QC RELATED TABLES (QC Kiosk)
-- ========================================

-- Clear Coil QC child tables
DELETE FROM \\\`tabCoil Surface Defect\\\`;

-- Clear Coil QC parent table
DELETE FROM \\\`tabCoil QC\\\`;

-- Clear Melting QC child tables (element results for spectro samples)
DELETE FROM \\\`tabMelting Sample Element Result\\\`;

-- Clear unified QC Sample child/parent (melting + casting)
DELETE FROM \\\`tabQC Sample Element\\\`;
DELETE FROM \\\`tabQC Sample\\\`;

-- ========================================
-- ANNEALING KIOSK TABLES
-- ========================================

-- Clear Annealing Cycle Log
DELETE FROM \\\`tabAnnealing Cycle Log\\\`;

-- Clear Annealing Charge child tables
DELETE FROM \\\`tabAnnealing Charge Coil\\\`;

-- Clear Annealing Charge parent table
DELETE FROM \\\`tabAnnealing Charge\\\`;

-- ========================================
-- CRM KIOSK TABLES
-- ========================================

-- Clear CRM Pass / CRM Pass Log
DELETE FROM \\\`tabCRM Pass\\\`;
DELETE FROM \\\`tabCRM Pass Log\\\`;

-- Clear Rolling Route Plan child tables
DELETE FROM \\\`tabRolling Route Step\\\`;

-- Clear Rolling Route Plan parent table
DELETE FROM \\\`tabRolling Route Plan\\\`;

-- ========================================
-- ROLLING PLAN KIOSK TABLES
-- ========================================

-- Clear PPC Rolling Plan child tables
DELETE FROM \\\`tabRolling Plan Pass\\\`;

-- Clear PPC Rolling Plan parent table
DELETE FROM \\\`tabPPC Rolling Plan\\\`;

-- ========================================
-- STOCK ENTRIES
-- ========================================

-- Clear Stock Entry child tables
DELETE FROM \\\`tabStock Entry Detail\\\`;

-- Clear Stock Entry parent table
DELETE FROM \\\`tabStock Entry\\\`;

-- ========================================
-- COIL PROCESS LOGS (Common)
-- ========================================

-- Clear Coil Process Logs
DELETE FROM \\\`tabCoil Process Log\\\`;

-- ========================================
-- CASTING KIOSK TABLES  
-- ========================================

-- Clear Mother Coil (depends on Casting Run)
DELETE FROM \\\`tabMother Coil\\\`;

-- Clear Casting Run child tables
DELETE FROM \\\`tabCasting Run Coil\\\`;

-- Clear Casting Run parent table
DELETE FROM \\\`tabCasting Run\\\`;

-- ========================================
-- MELTING KIOSK TABLES
-- ========================================

-- Clear Melting Batch child tables
DELETE FROM \\\`tabMelting Batch Raw Material\\\`;
DELETE FROM \\\`tabMelting Batch Process Log\\\`;
DELETE FROM \\\`tabMelting Batch Spectro Sample\\\`;

-- Clear Melting Batch parent table
DELETE FROM \\\`tabMelting Batch\\\`;

-- ========================================
-- PPC PLANNING TABLES (Casting Kiosk)
-- ========================================

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
SELECT '-- MELTING KIOSK --' as DocType, '' as Count
UNION ALL SELECT 'Melting Batch', COUNT(*) FROM \\\`tabMelting Batch\\\`
UNION ALL SELECT 'Melting Batch Raw Material', COUNT(*) FROM \\\`tabMelting Batch Raw Material\\\`
UNION ALL SELECT 'Melting Batch Process Log', COUNT(*) FROM \\\`tabMelting Batch Process Log\\\`
UNION ALL SELECT 'Melting Batch Spectro Sample', COUNT(*) FROM \\\`tabMelting Batch Spectro Sample\\\`
UNION ALL SELECT 'Melting Sample Element Result', COUNT(*) FROM \\\`tabMelting Sample Element Result\\\`
UNION ALL SELECT '-- CASTING KIOSK --', ''
UNION ALL SELECT 'PPC Casting Plan', COUNT(*) FROM \\\`tabPPC Casting Plan\\\`
UNION ALL SELECT 'PPC Casting Plan SO', COUNT(*) FROM \\\`tabPPC Casting Plan SO\\\`
UNION ALL SELECT 'Casting Run', COUNT(*) FROM \\\`tabCasting Run\\\`
UNION ALL SELECT 'Casting Run Coil', COUNT(*) FROM \\\`tabCasting Run Coil\\\`
UNION ALL SELECT 'Mother Coil', COUNT(*) FROM \\\`tabMother Coil\\\`
UNION ALL SELECT '-- QC KIOSK --', ''
UNION ALL SELECT 'Coil QC', COUNT(*) FROM \\\`tabCoil QC\\\`
UNION ALL SELECT 'Coil Surface Defect', COUNT(*) FROM \\\`tabCoil Surface Defect\\\`
UNION ALL SELECT 'QC Sample', COUNT(*) FROM \\\`tabQC Sample\\\`
UNION ALL SELECT 'QC Sample Element', COUNT(*) FROM \\\`tabQC Sample Element\\\`
UNION ALL SELECT '-- ROLLING PLAN KIOSK --', ''
UNION ALL SELECT 'PPC Rolling Plan', COUNT(*) FROM \\\`tabPPC Rolling Plan\\\`
UNION ALL SELECT 'Rolling Plan Pass', COUNT(*) FROM \\\`tabRolling Plan Pass\\\`
UNION ALL SELECT '-- CRM KIOSK --', ''
UNION ALL SELECT 'CRM Pass', COUNT(*) FROM \\\`tabCRM Pass\\\`
UNION ALL SELECT 'CRM Pass Log', COUNT(*) FROM \\\`tabCRM Pass Log\\\`
UNION ALL SELECT 'Rolling Route Plan', COUNT(*) FROM \\\`tabRolling Route Plan\\\`
UNION ALL SELECT 'Rolling Route Step', COUNT(*) FROM \\\`tabRolling Route Step\\\`
UNION ALL SELECT '-- ANNEALING KIOSK --', ''
UNION ALL SELECT 'Annealing Cycle Log', COUNT(*) FROM \\\`tabAnnealing Cycle Log\\\`
UNION ALL SELECT 'Annealing Charge', COUNT(*) FROM \\\`tabAnnealing Charge\\\`
UNION ALL SELECT 'Annealing Charge Coil', COUNT(*) FROM \\\`tabAnnealing Charge Coil\\\`
UNION ALL SELECT '-- STOCK --', ''
UNION ALL SELECT 'Stock Entry', COUNT(*) FROM \\\`tabStock Entry\\\`
UNION ALL SELECT 'Stock Entry Detail', COUNT(*) FROM \\\`tabStock Entry Detail\\\`
UNION ALL SELECT '-- COMMON --', ''
UNION ALL SELECT 'Coil Process Log', COUNT(*) FROM \\\`tabCoil Process Log\\\`;
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
echo -e "${GREEN}  All MES Kiosk data has been cleared!${NC}"
echo -e "${GREEN}========================================${NC}"

