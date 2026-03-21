#!/bin/bash
#
# Plugin Dependencies for Qwen Orchestrator Kit
# Анализ зависимостей, разрешение конфликтов, автоустановка
#
# Использование:
#   plugin-dependencies.sh check <plugin-name>
#   plugin-dependencies.sh resolve <plugin-name>
#   plugin-dependencies graph
#   plugin-dependencies conflicts
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR"
STATE_FILE="$PLUGINS_DIR/.plugin-state.json"
REGISTRY_FILE="$PLUGINS_DIR/plugin-registry.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[DEPS]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize state
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"installed": [], "enabled": [], "disabled": [], "loaded": []}' > "$STATE_FILE"
    fi
}

# Check if plugin is installed
is_installed() {
    local plugin_name="$1"
    jq -r '.installed[]' "$STATE_FILE" 2>/dev/null | grep -q "^${plugin_name}$"
}

# Get plugin dependencies
get_dependencies() {
    local plugin_name="$1"
    local plugin_file="$PLUGINS_DIR/$plugin_name/plugin.json"
    
    if [ -f "$plugin_file" ]; then
        jq -r '.dependencies[]?' "$plugin_file" 2>/dev/null || echo ""
    fi
}

# Get optional dependencies
get_optional_dependencies() {
    local plugin_name="$1"
    local plugin_file="$PLUGINS_DIR/$plugin_name/plugin.json"
    
    if [ -f "$plugin_file" ]; then
        jq -r '.optionalDependencies[]?' "$plugin_file" 2>/dev/null || echo ""
    fi
}

# Get all dependencies recursively
get_all_dependencies() {
    local plugin_name="$1"
    local visited="$2"
    
    # Prevent infinite loops
    if echo "$visited" | grep -q ":${plugin_name}:"; then
        return
    fi
    visited="${visited}:${plugin_name}:"
    
    local deps=$(get_dependencies "$plugin_name")
    for dep in $deps; do
        echo "$dep"
        get_all_dependencies "$dep" "$visited"
    done
}

# Check dependencies for a plugin
check_dependencies() {
    local plugin_name="$1"
    local missing=()
    local optional_missing=()
    
    log_info "Checking dependencies for: $plugin_name"
    
    # Get required dependencies
    local deps=$(get_dependencies "$plugin_name")
    for dep in $deps; do
        if ! is_installed "$dep"; then
            missing+=("$dep")
            log_error "Missing required dependency: $dep"
        else
            log_success "Dependency satisfied: $dep"
        fi
    done
    
    # Get optional dependencies
    local optional_deps=$(get_optional_dependencies "$plugin_name")
    for dep in $optional_deps; do
        if ! is_installed "$dep"; then
            optional_missing+=("$dep")
            log_warning "Optional dependency not installed: $dep"
        else
            log_success "Optional dependency installed: $dep"
        fi
    done
    
    # Check for conflicts
    check_conflicts "$plugin_name"
    
    # Summary
    echo ""
    if [ ${#missing[@]} -eq 0 ]; then
        log_success "All required dependencies satisfied"
    else
        log_error "Missing ${#missing[@]} required dependencies: ${missing[*]}"
        return 1
    fi
    
    if [ ${#optional_missing[@]} -gt 0 ]; then
        log_warning "Missing ${#optional_missing[@]} optional dependencies: ${optional_missing[*]}"
    fi
    
    return 0
}

# Check for conflicts
check_conflicts() {
    local plugin_name="$1"
    local plugin_file="$PLUGINS_DIR/$plugin_name/plugin.json"
    
    if [ ! -f "$plugin_file" ]; then
        return 0
    fi
    
    local conflicts=$(jq -r '.conflicts[]?' "$plugin_file" 2>/dev/null)
    
    for conflict in $conflicts; do
        if is_installed "$conflict"; then
            log_error "Conflict detected: $plugin_name conflicts with installed plugin $conflict"
            return 1
        fi
    done
    
    return 0
}

# Resolve dependencies (auto-install)
resolve_dependencies() {
    local plugin_name="$1"
    
    log_info "Resolving dependencies for: $plugin_name"
    
    # Get all dependencies recursively
    local all_deps=$(get_all_dependencies "$plugin_name" "")
    
    local to_install=()
    for dep in $all_deps; do
        if ! is_installed "$dep"; then
            to_install+=("$dep")
        fi
    done
    
    if [ ${#to_install[@]} -eq 0 ]; then
        log_success "All dependencies already installed"
        return 0
    fi
    
    echo ""
    log_info "Plugins to install: ${to_install[*]}"
    echo ""
    
    # Confirm installation
    read -p "Install these dependencies? (Y/n) " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled"
        return 1
    fi
    
    # Install each dependency
    for dep in "${to_install[@]}"; do
        log_info "Installing: $dep"
        "$SCRIPT_DIR/plugin-manager.sh" install "$dep"
    done
    
    log_success "All dependencies installed successfully"
}

# Generate dependency graph
generate_graph() {
    echo ""
    echo "=== Plugin Dependency Graph ==="
    echo ""
    
    for plugin_dir in "$PLUGINS_DIR"/*/; do
        if [ -f "${plugin_dir}plugin.json" ]; then
            local plugin_name=$(basename "$plugin_dir")
            local deps=$(get_dependencies "$plugin_name")
            local optional_deps=$(get_optional_dependencies "$plugin_name")
            
            if [ -n "$deps" ] || [ -n "$optional_deps" ]; then
                echo "$plugin_name"
                for dep in $deps; do
                    echo "  ├── $dep (required)"
                done
                for dep in $optional_deps; do
                    echo "  └── $dep (optional)"
                done
                echo ""
            fi
        fi
    done
}

# List conflicts
list_conflicts() {
    echo ""
    echo "=== Plugin Conflicts ==="
    echo ""
    
    local found_conflicts=false
    
    for plugin_dir in "$PLUGINS_DIR"/*/; do
        if [ -f "${plugin_dir}plugin.json" ]; then
            local plugin_name=$(basename "$plugin_dir")
            local conflicts=$(jq -r '.conflicts[]?' "${plugin_dir}plugin.json" 2>/dev/null)
            
            if [ -n "$conflicts" ]; then
                echo "$plugin_name conflicts with:"
                for conflict in $conflicts; do
                    local status="not installed"
                    if is_installed "$conflict"; then
                        status="INSTALLED"
                    fi
                    echo "  - $conflict [$status]"
                done
                echo ""
                found_conflicts=true
            fi
        fi
    done
    
    if [ "$found_conflicts" = false ]; then
        echo "No conflicts found"
    fi
    
    echo ""
}

# Show dependency tree for a plugin
show_tree() {
    local plugin_name="$1"
    
    echo ""
    echo "=== Dependency Tree: $plugin_name ==="
    echo ""
    
    print_tree "$plugin_name" ""
    
    echo ""
}

print_tree() {
    local plugin_name="$1"
    local prefix="$2"
    
    local installed=""
    if is_installed "$plugin_name"; then
        installed=" ✅"
    fi
    
    echo "${prefix}├── $plugin_name${installed}"
    
    local deps=$(get_dependencies "$plugin_name")
    local dep_array=($deps)
    local count=${#dep_array[@]}
    local i=0
    
    for dep in $deps; do
        i=$((i + 1))
        if [ $i -eq $count ]; then
            print_tree "$dep" "${prefix}│   "
        else
            print_tree "$dep" "${prefix}│   "
        fi
    done
}

# Show help
show_help() {
    echo ""
    echo "Plugin Dependencies for Qwen Orchestrator Kit"
    echo ""
    echo "Usage:"
    echo "  plugin-dependencies.sh check <plugin-name>    Check dependencies"
    echo "  plugin-dependencies.sh resolve <plugin-name>  Resolve/install dependencies"
    echo "  plugin-dependencies.sh tree <plugin-name>     Show dependency tree"
    echo "  plugin-dependencies.sh graph                  Show dependency graph"
    echo "  plugin-dependencies.sh conflicts              List conflicts"
    echo ""
}

# Main
main() {
    local command="${1:-help}"
    local plugin_name="${2:-}"
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed."
        exit 1
    fi
    
    init_state
    
    case "$command" in
        check)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            check_dependencies "$plugin_name"
            ;;
        resolve)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            resolve_dependencies "$plugin_name"
            ;;
        tree)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            show_tree "$plugin_name"
            ;;
        graph)
            generate_graph
            ;;
        conflicts)
            list_conflicts
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
