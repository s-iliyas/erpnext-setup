# 🐳 Frappe Healthcare Docker Setup

This Docker setup provides a containerized version of Frappe Framework with ERPNext and Healthcare modules, based on the manual setup instructions from `HEALTHCARE_README.md`.

## 🚀 Quick Start

### Using Docker Compose (Recommended)

```bash
# Build and start the container
docker-compose up --build

# Or run in background
docker-compose up --build -d
```

### Using Docker directly

```bash
# Build the image
docker build -t frappe-healthcare .

# Run the container
docker run -d \
  --name frappe-healthcare \
  -p 8080:8000 \
  -p 3307:3306 \
  -p 6380:6379 \
  -v frappe_sites:/home/frappe/frappe-bench/sites \
  -v mariadb_data:/var/lib/mysql \
  frappe-healthcare
```

## 🌐 Access

- **Frappe/ERPNext Web Interface**: http://localhost:8080
- **Default Credentials**:
  - Username: `Administrator`
  - Password: `admin`
- **Site Name**: `healthcare.swynix.com`

## 📦 What's Included

- Ubuntu 24.04 base
- Python 3.12 with virtual environment
- Node.js 22.x with Yarn
- MariaDB 12 with UTF-8 configuration
- Redis server
- wkhtmltopdf for PDF generation
- Frappe Framework (version-15)
- ERPNext (version-15)
- Healthcare module (version-15)
- Supervisor for process management

## 🔧 Services

The container runs multiple services via Supervisor:

- **MariaDB**: Database server (host port 3307 → container port 3306)
- **Redis**: Cache server (host port 6380 → container port 6379)
- **Frappe Web**: Main web application (host port 8080 → container port 8000)
- **Frappe Workers**: Background job processors (default, long, short queues)
- **Frappe Scheduler**: Cron job scheduler

## 📁 Volumes

- `frappe_sites`: Frappe site data and configurations
- `mariadb_data`: MariaDB database files
- `frappe_logs`: Supervisor and application logs

## 🛠 Customization

### Environment Variables

You can customize the setup by modifying these environment variables in `docker-compose.yml`:

- `SITE_NAME`: The site domain name (default: healthcare.swynix.com)
- `MARIADB_ROOT_PASSWORD`: MariaDB root password (default: rootpassword)
- `ADMIN_PASSWORD`: Frappe Administrator password (default: admin)

### Custom Site Creation

To create a new site after the container is running:

```bash
# Enter the container
docker exec -it frappe-healthcare bash

# Switch to frappe user and activate environment
su - frappe
cd frappe-bench
source ../env/bin/activate

# Create new site
bench new-site your-domain.com --mariadb-root-password rootpassword --admin-password yourpassword
bench use your-domain.com
bench install-app erpnext
bench install-app healthcare
```

## 🔍 Troubleshooting

### View logs

```bash
# All supervisor logs
docker exec -it frappe-healthcare tail -f /var/log/supervisor/*.log

# Specific service logs
docker exec -it frappe-healthcare tail -f /var/log/supervisor/frappe-web.log
```

### Access container shell

```bash
docker exec -it frappe-healthcare bash
```

### Reset database

```bash
# Stop container
docker-compose down

# Remove database volume
docker volume rm erpnext-setup_mariadb_data

# Start fresh
docker-compose up --build
```

## 📝 Notes

- First startup may take several minutes as the site is created and apps are installed
- The container includes all dependencies from the manual setup guide
- MariaDB is configured for UTF-8mb4 support
- Supervisor manages all services and will restart them if they fail
- Site data persists in Docker volumes between container restarts
