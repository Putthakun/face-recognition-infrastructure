.PHONY: up down restart logs ps clean

# copy .env.example → .env
.env:
	cp .env.example .env
	@echo ".env created — please edit passwords before run"

up: .env
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart $(service)

logs:
	docker compose logs -f $(service)

ps:
	docker compose ps

# remove container + volumes
clean:
	docker compose down -v --remove-orphans
