#!/usr/bin/env bash
set -euo pipefail

# Docker Setup Script - Handles all Docker-related installation

MCP_HOME="$HOME/.mcp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create Docker Compose file with FIXED healthchecks
create_docker_compose() {
    log_info "Creating Docker Compose configuration..."
    
    cat > "$MCP_HOME/docker/docker-compose.yml" << 'EOF'
# Claude Implementation Partner - Docker Services
# Fixed healthchecks that actually work

services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: claude-qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_storage:/qdrant/storage
    environment:
      - QDRANT__SERVICE__HTTP_PORT=6333
      - QDRANT__SERVICE__ENABLE_TLS=false
    # Simple healthcheck that works without curl
    healthcheck:
      test: ["CMD-SHELL", "timeout 5 bash -c ':> /dev/tcp/127.0.0.1/6333' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  ollama:
    image: ollama/ollama:latest
    container_name: claude-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    # Simple healthcheck that works
    healthcheck:
      test: ["CMD-SHELL", "timeout 5 bash -c ':> /dev/tcp/127.0.0.1/11434' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  mem0:
    build:
      context: .
      dockerfile: Dockerfile.mem0
    container_name: claude-mem0
    restart: unless-stopped
    ports:
      - "8765:8765"
    environment:
      - QDRANT_HOST=qdrant
      - QDRANT_PORT=6333
      - OLLAMA_HOST=http://ollama:11434
      - EMBEDDING_MODEL=mxbai-embed-large
    depends_on:
      qdrant:
        condition: service_healthy
      ollama:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "python -c 'import requests; requests.get(\"http://localhost:8765/health\")' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

volumes:
  qdrant_storage:
  ollama_models:
EOF
    
    log_success "Docker Compose configuration created"
}

# Create Mem0 Dockerfile
create_mem0_dockerfile() {
    log_info "Creating Mem0 Dockerfile..."
    
    cat > "$MCP_HOME/docker/Dockerfile.mem0" << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including curl for healthchecks
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    mem0ai \
    qdrant-client \
    ollama \
    fastapi \
    uvicorn \
    requests

# Create simple Mem0 server
COPY mem0_server.py .

EXPOSE 8765

# Run the server
CMD ["python", "mem0_server.py"]
EOF
    
    log_success "Mem0 Dockerfile created"
}

# Create Mem0 server script
create_mem0_server() {
    log_info "Creating Mem0 server..."
    
    cat > "$MCP_HOME/docker/mem0_server.py" << 'EOF'
#!/usr/bin/env python3
"""Simple Mem0 server with health endpoint"""

import os
from fastapi import FastAPI
from mem0 import Memory
import uvicorn

app = FastAPI()

# Initialize Mem0
config = {
    "vector_store": {
        "provider": "qdrant",
        "config": {
            "host": os.getenv("QDRANT_HOST", "qdrant"),
            "port": int(os.getenv("QDRANT_PORT", 6333))
        }
    },
    "embedder": {
        "provider": "ollama",
        "config": {
            "model": os.getenv("EMBEDDING_MODEL", "mxbai-embed-large"),
            "ollama_base_url": os.getenv("OLLAMA_HOST", "http://ollama:11434")
        }
    }
}

try:
    memory = Memory.from_config(config)
    mem0_healthy = True
except Exception as e:
    print(f"Failed to initialize Mem0: {e}")
    mem0_healthy = False

@app.get("/health")
async def health():
    return {"status": "healthy" if mem0_healthy else "unhealthy"}

@app.get("/")
async def root():
    return {"service": "Mem0 Memory Server", "status": "running"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8765)
EOF
    
    log_success "Mem0 server created"
}

# Create .env template
create_env_template() {
    log_info "Creating environment template..."
    
    cat > "$MCP_HOME/docker/.env.template" << 'EOF'
# Claude Implementation Partner - Environment Variables

# API Keys (optional)
PERPLEXITY_API_KEY=
GITHUB_TOKEN=

# Database (if using PostgreSQL)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# Service Ports (defaults)
QDRANT_PORT=6333
OLLAMA_PORT=11434
MEM0_PORT=8765
EOF
    
    # Copy to .env if doesn't exist
    if [ ! -f "$MCP_HOME/docker/.env" ]; then
        cp "$MCP_HOME/docker/.env.template" "$MCP_HOME/docker/.env"
        log_info "Created .env file (configure API keys if needed)"
    fi
}

# Note: Model will be pulled after services start

# Main setup
main() {
    log_info "Setting up Docker services..."
    
    # Create directory
    mkdir -p "$MCP_HOME/docker"
    
    # Create all files
    create_docker_compose
    create_mem0_dockerfile
    create_mem0_server
    create_env_template
    
    log_success "Docker setup complete!"
    log_info "Services configured in: $MCP_HOME/docker/"
}

main "$@"