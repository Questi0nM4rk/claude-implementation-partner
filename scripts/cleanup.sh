#!/usr/bin/env bash
set -euo pipefail

# Comprehensive cleanup script for Claude Implementation Partner

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_HOME="$HOME/.mcp"
CLAUDE_HOME="$HOME/.claude"

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

# Docker cleanup
cleanup_docker() {
    log_info "Cleaning up Docker containers and volumes..."
    
    # Stop and remove containers
    docker stop claude-qdrant claude-ollama claude-mem0 2>/dev/null || true
    docker rm claude-qdrant claude-ollama claude-mem0 2>/dev/null || true
    
    # Remove volumes if doing full cleanup
    if [ "${1:-}" = "full" ]; then
        docker volume rm $(docker volume ls -q | grep -E "(qdrant|ollama|mem0)" 2>/dev/null) 2>/dev/null || true
    fi
    
    log_success "Docker cleanup complete"
}

# Data cleanup
cleanup_data() {
    log_info "Cleaning up data directories..."
    
    rm -rf "$MCP_HOME/data" 2>/dev/null || true
    rm -rf "$HOME/.qdrant" 2>/dev/null || true
    rm -rf "$HOME/.ollama" 2>/dev/null || true
    
    log_success "Data cleanup complete"
}

# Emergency cleanup - force remove everything
emergency_cleanup() {
    log_warn "EMERGENCY CLEANUP - Removing all containers and data!"
    
    # Force stop all containers with claude- prefix
    docker ps -a | grep "claude-" | awk '{print $1}' | xargs -r docker stop 2>/dev/null || true
    docker ps -a | grep "claude-" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
    
    # Remove all related volumes
    docker volume ls | grep -E "(qdrant|ollama|mem0)" | awk '{print $2}' | xargs -r docker volume rm -f 2>/dev/null || true
    
    # Clean data directories
    rm -rf "$MCP_HOME" 2>/dev/null || true
    
    log_success "Emergency cleanup complete"
}

# Full uninstall
uninstall() {
    log_warn "Uninstalling Claude Implementation Partner..."
    
    # Stop services
    cleanup_docker full
    
    # Remove all data
    cleanup_data
    
    # Remove configuration
    rm -rf "$MCP_HOME" 2>/dev/null || true
    
    # Backup Claude config before removing
    if [ -d "$CLAUDE_HOME" ]; then
        BACKUP_DIR="$HOME/.claude-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up Claude config to $BACKUP_DIR"
        cp -r "$CLAUDE_HOME" "$BACKUP_DIR"
        rm -rf "$CLAUDE_HOME"
    fi
    
    log_success "Uninstall complete"
}

# Main
case "${1:-docker}" in
    docker)
        cleanup_docker
        ;;
    data)
        cleanup_data
        ;;
    emergency)
        emergency_cleanup
        ;;
    uninstall)
        uninstall
        ;;
    all)
        cleanup_docker full
        cleanup_data
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Usage: $0 {docker|data|emergency|uninstall|all}"
        exit 1
        ;;
esac