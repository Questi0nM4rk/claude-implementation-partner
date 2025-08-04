#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Claude Implementation Partner                    ║"
    echo "║                  Installation Script                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

check_requirements() {
    log_info "🔍 Checking requirements..."
    
    local missing_deps=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        missing_deps+=("docker-compose")
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Check curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them first"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_success "All requirements satisfied"
}

setup_claude_config() {
    log_info "📁 Setting up Claude configuration..."
    
    # Create Claude home directory
    mkdir -p "$CLAUDE_HOME"
    
    # Copy configuration files
    cp "$SCRIPT_DIR/core/config/claude/CLAUDE.md" "$CLAUDE_HOME/"
    cp "$SCRIPT_DIR/core/config/claude/settings.json" "$CLAUDE_HOME/"
    cp "$SCRIPT_DIR/core/config/claude/mcp.json" "$CLAUDE_HOME/"
    
    log_success "Claude configuration installed"
}

setup_environment() {
    log_info "🔐 Setting up environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        cat > "$SCRIPT_DIR/.env" << 'EOF'
# API Keys (optional - set these for full functionality)
PERPLEXITY_API_KEY=
ATLASSIAN_DOMAIN=
ATLASSIAN_EMAIL=
ATLASSIAN_API_TOKEN=
GITLAB_TOKEN=
GITLAB_URL=

# Memory Services (automatically configured)
QDRANT_HOST=localhost
QDRANT_PORT=6333
OLLAMA_HOST=http://localhost:11434
EMBEDDING_MODEL=mxbai-embed-large
MEM0_PORT=8765
EOF
        log_info "Created .env file - you can configure API keys later"
    else
        log_info ".env file already exists"
    fi
}

start_memory_services() {
    log_info "🐳 Starting memory services (Docker)..."
    
    cd "$SCRIPT_DIR/infrastructure/docker"
    
    # Pull images first
    log_info "Pulling Docker images..."
    docker-compose pull
    
    # Build custom images
    log_info "Building Mem0 MCP server..."
    docker-compose build mem0-server
    
    # Start services
    log_info "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    local retries=30
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:6333/health > /dev/null 2>&1 && \
           curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
            break
        fi
        retries=$((retries - 1))
        sleep 2
    done
    
    if [ $retries -eq 0 ]; then
        log_error "Services failed to start properly"
        docker-compose logs
        exit 1
    fi
    
    # Wait for Mem0 server
    log_info "Waiting for Mem0 server..."
    retries=30
    while [ $retries -gt 0 ]; do
        if curl -s http://localhost:8765/health > /dev/null 2>&1; then
            break
        fi
        retries=$((retries - 1))
        sleep 2
    done
    
    if [ $retries -eq 0 ]; then
        log_warn "Mem0 server may not be ready yet - check with: docker-compose logs mem0-server"
    else
        log_success "All memory services are running"
    fi
}

install_ollama_model() {
    log_info "🤖 Installing Ollama embedding model..."
    
    # Try to pull the embedding model
    if docker exec claude-ollama ollama pull mxbai-embed-large; then
        log_success "Embedding model installed"
    else
        log_warn "Failed to install embedding model - it will be downloaded on first use"
    fi
}

test_installation() {
    log_info "🧪 Testing installation..."
    
    # Test memory service
    if curl -s http://localhost:8765/health | grep -q "healthy"; then
        log_success "✓ Memory service is healthy"
    else
        log_warn "✗ Memory service test failed"
    fi
    
    # Test Qdrant
    if curl -s http://localhost:6333/health > /dev/null 2>&1; then
        log_success "✓ Qdrant is running"
    else
        log_warn "✗ Qdrant test failed"
    fi
    
    # Test Ollama
    if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
        log_success "✓ Ollama is running"
    else
        log_warn "✗ Ollama test failed"
    fi
}

show_summary() {
    echo
    log_success "🎉 Installation completed!"
    echo
    echo "📋 What's Running:"
    echo "   • Mem0 MCP Server: http://localhost:8765"
    echo "   • Qdrant Vector DB: http://localhost:6333"
    echo "   • Ollama Embeddings: http://localhost:11434"
    echo
    echo "🚀 Quick Commands:"
    echo "   • Check status: docker-compose -f infrastructure/docker/docker-compose.yml ps"
    echo "   • View logs: docker-compose -f infrastructure/docker/docker-compose.yml logs"
    echo "   • Stop services: docker-compose -f infrastructure/docker/docker-compose.yml down"
    echo
    echo "🔧 Configuration:"
    echo "   • Claude config: ~/.claude/"
    echo "   • Environment: .env"
    echo "   • API keys: Edit .env file for full functionality"
    echo
    echo "📚 Usage:"
    echo "   1. Start Claude Code"
    echo "   2. Try: /impl:brainstorm 'your implementation question'"
    echo "   3. Use: /memory:save-pattern to save useful patterns"
    echo
    echo "💡 Next Steps:"
    echo "   • Configure API keys in .env file"
    echo "   • Test with: claude"
    echo "   • Read docs in docs/ folder"
    echo
}

main() {
    show_header
    check_requirements
    setup_environment
    setup_claude_config
    start_memory_services
    install_ollama_model
    test_installation
    show_summary
}

# Run main installation
main "$@"
