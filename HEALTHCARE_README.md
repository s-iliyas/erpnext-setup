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

### Create a New Site:

```bash
bench new-site healthcare.swynix.com

bench use healthcare.swynix.com

# get erpnext 

bench get-app erpnext --branch version-15 
bench get-app healthcare --branch version-15 

# install erpnext in bench

bench --site iliyas.com install-app erpnext
bench --site iliyas.com install-app healthcare

bench start

bench --site iliyas.com serve --port 8080
```

Follow prompts:

* Enter MariaDB **root** password
* Confirm MariaDB version warning (MariaDB 12 is newer than tested 11.8)
* Set **Administrator** password
* SystemSettings.enable\_scheduler is UNSET (you can enable it later)

---

✅ **Done!**
You now have a working setup of Frappe Framework with MariaDB 12 and all necessary dependencies.

---