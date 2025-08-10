#!/usr/bin/env bash
set -euo pipefail

# Service Manager - Handles Docker service operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_HOME="$HOME/.mcp"
COMPOSE_FILE="$MCP_HOME/docker/docker-compose.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check if docker-compose file exists
check_compose() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "Docker Compose file not found at $COMPOSE_FILE"
        log_info "Run './install.sh install' first"
        exit 1
    fi
}

# Start services
start_services() {
    check_compose
    
    log_info "Starting Claude Implementation Partner services..."
    
    # Check for existing containers first
    if docker ps -a | grep -qE "(claude-qdrant|claude-ollama|claude-mem0)"; then
        log_warn "Found existing containers. Cleaning up first..."
        "$SCRIPT_DIR/cleanup.sh" docker
    fi
    
    cd "$MCP_HOME/docker"
    
    # Start services
    docker compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 5
    
    # Wait for Ollama to be fully ready before installing model
    log_info "Waiting for Ollama to be ready..."
    for i in {1..30}; do
        if docker exec claude-ollama ollama list &>/dev/null; then
            break
        fi
        sleep 2
    done
    
    # Install embedding model if not present
    log_info "Checking embedding model..."
    if docker exec claude-ollama ollama list 2>/dev/null | grep -q "mxbai-embed-large"; then
        log_success "Embedding model already installed"
    else
        log_info "Installing mxbai-embed-large embedding model (this may take a few minutes)..."
        # Retry up to 3 times with proper error handling
        local max_attempts=3
        for attempt in $(seq 1 $max_attempts); do
            if docker exec claude-ollama ollama pull mxbai-embed-large; then
                log_success "Embedding model installed successfully"
                break
            else
                if [ $attempt -lt $max_attempts ]; then
                    log_warn "Attempt $attempt failed, retrying..."
                    sleep 5
                else
                    log_error "Failed to install embedding model after $max_attempts attempts"
                    log_info "You can manually install it later with:"
                    log_info "  docker exec claude-ollama ollama pull mxbai-embed-large"
                fi
            fi
        done
    fi
    
    # Check status
    if docker compose ps --format json 2>/dev/null | grep -q '"State":"running"' || 
       docker compose ps 2>/dev/null | grep -qE "(running|healthy|Up)"; then
        log_success "Services started successfully!"
        
        echo ""
        echo "📊 Service URLs:"
        echo "  • Qdrant Dashboard: http://localhost:6333/dashboard"
        echo "  • Ollama API:       http://localhost:11434"
        echo "  • Mem0 API:         http://localhost:8765"
    else
        # Double-check by looking for container names
        if docker ps | grep -qE "(claude-qdrant|claude-ollama|claude-mem0)"; then
            log_success "Services are running!"
            
            echo ""
            echo "📊 Service URLs:"
            echo "  • Qdrant Dashboard: http://localhost:6333/dashboard"
            echo "  • Ollama API:       http://localhost:11434"
            echo "  • Mem0 API:         http://localhost:8765"
        else
            log_error "Some services may have issues"
            docker compose logs --tail=20
        fi
    fi
}

# Stop services
stop_services() {
    check_compose
    
    log_info "Stopping services..."
    
    cd "$MCP_HOME/docker"
    docker compose down
    
    log_success "Services stopped"
}

# Check status
check_status() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          Claude Implementation Partner                  ║"
    echo "║                Service Status                           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "Services not installed"
        return
    fi
    
    cd "$MCP_HOME/docker"
    
    # Show container status
    echo "🐳 Docker Containers:"
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || {
        log_warn "No containers running"
        return
    }
    
    echo ""
    echo "🔍 Service Health:"
    
    # Check Qdrant
    if curl -s http://localhost:6333/health > /dev/null 2>&1; then
        echo -e "  • Qdrant:    ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  • Qdrant:    ${RED}✗ Not responding${NC}"
    fi
    
    # Check Ollama
    if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
        echo -e "  • Ollama:    ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  • Ollama:    ${RED}✗ Not responding${NC}"
    fi
    
    # Check Mem0
    if curl -s http://localhost:8765/health > /dev/null 2>&1; then
        echo -e "  • Mem0:      ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  • Mem0:      ${RED}✗ Not responding${NC}"
    fi
    
    echo ""
    
    # Check for embedding model
    if docker exec claude-ollama ollama list 2>/dev/null | grep -q "mxbai-embed-large"; then
        echo -e "📦 Embedding Model: ${GREEN}✓ Installed${NC}"
    else
        echo -e "📦 Embedding Model: ${YELLOW}⚠ Not installed${NC}"
        echo "   Run './install.sh start' to install the model automatically"
    fi
}

# Restart services
restart_services() {
    log_info "Restarting services..."
    stop_services
    sleep 2
    start_services
}

# View logs
view_logs() {
    check_compose
    
    SERVICE="${2:-}"
    
    cd "$MCP_HOME/docker"
    
    if [ -z "$SERVICE" ]; then
        docker compose logs --tail=100 -f
    else
        docker compose logs --tail=100 -f "$SERVICE"
    fi
}

# Main
case "${1:-status}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        check_status
        ;;
    logs)
        view_logs "$@"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Usage: $0 {start|stop|restart|status|logs [service]}"
        exit 1
        ;;
esac