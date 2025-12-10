#!/bin/bash
# Database Dump Script for MES
# Creates a full database dump that can be restored to another database
# Usage: ./db-dump.sh [output_directory]

set -e

# Configuration
CONTAINER="frappe-mes"
SITE="mes.swynix.com"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEFAULT_OUTPUT_DIR="./backups"

# Output directory (use provided argument or default)
OUTPUT_DIR="${1:-$DEFAULT_OUTPUT_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  MES Database Dump Script${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo -e "${RED}Error: Container '${CONTAINER}' is not running!${NC}"
    echo "Start the container first with: docker compose -f docker-compose-mes.yml up -d"
    exit 1
fi

echo -e "${GREEN}Container '${CONTAINER}' is running${NC}"

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

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Define dump filename
DUMP_FILENAME="${DB_NAME}_${TIMESTAMP}.sql"
DUMP_PATH_CONTAINER="/tmp/${DUMP_FILENAME}"
DUMP_PATH_HOST="${OUTPUT_DIR}/${DUMP_FILENAME}"
COMPRESSED_FILENAME="${DUMP_FILENAME}.gz"
COMPRESSED_PATH_HOST="${OUTPUT_DIR}/${COMPRESSED_FILENAME}"

echo ""
echo -e "${YELLOW}Creating database dump...${NC}"
echo -e "  Database: ${CYAN}${DB_NAME}${NC}"
echo -e "  Output: ${CYAN}${DUMP_PATH_HOST}${NC}"
echo ""

# Create dump inside container (MariaDB compatible options)
docker exec ${CONTAINER} bash -c "mysqldump -h 127.0.0.1 -u ${DB_NAME} -p'${DB_PASS}' \
    --single-transaction \
    --routines \
    --triggers \
    --add-drop-table \
    ${DB_NAME} > ${DUMP_PATH_CONTAINER}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create database dump!${NC}"
    exit 1
fi

# Get dump size inside container
DUMP_SIZE=$(docker exec ${CONTAINER} bash -c "du -h ${DUMP_PATH_CONTAINER}" | cut -f1)
echo -e "${GREEN}Dump created inside container (${DUMP_SIZE})${NC}"

# Copy dump from container to host
echo -e "${YELLOW}Copying dump to host...${NC}"
docker cp "${CONTAINER}:${DUMP_PATH_CONTAINER}" "${DUMP_PATH_HOST}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to copy dump from container!${NC}"
    exit 1
fi

# Clean up dump file inside container
docker exec ${CONTAINER} bash -c "rm -f ${DUMP_PATH_CONTAINER}"

# Compress the dump
echo -e "${YELLOW}Compressing dump file...${NC}"
gzip -f "${DUMP_PATH_HOST}"

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(du -h "${COMPRESSED_PATH_HOST}" | cut -f1)
    echo -e "${GREEN}Compressed to ${COMPRESSED_SIZE}${NC}"
else
    echo -e "${YELLOW}Warning: Compression failed, keeping uncompressed file${NC}"
    COMPRESSED_PATH_HOST="${DUMP_PATH_HOST}"
fi

# Show final output
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Database dump completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Dump file: ${CYAN}${COMPRESSED_PATH_HOST}${NC}"
echo ""
echo -e "${YELLOW}To restore this dump to another database:${NC}"
echo ""
echo "  1. Decompress (if compressed):"
echo -e "     ${CYAN}gunzip ${COMPRESSED_PATH_HOST}${NC}"
echo ""
echo "  2. Restore to database:"
echo -e "     ${CYAN}mysql -h <host> -u <user> -p <database_name> < ${DUMP_PATH_HOST}${NC}"
echo ""
echo "  Or restore directly (without decompressing):"
echo -e "     ${CYAN}zcat ${COMPRESSED_PATH_HOST} | mysql -h <host> -u <user> -p <database_name>${NC}"
echo ""
