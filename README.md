# nodejs-devops-app

A production-ready Node.js REST API containerized with Docker, orchestrated with Docker Compose (app + MongoDB), tested with Jest, and deployed via a GitHub Actions CI/CD pipeline.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Node.js 20, Express.js |
| Database | MongoDB 7 (Mongoose ODM) |
| Testing | Jest + Supertest |
| Container | Docker (multi-stage build) |
| Orchestration | Docker Compose |
| CI/CD | GitHub Actions |
| Registry | Docker Hub |

## Project Structure

```
nodejs-devops-app/
├── src/
│   ├── app.js                  # Express entry point
│   ├── models/item.js          # Mongoose Item schema
│   └── routes/items.js         # CRUD route handlers
├── tests/
│   └── items.test.js           # Jest + Supertest test suite
├── deploy/
│   └── setup-vm.sh             # VM bootstrap script
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions pipeline
├── Dockerfile                  # Multi-stage production build
├── docker-compose.yml          # App + MongoDB stack
├── docker-compose.test.yml     # Test environment override
├── .dockerignore
├── .env.example
└── package.json
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/items` | Get all items |
| GET | `/api/items/:id` | Get single item |
| POST | `/api/items` | Create new item |
| PUT | `/api/items/:id` | Update item |
| DELETE | `/api/items/:id` | Delete item |

## Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Node.js 20+](https://nodejs.org/) (for local dev)

### Run with Docker Compose

```bash
# Clone and enter the project
git clone <your-repo-url>
cd nodejs-devops-app

# Start the full stack (app + MongoDB)
docker compose up -d

# Verify it's running
curl http://localhost:3000/health

# View logs
docker compose logs -f app
```

### Run Tests

```bash
# Option 1: Local (requires MongoDB running on localhost:27017)
npm install
npm test

# Option 2: Fully containerized (recommended)
docker compose -f docker-compose.yml -f docker-compose.test.yml up \
  --abort-on-container-exit --exit-code-from app
```

### Run Locally (without Docker)

```bash
npm install
cp .env.example .env
# Edit .env: set MONGO_URI=mongodb://localhost:27017/devopsdb
npm run dev
```

## GitHub Actions CI/CD

The pipeline has **3 jobs** that run sequentially on push to `main`:

```
push to main
     │
     ▼
[1] 🧪 test          ← runs Jest tests with MongoDB in Docker
     │
     ▼
[2] 🐳 build-and-push ← builds image, pushes to Docker Hub
     │
     ▼
[3] 🚀 deploy         ← SSH into VM, pull image, docker compose up
```

### Required GitHub Secrets

Go to **Settings → Secrets → Actions** in your GitHub repo and add:

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | `AmanaJamsheed` |
| `DOCKERHUB_TOKEN` | Your Docker Hub access token |
| `VM_HOST` | Your VM's public IP address |
| `VM_USERNAME` | SSH username (e.g., `ubuntu`) |
| `VM_SSH_PRIVATE_KEY` | Contents of your private SSH key |

### Create a Docker Hub Access Token

1. Go to [hub.docker.com](https://hub.docker.com) → Account Settings → Security
2. Click **New Access Token** → name it `github-actions`
3. Copy the token and add it as `DOCKERHUB_TOKEN` secret

## VM Deployment

```bash
# 1. SSH into your Ubuntu 22.04 VM
ssh user@your-vm-ip

# 2. Upload and run setup script
scp deploy/setup-vm.sh user@your-vm-ip:~
ssh user@your-vm-ip "sudo bash setup-vm.sh"

# 3. Log out and back in for docker group changes
exit && ssh user@your-vm-ip

# 4. First manual deployment
mkdir -p ~/nodejs-devops-app
scp docker-compose.yml user@your-vm-ip:~/nodejs-devops-app/
ssh user@your-vm-ip "cd ~/nodejs-devops-app && docker compose up -d"
```

After this, GitHub Actions handles all future deployments automatically.

## Sample API Usage

```bash
# Health check
curl http://localhost:3000/health

# Create an item
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Laptop", "description": "Dell XPS 15", "quantity": 3}'

# Get all items
curl http://localhost:3000/api/items

# Update an item
curl -X PUT http://localhost:3000/api/items/<id> \
  -H "Content-Type: application/json" \
  -d '{"quantity": 5}'

# Delete an item
curl -X DELETE http://localhost:3000/api/items/<id>
```

## Docker Image

The image is published to Docker Hub on every push to `main`:

```
amanajamsheed/nodejs-devops-app:latest
amanajamsheed/nodejs-devops-app:main
amanajamsheed/nodejs-devops-app:sha-<commit>
```
