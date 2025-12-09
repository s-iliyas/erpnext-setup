#!/bin/bash
# Script to enable server scripts in running MES container
# Usage: ./enable-server-scripts.sh

CONTAINER_NAME="frappe-mes"
SITE_NAME="mes.swynix.com"

echo "Enabling server scripts in container: $CONTAINER_NAME"

docker exec -it $CONTAINER_NAME bash -c "
    source /home/frappe/env/bin/activate && 
    source /home/frappe/.nvm/nvm.sh && 
    nvm use 22 && 
    cd /home/frappe/frappe-bench && 
    bench use $SITE_NAME && 
    bench --site $SITE_NAME set-config server_script_enabled true && 
    bench set-config -g server_script_enabled true &&
    bench --site $SITE_NAME clear-cache &&
    echo 'Server scripts enabled successfully!'
"

echo ""
echo "✅ Server scripts have been enabled."
echo "Please refresh your browser and try 'Fetch Material' again."


