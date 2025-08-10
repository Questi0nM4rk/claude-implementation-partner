#!/usr/bin/env bash
set -euo pipefail

# Claude Implementation Partner - Simple Installer
# Only this script in main directory, everything else organized

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
MCP_HOME="$HOME/.mcp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Color functions (inline for simplicity)
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

show_banner() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║          🧠 CLAUDE IMPLEMENTATION PARTNER 🧠               ║
║                                                              ║
║         Argumentative Intelligence for Development           ║
╚════════════════════════════════════════════════════════════════╝
EOF
}

show_help() {
    echo "Usage: ./install.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install   - Install Claude Implementation Partner (default)"
    echo "  start     - Start Docker services"
    echo "  stop      - Stop Docker services"
    echo "  status    - Check service status"
    echo "  clean     - Remove all containers and data"
    echo "  uninstall - Complete uninstall"
    echo "  help      - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./install.sh              # Install everything"
    echo "  ./install.sh start        # Start services"
    echo "  ./install.sh status       # Check health"
    echo "  ./install.sh clean        # Clean up"
}

# Installation functions
do_install() {
    show_banner
    
    log_info "Starting installation..."
    
    # Check prerequisites
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        exit 1
    fi
    
    # Backup existing config
    if [ -d "$CLAUDE_HOME" ]; then
        BACKUP_DIR="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing configuration to $BACKUP_DIR"
        cp -r "$CLAUDE_HOME" "$BACKUP_DIR"
    fi
    
    # Create directories
    log_info "Creating directories..."
    mkdir -p "$CLAUDE_HOME"/{hooks,commands,patterns,scripts}
    mkdir -p "$MCP_HOME"/docker
    
    # Copy configuration files
    log_info "Installing configuration..."
    cp -r "$SCRIPT_DIR/config/claude/"* "$CLAUDE_HOME/" 2>/dev/null || true
    
    # Make all scripts executable
    chmod +x "$SCRIPT_DIR/install.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/scripts/"*.sh 2>/dev/null || true
    
    # Install Docker services with fixed healthchecks
    log_info "Installing Docker services..."
    if [ -f "$SCRIPT_DIR/scripts/docker-setup.sh" ]; then
        "$SCRIPT_DIR/scripts/docker-setup.sh"
    else
        log_error "Docker setup script not found"
        exit 1
    fi
    
    log_success "Installation complete!"
    echo ""
    echo "Next step:"
    echo "  Run: ${GREEN}./install.sh start${NC}"
    echo ""
    echo "This will:"
    echo "  • Start all Docker services"
    echo "  • Download the embedding model automatically"
    echo "  • Make everything ready to use"
    echo ""
    echo "No manual steps needed - everything is automatic!"
}

# Service management
do_start() {
    log_info "Starting services..."
    if [ -f "$SCRIPT_DIR/scripts/service-manager.sh" ]; then
        "$SCRIPT_DIR/scripts/service-manager.sh" start
    else
        log_error "Service manager script not found"
        exit 1
    fi
}

do_stop() {
    log_info "Stopping services..."
    if [ -f "$SCRIPT_DIR/scripts/service-manager.sh" ]; then
        "$SCRIPT_DIR/scripts/service-manager.sh" stop
    else
        log_error "Service manager script not found"
        exit 1
    fi
}

do_status() {
    if [ -f "$SCRIPT_DIR/scripts/service-manager.sh" ]; then
        "$SCRIPT_DIR/scripts/service-manager.sh" status
    else
        log_error "Service manager script not found"
        exit 1
    fi
}

do_clean() {
    log_warn "This will remove all containers and data!"
    read -p "Are you sure? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        if [ -f "$SCRIPT_DIR/scripts/cleanup.sh" ]; then
            # Make sure script is executable
            chmod +x "$SCRIPT_DIR/scripts/cleanup.sh" 2>/dev/null || true
            # Use emergency cleanup to ensure everything is removed
            "$SCRIPT_DIR/scripts/cleanup.sh" emergency
        else
            log_error "Cleanup script not found"
            exit 1
        fi
    fi
}

do_uninstall() {
    log_warn "This will completely uninstall Claude Implementation Partner!"
    read -p "Are you sure? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
        if [ -f "$SCRIPT_DIR/scripts/cleanup.sh" ]; then
            "$SCRIPT_DIR/scripts/cleanup.sh" uninstall
        else
            log_error "Cleanup script not found"
            exit 1
        fi
    fi
}

# Main
main() {
    case "${1:-install}" in
        install)
            do_install
            ;;
        start)
            do_start
            ;;
        stop)
            do_stop
            ;;
        status)
            do_status
            ;;
        clean)
            do_clean
            ;;
        uninstall)
            do_uninstall
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"