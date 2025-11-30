#!/bin/bash
# Simple script to update swynix_mes app in MES container
# Usage: ./update-mes-app.sh

set -e

echo "🔄 Updating swynix_mes app in MES container..."

# Check if container is running
if ! docker ps | grep -q frappe-mes; then
    echo "❌ MES container (frappe-mes) is not running!"
    echo "   Start it with: docker compose -f docker-compose-mes.yml up -d"
    exit 1
fi

# Update app, build, and restart
docker exec -it frappe-mes bash -c "
    git config --global --add safe.directory /home/frappe/frappe-bench/apps/swynix_mes 2>/dev/null || true && \
    cd /home/frappe/frappe-bench/apps/swynix_mes && \
    echo '📥 Pulling latest changes...' && \
    git pull && \
    cd /home/frappe/frappe-bench && \
    echo '🔨 Building assets...' && \
    source /home/frappe/env/bin/activate && \
    source /home/frappe/.nvm/nvm.sh && \
    nvm use 22 && \
    bench build --force && \
    echo '🧹 Clearing cache...' && \
    bench --site mes.swynix.com clear-cache && \
    echo '🔄 Restarting bench...' && \
    bench restart
"

echo "✅ MES app updated successfully!"

