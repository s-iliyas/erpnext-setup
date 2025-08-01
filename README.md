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
* Remove anonymous users: **Y**
* Disallow remote root login: **n**
* Remove test database: **Y**
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
nvm install 18     # or 20, 22
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
pip install virtualenv
virtualenv env
source env/bin/activate
```

---

## 🚀 Install Frappe Bench CLI

```bash
pip install frappe-bench # (can use any name frappe-bench/erp/core/..etc)
bench --version  # should print e.g. 5.25.9
```

### Initialize Bench:

```bash
bench init frappe-bench
cd frappe-bench
```

### Create a New Site:

```bash
bench new-site iliyas.com
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