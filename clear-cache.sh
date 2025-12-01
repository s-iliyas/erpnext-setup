docker exec frappe-mes bash -c "
    cd /home/frappe/frappe-bench && \
    source /home/frappe/env/bin/activate && \
    source /home/frappe/.nvm/nvm.sh && \
    nvm use 22 && \
    bench --site mes.swynix.com migrate && \
    bench build --force && \
    bench --site mes.swynix.com clear-cache && \
    bench --site mes.swynix.com clear-website-cache && \
    bench restart
"