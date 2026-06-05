# face-recognition-infra

Infrastructure layer for the Face Recognition Attendance System. Provides shared services (database, cache, message queue) via an external Docker network that all other services connect to.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              face-infra (Docker Network)         │
│                                                  │
│  ┌─────────────┐  ┌───────┐  ┌──────────────┐  │
│  │  Azure SQL  │  │ Redis │  │  RabbitMQ    │  │
│  │    Edge     │  │       │  │ + Management │  │
│  │  port 1433  │  │  6379 │  │  5672/15672  │  │
│  └─────────────┘  └───────┘  └──────────────┘  │
└─────────────────────────────────────────────────┘
         ↑               ↑               ↑
   face-recognition-server / edge / web (join network)
```

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| Azure SQL Edge | `mcr.microsoft.com/azure-sql-edge` | `1433` | Primary database (T-SQL, ARM64 native) |
| Redis | `redis:7-alpine` | `6379` | Cache & session store |
| RabbitMQ | `rabbitmq:3-management-alpine` | `5672` / `15672` | Async face processing queue |

## Quick Start

```bash
# 1. clone และ setup
git clone <repo>
cd face-recognition-infra

# 2. สร้าง .env (สร้างอัตโนมัติตอน make up)
cp .env.example .env
# แก้ passwords ใน .env ก่อน

# 3. start
make up

# 4. ตรวจสอบ
make ps
```

## Commands

```bash
make up                        # start ทุก service
make down                      # stop ทุก service
make restart service=redis     # restart เฉพาะ service
make logs service=sqlserver    # ดู log realtime
make ps                        # ดู status และ health
make clean                     # ลบทุกอย่างรวม volumes (ข้อมูลหาย)
```

## Connecting from Other Services

เพิ่มใน `docker-compose.yml` ของ service อื่น:

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
├── docker-compose.yml          # service definitions
├── .env.example                # environment variable template
├── Makefile                    # shortcut commands
├── config/
│   └── rabbitmq/
│       └── rabbitmq.conf       # memory & disk limits
└── init/
    └── sqlserver/
        └── 01_init.sql         # database initialization script
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MSSQL_SA_PASSWORD` | SQL Server SA password (min 8 chars, must include upper/lower/number/symbol) |
| `MSSQL_DB` | Database name |
| `REDIS_PASSWORD` | Redis auth password |
| `RABBITMQ_USER` | RabbitMQ username |
| `RABBITMQ_PASSWORD` | RabbitMQ password |

## RabbitMQ Management UI

เปิด [http://localhost:15672](http://localhost:15672) หลังจาก `make up`

Login ด้วย `RABBITMQ_USER` / `RABBITMQ_PASSWORD` ใน `.env`
