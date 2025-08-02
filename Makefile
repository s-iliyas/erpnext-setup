.PHONY: up down up-erpnext down-erpnext up-healthcare down-healthcare up-hrms down-hrms up-caddy down-caddy rebuild-erpnext restart-erpnext clean-erpnext

up: up-erpnext up-healthcare up-hrms up-caddy

down: down-erpnext down-healthcare down-hrms down-caddy

up-erpnext:
	docker compose up -d --build

down-erpnext:
	docker compose down

up-healthcare:
	docker compose -f docker-compose-healthcare.yml up -d --build

down-healthcare:
	docker compose -f docker-compose-healthcare.yml down

up-hrms:
	docker compose -f docker-compose-hrms.yml up -d --build

down-hrms:
	docker compose -f docker-compose-hrms.yml down

up-caddy:
	docker compose -f docker-compose-caddy.yml up -d --build

down-caddy:
	docker compose -f docker-compose-caddy.yml down

rebuild-erpnext:
	docker compose down
	docker compose build --no-cache
	docker compose up -d

restart-erpnext:
	docker compose restart

clean-erpnext:
	docker compose down
	docker system prune -f
	docker volume prune -f