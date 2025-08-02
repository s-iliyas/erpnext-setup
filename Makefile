.PHONY: up down up-all down-all up-erpnext down-erpnext up-healthcare down-healthcare up-hrms down-hrms up-caddy down-caddy up-combo down-combo rebuild-erpnext restart-erpnext clean-erpnext clean-all status logs redis-status redis-cli help

# Resource optimized setup - runs all services with shared Redis
up-all:
	@echo "🚀 Starting all services with shared Redis (optimized for 2CPU/4GB)..."
	docker compose -f docker-compose.yml -f docker-compose-healthcare.yml -f docker-compose-hrms.yml -f docker-compose-caddy.yml up -d --build
	@echo "✅ All services starting... Check status with 'make status'"

down-all:
	@echo "🛑 Stopping all services..."
	docker compose -f docker-compose.yml -f docker-compose-healthcare.yml -f docker-compose-hrms.yml -f docker-compose-caddy.yml down
	@echo "✅ All services stopped"

# Combination setups (recommended for better resource usage)
up-combo:
	@echo "🚀 Starting ERPNext + Healthcare (recommended combo)..."
	docker compose -f docker-compose.yml -f docker-compose-healthcare.yml up -d --build
	@echo "✅ Combo services starting... Check status with 'make status'"

down-combo:
	@echo "🛑 Stopping ERPNext + Healthcare combo..."
	docker compose -f docker-compose.yml -f docker-compose-healthcare.yml down

# Individual services (each includes shared Redis)
up-erpnext:
	@echo "🚀 Starting ERPNext with shared Redis..."
	docker compose up -d --build

down-erpnext:
	docker compose down

up-healthcare:
	@echo "🚀 Starting Healthcare with shared Redis..."
	docker compose -f docker-compose-healthcare.yml up -d --build

down-healthcare:
	docker compose -f docker-compose-healthcare.yml down

up-hrms:
	@echo "🚀 Starting HRMS with shared Redis..."
	docker compose -f docker-compose-hrms.yml up -d --build

down-hrms:
	docker compose -f docker-compose-hrms.yml down

up-caddy:
	docker compose -f docker-compose-caddy.yml up -d --build

down-caddy:
	docker compose -f docker-compose-caddy.yml down

# Legacy compatibility
up: up-combo
down: down-combo

# Maintenance commands
rebuild-erpnext:
	@echo "🔄 Rebuilding ERPNext..."
	docker compose down
	docker compose build --no-cache
	docker compose up -d

restart-erpnext:
	docker compose restart

# Monitoring commands
status:
	@echo "📊 Container Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo "\n💾 Resource Usage:"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

logs:
	@echo "📋 Recent logs from all services:"
	@echo "--- ERPNext ---"
	@docker logs frappe-erpnext --tail 5 2>/dev/null || echo "ERPNext not running"
	@echo "--- Healthcare ---"
	@docker logs frappe-healthcare --tail 5 2>/dev/null || echo "Healthcare not running"
	@echo "--- HRMS ---"
	@docker logs frappe-hrms --tail 5 2>/dev/null || echo "HRMS not running"

redis-status:
	@echo "🔴 Redis Status:"
	@docker exec redis-shared redis-cli info clients 2>/dev/null | grep connected_clients || echo "Redis not running"
	@docker exec redis-shared redis-cli info memory 2>/dev/null | grep used_memory_human || echo "Redis not running"

redis-cli:
	@echo "🔴 Opening Redis CLI (type 'exit' to quit):"
	docker exec -it redis-shared redis-cli

# Cleanup commands
clean-erpnext:
	docker compose down
	docker system prune -f

clean-all:
	@echo "🧹 Cleaning all Docker resources..."
	docker compose -f docker-compose.yml -f docker-compose-healthcare.yml -f docker-compose-hrms.yml -f docker-compose-caddy.yml down
	docker system prune -af
	docker volume prune -f
	@echo "✅ Cleanup complete"

# Help
help:
	@echo "📚 ERPNext Resource Optimized Setup Commands:"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make up-all        - Start all services (ERPNext + Healthcare + HRMS + Caddy)"
	@echo "  make up-combo      - Start ERPNext + Healthcare (recommended)"
	@echo "  make up-erpnext    - Start only ERPNext"
	@echo "  make up-healthcare - Start only Healthcare"
	@echo "  make up-hrms       - Start only HRMS"
	@echo ""
	@echo "🛑 Stop Services:"
	@echo "  make down-all      - Stop all services"
	@echo "  make down-combo    - Stop ERPNext + Healthcare"
	@echo "  make down-erpnext  - Stop ERPNext"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make status        - Show container status and resource usage"
	@echo "  make logs          - Show recent logs from all services"
	@echo "  make redis-status  - Show Redis connection and memory info"
	@echo "  make redis-cli     - Open Redis CLI"
	@echo ""
	@echo "🔧 Maintenance:"
	@echo "  make rebuild-erpnext - Rebuild ERPNext container"
	@echo "  make clean-all       - Stop and clean all Docker resources"
	@echo ""
	@echo "🌐 Access URLs:"
	@echo "  ERPNext:   http://localhost:8080"
	@echo "  Healthcare: http://localhost:8081"
	@echo "  HRMS:      http://localhost:8082"