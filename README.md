# 💼 Frappe + MariaDB 12 Manual Setup (Ubuntu 24.04 / Noble)

## 📦 System Preparation

```bash
sudo apt update && sudo apt upgrade -y
python3 --version
```

### Install Dependencies

```bash
sudo apt-get install \
  git \
  python3-dev \
  python3-setuptools \
  python3-pip \
  virtualenv \
  apt-transport-https \
  curl \
  python-is-python3 \
  redis-server \
  libmariadb-dev \
  mariadb-server \
  mariadb-client \
  pkg-config -y
```

---

## 🛠 Manual Setup for MariaDB 12 (If not using system `apt` version)

### Add MariaDB Keyring

```bash
sudo mkdir -p /etc/apt/keyrings
sudo curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
```

### Add MariaDB 12 Repo

```bash
sudo nano /etc/apt/sources.list.d/mariadb.sources
```

Paste the following into the file:

```text
# MariaDB 12.0 repository list - created 2025-08-01
X-Repolib-Name: MariaDB
Types: deb
URIs: https://mirror.bharatdatacenter.com/mariadb/repo/12.0/ubuntu
Suites: noble
Components: main main/debug
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
```

Then update and install:

```bash
sudo apt-get update
sudo apt-get install mariadb-server -y
```

---

## 🔐 Secure MariaDB

```bash
sudo mariadb-secure-installation
```

### Follow prompts:

* Enter current root password: just press **Enter** (if none set)
* Switch to unix\_socket: **n**
* Change root password: **Y**, then set it
* Remove anonymous users: **n**
* Disallow remote root login: **n**
* Remove test database: **n**
* Reload privilege tables: **Y**

---

## 🧾 MariaDB UTF-8 Config (Optional but Recommended)

Edit config:

```bash
sudo nano /etc/mysql/my.cnf
```

Add the following:

```ini
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
```

Restart MariaDB:

```bash
sudo systemctl restart mariadb
```

---

## 🟩 Install Node.js via NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc  # or restart terminal
nvm install 22     # or 20, 22
node -v
```

### Install Yarn

```bash
npm install -g yarn
```

---

## 🖨 Install `wkhtmltopdf` for PDF Export Support

### Dependencies:

```bash
sudo apt install xvfb libfontconfig -y
```

### Download and Install:

```bash
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt install xfonts-75dpi -y
sudo dpkg -i wkhtmltox_*.deb
rm wkhtmltox_*.deb
```

---

## 🧪 Setup Python Virtualenv

```bash
sudo apt install  python3-venv -y
python3 -m venv env
source env/bin/activate

# ( or )

# Install virtualenv if not already installed
pip install virtualenv

# Create a virtual environment
virtualenv env

# Activate the environment
source env/bin/activate

```

---

## 🚀 Install Frappe Bench CLI

```bash
pip install frappe-bench 
bench --version
```

### Initialize Bench:

```bash
bench init --frappe-branch version-15 frappe-bench # (can use any name frappe-bench/erp/core/..etc)
cd frappe-bench
```

### If root user command error

```bash
sudo adduser newusername
sudo deluser newusername sudo
su - newusername

```


### Create a New Site:

```bash
bench new-site iliyas.com

# can add multiple sites
bench new-site iliyas.co

bench new-site iliyas.in

# you have select one site

bench use iliyas.com

# get erpnext 

bench get-app erpnext  --branch version-15 

# install erpnext in bench

bench --site iliyas.com install-app erpnext

bench start

bench --site iliyas.com serve --port 8080
```

Follow prompts:

* Enter MariaDB **root** password
* Confirm MariaDB version warning (MariaDB 12 is newer than tested 11.8)
* Set **Administrator** password
* SystemSettings.enable\_scheduler is UNSET (you can enable it later)

---

For production

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
docker compose -f pwd.yml up -d --build
```

---

## 💾 Database Backup & Restore (Docker)

### Take a Database Backup

Use the `db-dump.sh` script to create a full database dump:

```bash
cd erpnext-setup

# Basic usage (saves to ./backups directory)
./db-dump.sh

# Or specify custom output directory
./db-dump.sh /path/to/your/backups
```

This creates a compressed `.sql.gz` file in the `backups/` directory.

---

### Check Database Credentials

Database credentials are stored in the site config inside the container:

```bash
docker exec frappe-mes cat /home/frappe/frappe-bench/sites/mes.swynix.com/site_config.json
```

Output example:

```json
{
  "db_name": "_fc8f8e51235a2db9",
  "db_password": "tZVG3Q0jqK1qbNgD",
  "db_type": "mariadb",
  ...
}
```

**Connection details from host machine:**

| Parameter | Value |
|-----------|-------|
| Host | `localhost` or `127.0.0.1` |
| Port | `3310` (mapped in docker-compose-mes.yml) |
| User | Same as `db_name` from site_config.json |
| Password | `db_password` from site_config.json |
| Database | Same as `db_name` from site_config.json |

---

### Restore Database

#### Option 1: Restore to the same MES Docker database

```bash
# First, get the credentials
docker exec frappe-mes cat /home/frappe/frappe-bench/sites/mes.swynix.com/site_config.json

sudo apt install mysql-client-core-8.0

# Restore (replace values with actual credentials)
zcat backups/your_dump.sql.gz | mysql -h 127.0.0.1 -P 3310 -u <db_name> -p'<db_password>' <db_name>

# example

mysql -h 127.0.0.1 -P 3310 -u _fc8f8e51235a2db9 -p'X8Sapvys2haLpIao' _fc8f8e51235a2db9 < backups/your_dump.sql

# or

# First, copy the dump file into the container
docker cp backups/_fc8f8e51235a2db9_20251210_223240.sql frappe-mes:/tmp/

# Then restore from inside the container
docker exec frappe-mes bash -c "mysql -h 127.0.0.1 -u _fc8f8e51235a2db9 -p'X8Sapvys2haLpIao' _fc8f8e51235a2db9 < /tmp/_fc8f8e51235a2db9_20251210_223240.sql"

# Clean up the temp file
docker exec frappe-mes rm /tmp/_fc8f8e51235a2db9_20251210_223240.sql

# Clear cache after restore
docker exec frappe-mes bash -c "cd /home/frappe/frappe-bench && /home/frappe/env/bin/bench --site mes.swynix.com clear-cache"

```

#### Option 2: Restore to a new/different database

```bash
# Decompress first
gunzip backups/your_dump.sql.gz

# Create new database on target server
mysql -h <new_host> -u root -p -e "CREATE DATABASE mes_new;"
mysql -h <new_host> -u root -p -e "GRANT ALL ON mes_new.* TO 'mes_user'@'%' IDENTIFIED BY 'your_password';"

# Restore
mysql -h <new_host> -u mes_user -p'your_password' mes_new < backups/your_dump.sql
```

#### Option 3: Restore directly without decompressing

```bash
zcat backups/your_dump.sql.gz | mysql -h <host> -P <port> -u <user> -p'<password>' <database>
```

---

### Other Useful Scripts

| Script | Description |
|--------|-------------|
| `db-dump.sh` | Create database backup |
| `clear-mes-data.sh` | Clear all MES operational data (kiosks) |
| `clear-cache.sh` | Clear Frappe cache |
| `update-mes-app.sh` | Pull latest code and rebuild |

---

✅ **Done!**
You now have a working setup of Frappe Framework with MariaDB 12 and all necessary dependencies.

---