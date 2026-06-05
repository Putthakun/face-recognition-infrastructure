# face-recognition-infra

Infrastructure layer for the Face Recognition Attendance System. Provides shared services (database, cache, message queue) via an external Docker network that all other services connect to.

## Architecture

![Architecture](https://github.com/user-attachments/assets/a7a6027c-1bed-4b00-86d7-5c2a3cb154ce)

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| Azure SQL Edge | `mcr.microsoft.com/azure-sql-edge` | `1433` | Primary database (T-SQL, ARM64 native) |
| Redis | `redis:7-alpine` | `6379` | Cache & session store |
| RabbitMQ | `rabbitmq:3-management-alpine` | `5672` / `15672` | Async face processing queue |
| Prometheus | `prom/prometheus` | `9090` | Metrics collection |
| Grafana | `grafana/grafana` | `3000` | Metrics dashboard |

## Quick Start

```bash
# 1. Clone the repository
git clone <repo>
cd face-recognition-infra

# 2. Create .env from template (auto-created on first make up)
cp .env.example .env
# Edit passwords in .env before starting

# 3. Start all services
make up

# 4. Verify services are healthy
make ps
```

## Commands

```bash
make up                        # Start all services
make down                      # Stop all services
make restart service=redis     # Restart a specific service
make logs service=sqlserver    # Stream logs for a specific service
make ps                        # Show status and health
make clean                     # Remove all containers and volumes (data will be lost)
```

## Connecting from Other Services

Add the following to your service's `docker-compose.yml`:

```yaml
networks:
  face-infra:
    external: true

services:
  your-service:
    networks:
      - face-infra
    environment:
      DATABASE_URL: "Server=infra-sqlserver,1433;Database=facerecog;User Id=sa;Password=<password>;TrustServerCertificate=True"
      REDIS_URL: redis://:<password>@infra-redis:6379
      RABBITMQ_URL: amqp://<user>:<password>@infra-rabbitmq:5672
```

> **Note:** Start infra before other services. `depends_on` does not work across separate compose projects — implement connection retry in the application layer.

## Project Structure

```
face-recognition-infra/
├── docker-compose.yml          # Service definitions
├── .env.example                # Environment variable template
├── Makefile                    # Shortcut commands
├── config/
│   ├── rabbitmq/
│   │   └── rabbitmq.conf       # Memory & disk limits
│   ├── prometheus/
│   │   └── prometheus.yml      # Scrape config
│   └── grafana/
│       └── provisioning/
│           └── datasources/
│               └── prometheus.yml  # Auto-connect Grafana → Prometheus
└── init/
    └── sqlserver/
        └── 01_init.sql         # Database initialization script
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MSSQL_SA_PASSWORD` | SQL Server SA password (min 8 chars, must include upper/lower/number/symbol) |
| `MSSQL_DB` | Database name |
| `REDIS_PASSWORD` | Redis auth password |
| `RABBITMQ_USER` | RabbitMQ username |
| `RABBITMQ_PASSWORD` | RabbitMQ password |
| `GRAFANA_USER` | Grafana admin username |
| `GRAFANA_PASSWORD` | Grafana admin password |

## Web UIs

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | [http://localhost:3000](http://localhost:3000) | `GRAFANA_USER` / `GRAFANA_PASSWORD` |
| Prometheus | [http://localhost:9090](http://localhost:9090) | — |
| RabbitMQ | [http://localhost:15672](http://localhost:15672) | `RABBITMQ_USER` / `RABBITMQ_PASSWORD` |
