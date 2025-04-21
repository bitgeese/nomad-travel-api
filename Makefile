.PHONY: up down build logs shell migrate makemigrations test lint format superuser help

# Display help information by default
help:
	@echo "Available commands:"
	@echo "  make up               - Start all containers"
	@echo "  make down             - Stop all containers"
	@echo "  make build            - Rebuild containers"
	@echo "  make logs             - View logs from all containers"
	@echo "  make shell            - Open a shell in the web container"
	@echo "  make migrate          - Run migrations"
	@echo "  make makemigrations   - Create new migrations"
	@echo "  make test             - Run tests"
	@echo "  make lint             - Run linting checks"
	@echo "  make format           - Format code with black"
	@echo "  make superuser        - Create a superuser"

# Docker compose commands
up:
	docker-compose up -d

down:
	docker-compose down

build:
	docker-compose up -d --build

logs:
	docker-compose logs -f

shell:
	docker-compose exec web /bin/bash

# Django commands
migrate:
	docker-compose exec web python manage.py migrate

makemigrations:
	docker-compose exec web python manage.py makemigrations

test:
	docker-compose exec web python manage.py test

superuser:
	docker-compose exec web python manage.py createsuperuser

# Development tools
lint:
	docker-compose exec web flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	docker-compose exec web flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

format:
	docker-compose exec web black . 