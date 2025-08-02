# 🐳 Multiple Frappe Healthcare Instances

This setup allows you to run multiple independent Frappe Healthcare instances simultaneously without port conflicts.

## 📁 Available Configurations

| Instance | Compose File              | Web Port | DB Port | Redis Port | Access URL            |
| -------- | ------------------------- | -------- | ------- | ---------- | --------------------- |
| **Main** | `docker-compose.yml`      | 8080     | 3307    | 6380       | http://localhost:8080 |
| **ERP1** | `docker-compose-erp1.yml` | 8081     | 3308    | 6381       | http://localhost:8081 |
| **ERP2** | `docker-compose-erp2.yml` | 8082     | 3309    | 6382       | http://localhost:8082 |

## 🚀 Starting Instances

### Start Main Instance

```bash
docker compose up -d
```

### Start ERP1 Instance

```bash
docker compose -f docker-compose-erp1.yml up -d
```

### Start ERP2 Instance

```bash
docker compose -f docker-compose-erp2.yml up -d
```

### Start All Instances

```bash
docker compose up -d
docker compose -f docker-compose-erp1.yml up -d
docker compose -f docker-compose-erp2.yml up -d
```

## 🛑 Stopping Instances

### Stop Main Instance

```bash
docker compose down
```

### Stop ERP1 Instance

```bash
docker compose -f docker-compose-erp1.yml down
```

### Stop ERP2 Instance

```bash
docker compose -f docker-compose-erp2.yml down
```

### Stop All Instances

```bash
docker compose down
docker compose -f docker-compose-erp1.yml down
docker compose -f docker-compose-erp2.yml down
```

## 🔄 Rebuilding Instances

### Rebuild and Start ERP1

```bash
docker compose -f docker-compose-erp1.yml up --build -d
```

### Rebuild and Start ERP2

```bash
docker compose -f docker-compose-erp2.yml up --build -d
```

## 📊 Monitoring Instances

### Check Status of All Containers

```bash
docker ps
```

### View Logs for ERP1

```bash
docker logs frappe-healthcare-erp1
```

### View Logs for ERP2

```bash
docker logs frappe-healthcare-erp2
```

## 🔐 Login Credentials

All instances use the same credentials:

- **Username**: `Administrator`
- **Password**: `admin`

## 💾 Data Persistence

Each instance has separate volumes:

- **Main**: `frappe_sites`, `mariadb_data`, `frappe_logs`
- **ERP1**: `frappe_sites_erp1`, `mariadb_data_erp1`, `frappe_logs_erp1`
- **ERP2**: `frappe_sites_erp2`, `mariadb_data_erp2`, `frappe_logs_erp2`

## 🗄️ Database Access

### Connect to Main Instance Database

```bash
mysql -h localhost -P 3307 -u root -p
```

### Connect to ERP1 Database

```bash
mysql -h localhost -P 3308 -u root -p
```

### Connect to ERP2 Database

```bash
mysql -h localhost -P 3309 -u root -p
```

Password: `rootpassword`

## 🧹 Cleanup

### Remove All Containers and Volumes

```bash
# Stop all instances
docker compose down
docker compose -f docker-compose-erp1.yml down
docker compose -f docker-compose-erp2.yml down

# Remove volumes
docker volume rm erpnext-setup_frappe_sites erpnext-setup_mariadb_data erpnext-setup_frappe_logs
docker volume rm erpnext-setup_frappe_sites_erp1 erpnext-setup_mariadb_data_erp1 erpnext-setup_frappe_logs_erp1
docker volume rm erpnext-setup_frappe_sites_erp2 erpnext-setup_mariadb_data_erp2 erpnext-setup_frappe_logs_erp2
```

## ⚡ Quick Test

Test all instances are running:

```bash
curl -s -o /dev/null -w "Main: %{http_code}\n" http://localhost:8080
curl -s -o /dev/null -w "ERP1: %{http_code}\n" http://localhost:8081
curl -s -o /dev/null -w "ERP2: %{http_code}\n" http://localhost:8082
```

Expected output: All should return `200`
