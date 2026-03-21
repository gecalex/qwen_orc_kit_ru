#!/bin/bash
#
# Load Plugin for Qwen Orchestrator Kit
# Загрузка плагина в контекст: проверка зависимостей, активация компонентов
#
# Использование:
#   load-plugin.sh <plugin-name>
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR"
STATE_FILE="$PLUGINS_DIR/.plugin-state.json"
QWEN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[LOAD]${NC} $1"
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

# Check if plugin is enabled
is_enabled() {
    local plugin_name="$1"
    jq -r '.enabled[]' "$STATE_FILE" 2>/dev/null | grep -q "^${plugin_name}$"
}

# Check if plugin is loaded
is_loaded() {
    local plugin_name="$1"
    jq -r '.loaded[]' "$STATE_FILE" 2>/dev/null | grep -q "^${plugin_name}$"
}

# Validate plugin
validate_plugin() {
    local plugin_name="$1"
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    
    if [ ! -d "$plugin_path" ]; then
        log_error "Plugin directory not found: $plugin_path"
        return 1
    fi
    
    if [ ! -f "$plugin_path/plugin.json" ]; then
        log_error "plugin.json not found in $plugin_path"
        return 1
    fi
    
    # Validate JSON
    if ! jq empty "$plugin_path/plugin.json" 2>/dev/null; then
        log_error "Invalid JSON in plugin.json"
        return 1
    fi
    
    return 0
}

# Load plugin components
load_components() {
    local plugin_name="$1"
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    local plugin_file="$plugin_path/plugin.json"
    
    log_info "Loading components for plugin: $plugin_name"
    
    # Load agents
    local agents=$(jq -r '.components.agents[]?.file' "$plugin_file" 2>/dev/null)
    if [ -n "$agents" ]; then
        log_info "Loading agents..."
        for agent_file in $agents; do
            local agent_path="$plugin_path/$agent_file"
            if [ -f "$agent_path" ]; then
                log_success "  Agent: $agent_file"
            else
                log_warning "  Agent not found: $agent_file"
            fi
        done
    fi
    
    # Load commands
    local commands=$(jq -r '.components.commands[]?.file' "$plugin_file" 2>/dev/null)
    if [ -n "$commands" ]; then
        log_info "Loading commands..."
        for cmd_file in $commands; do
            local cmd_path="$plugin_path/$cmd_file"
            if [ -f "$cmd_path" ]; then
                log_success "  Command: $cmd_file"
            else
                log_warning "  Command not found: $cmd_file"
            fi
        done
    fi
    
    # Load skills
    local skills=$(jq -r '.components.skills[]?.file' "$plugin_file" 2>/dev/null)
    if [ -n "$skills" ]; then
        log_info "Loading skills..."
        for skill_file in $skills; do
            local skill_path="$plugin_path/$skill_file"
            if [ -f "$skill_path" ]; then
                log_success "  Skill: $skill_file"
            else
                log_warning "  Skill not found: $skill_file"
            fi
        done
    fi
}

# Load dependencies
load_dependencies() {
    local plugin_name="$1"
    local plugin_file="$PLUGINS_DIR/$plugin_name/plugin.json"
    
    local deps=$(jq -r '.dependencies[]?' "$plugin_file" 2>/dev/null)
    
    for dep in $deps; do
        if ! is_loaded "$dep"; then
            log_info "Loading dependency: $dep"
            load_plugin "$dep"
        else
            log_info "Dependency already loaded: $dep"
        fi
    done
}

# Main load function
load_plugin() {
    local plugin_name="$1"
    
    log_info "Loading plugin: $plugin_name"
    
    # Validate plugin
    if ! validate_plugin "$plugin_name"; then
        return 1
    fi
    
    # Check if enabled
    if ! is_enabled "$plugin_name"; then
        log_error "Plugin '$plugin_name' is not enabled. Run: plugin-manager.sh enable $plugin_name"
        return 1
    fi
    
    # Check if already loaded
    if is_loaded "$plugin_name"; then
        log_warning "Plugin '$plugin_name' is already loaded"
        return 0
    fi
    
    # Load dependencies first
    load_dependencies "$plugin_name"
    
    # Load components
    load_components "$plugin_name"
    
    # Mark as loaded
    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" '.loaded += [$name]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    # Run load script if exists
    local load_script="$PLUGINS_DIR/$plugin_name/scripts/on-load.sh"
    if [ -f "$load_script" ]; then
        log_info "Running on-load script..."
        bash "$load_script"
    fi
    
    log_success "Plugin '$plugin_name' loaded successfully"
}

# Unload plugin
unload_plugin() {
    local plugin_name="$1"
    
    log_info "Unloading plugin: $plugin_name"
    
    # Check if loaded
    if ! is_loaded "$plugin_name"; then
        log_warning "Plugin '$plugin_name' is not loaded"
        return 0
    fi
    
    # Run unload script if exists
    local unload_script="$PLUGINS_DIR/$plugin_name/scripts/on-unload.sh"
    if [ -f "$unload_script" ]; then
        log_info "Running on-unload script..."
        bash "$unload_script"
    fi
    
    # Remove from loaded list
    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" '.loaded -= [$name]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    log_success "Plugin '$plugin_name' unloaded successfully"
}

# List loaded plugins
list_loaded() {
    echo ""
    echo "=== Loaded Plugins ==="
    echo ""
    
    init_state
    local loaded=$(jq -r '.loaded[]' "$STATE_FILE" 2>/dev/null)
    
    if [ -z "$loaded" ]; then
        echo "No plugins loaded"
    else
        for plugin in $loaded; do
            local version=$(jq -r '.version' "$PLUGINS_DIR/$plugin/plugin.json" 2>/dev/null || echo "unknown")
            echo "  - $plugin (v$version)"
        done
    fi
    
    echo ""
}

# Show help
show_help() {
    echo ""
    echo "Load Plugin for Qwen Orchestrator Kit"
    echo ""
    echo "Usage:"
    echo "  load-plugin.sh <plugin-name>          Load a plugin"
    echo "  load-plugin.sh unload <plugin-name>   Unload a plugin"
    echo "  load-plugin.sh list                   List loaded plugins"
    echo "  load-plugin.sh reload <plugin-name>   Reload a plugin"
    echo ""
}

# Main
main() {
    local command="${1:-}"
    local plugin_name="${2:-}"
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed."
        exit 1
    fi
    
    init_state
    
    if [ -z "$command" ]; then
        log_error "Please specify a plugin name"
        show_help
        exit 1
    fi
    
    case "$command" in
        unload)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                exit 1
            fi
            unload_plugin "$plugin_name"
            ;;
        list)
            list_loaded
            ;;
        reload)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                exit 1
            fi
            unload_plugin "$plugin_name"
            load_plugin "$plugin_name"
            ;;
        *)
            # Assume it's a plugin name
            load_plugin "$command"
            ;;
    esac
}

main "$@"
