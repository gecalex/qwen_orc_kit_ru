#!/bin/bash
#
# Plugin Manager for Qwen Orchestrator Kit
# Управление плагинами: установка, удаление, включение, выключение
#
# Использование:
#   plugin-manager.sh install <plugin-name>
#   plugin-manager.sh uninstall <plugin-name>
#   plugin-manager.sh enable <plugin-name>
#   plugin-manager.sh disable <plugin-name>
#   plugin-manager.sh list [--installed|--available]
#   plugin-manager.sh info <plugin-name>
#   plugin-manager.sh update <plugin-name>
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR"
REGISTRY_FILE="$PLUGINS_DIR/plugin-registry.json"
STATE_FILE="$PLUGINS_DIR/.plugin-state.json"
QWEN_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize state file if not exists
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"installed": [], "enabled": [], "disabled": []}' > "$STATE_FILE"
    fi
}

# Get installed plugins
get_installed_plugins() {
    init_state
    jq -r '.installed[]' "$STATE_FILE" 2>/dev/null || echo ""
}

# Get enabled plugins
get_enabled_plugins() {
    init_state
    jq -r '.enabled[]' "$STATE_FILE" 2>/dev/null || echo ""
}

# Check if plugin is installed
is_installed() {
    local plugin_name="$1"
    get_installed_plugins | grep -q "^${plugin_name}$"
}

# Check if plugin is enabled
is_enabled() {
    local plugin_name="$1"
    get_enabled_plugins | grep -q "^${plugin_name}$"
}

# Validate plugin exists
validate_plugin() {
    local plugin_name="$1"
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    
    if [ ! -d "$plugin_path" ]; then
        log_error "Plugin '$plugin_name' not found in $plugin_path"
        return 1
    fi
    
    if [ ! -f "$plugin_path/plugin.json" ]; then
        log_error "plugin.json not found in $plugin_path"
        return 1
    fi
    
    return 0
}

# Install plugin
install_plugin() {
    local plugin_name="$1"
    
    log_info "Installing plugin: $plugin_name"
    
    # Validate plugin
    if ! validate_plugin "$plugin_name"; then
        return 1
    fi
    
    # Check if already installed
    if is_installed "$plugin_name"; then
        log_warning "Plugin '$plugin_name' is already installed"
        return 0
    fi
    
    # Check dependencies
    check_dependencies "$plugin_name"
    
    # Add to installed list
    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" '.installed += [$name]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    # Enable by default
    enable_plugin "$plugin_name" false
    
    log_success "Plugin '$plugin_name' installed successfully"
    
    # Show plugin info
    show_plugin_info "$plugin_name"
}

# Uninstall plugin
uninstall_plugin() {
    local plugin_name="$1"
    
    log_info "Uninstalling plugin: $plugin_name"
    
    # Check if installed
    if ! is_installed "$plugin_name"; then
        log_error "Plugin '$plugin_name' is not installed"
        return 1
    fi
    
    # Check if other plugins depend on this
    local dependents=$(get_dependent_plugins "$plugin_name")
    if [ -n "$dependents" ]; then
        log_warning "The following plugins depend on '$plugin_name':"
        echo "$dependents"
        read -p "Continue anyway? (y/N) " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Uninstall cancelled"
            return 1
        fi
    fi
    
    # Remove from installed list
    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" '.installed -= [$name] | .enabled -= [$name] | .disabled -= [$name]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    log_success "Plugin '$plugin_name' uninstalled successfully"
}

# Enable plugin
enable_plugin() {
    local plugin_name="$1"
    local silent="${2:-false}"
    
    if [ "$silent" != "false" ]; then
        log_info "Enabling plugin: $plugin_name"
    fi
    
    # Check if installed
    if ! is_installed "$plugin_name"; then
        log_error "Plugin '$plugin_name' is not installed. Run: plugin-manager.sh install $plugin_name"
        return 1
    fi
    
    # Check if already enabled
    if is_enabled "$plugin_name"; then
        if [ "$silent" != "false" ]; then
            log_warning "Plugin '$plugin_name' is already enabled"
        fi
        return 0
    fi
    
    # Enable dependencies first
    local deps=$(get_plugin_dependencies "$plugin_name")
    for dep in $deps; do
        if ! is_enabled "$dep"; then
            enable_plugin "$dep" true
        fi
    done
    
    # Add to enabled list, remove from disabled
    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" '.enabled += [$name] | .disabled -= [$name]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    # Run onEnable script if exists
    local on_enable_script="$PLUGINS_DIR/$plugin_name/scripts/on-enable.sh"
    if [ -f "$on_enable_script" ]; then
        log_info "Running on-enable script..."
        bash "$on_enable_script"
    fi
    
    if [ "$silent" != "false" ]; then
        log_success "Plugin '$plugin_name' enabled successfully"
    fi
}

# Disable plugin
disable_plugin() {
    local plugin_name="$1"
    
    log_info "Disabling plugin: $plugin_name"
    
    # Check if installed
    if ! is_installed "$plugin_name"; then
        log_error "Plugin '$plugin_name' is not installed"
        return 1
    fi
    
    # Check if already disabled
    if ! is_enabled "$plugin_name"; then
        log_warning "Plugin '$plugin_name' is already disabled"
        return 0
    fi
    
    # Remove from enabled list, add to disabled
    local temp_file=$(mktemp)
    jq --arg name "$plugin_name" '.enabled -= [$name] | .disabled += [$name]' "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
    
    # Run onDisable script if exists
    local on_disable_script="$PLUGINS_DIR/$plugin_name/scripts/on-disable.sh"
    if [ -f "$on_disable_script" ]; then
        log_info "Running on-disable script..."
        bash "$on_disable_script"
    fi
    
    log_success "Plugin '$plugin_name' disabled successfully"
}

# List plugins
list_plugins() {
    local filter="${1:-all}"
    
    echo ""
    echo "=== Plugin Manager ==="
    echo ""
    
    case "$filter" in
        --installed)
            echo "Installed Plugins:"
            echo "------------------"
            for plugin in $(get_installed_plugins); do
                local status="installed"
                if is_enabled "$plugin"; then
                    status="enabled"
                else
                    status="disabled"
                fi
                local version=$(jq -r '.version' "$PLUGINS_DIR/$plugin/plugin.json" 2>/dev/null || echo "unknown")
                echo "  - $plugin (v$version) [$status]"
            done
            ;;
        --available)
            echo "Available Plugins:"
            echo "------------------"
            for plugin_dir in "$PLUGINS_DIR"/*/; do
                if [ -f "${plugin_dir}plugin.json" ]; then
                    local plugin_name=$(basename "$plugin_dir")
                    local version=$(jq -r '.version' "${plugin_dir}plugin.json" 2>/dev/null || echo "unknown")
                    local installed=""
                    if is_installed "$plugin_name"; then
                        installed=" [installed]"
                    fi
                    echo "  - $plugin_name (v$version)$installed"
                fi
            done
            ;;
        *)
            # Show all with status
            echo "All Plugins:"
            echo "------------"
            for plugin_dir in "$PLUGINS_DIR"/*/; do
                if [ -f "${plugin_dir}plugin.json" ]; then
                    local plugin_name=$(basename "$plugin_dir")
                    local version=$(jq -r '.version' "${plugin_dir}plugin.json" 2>/dev/null || echo "unknown")
                    local description=$(jq -r '.description' "${plugin_dir}plugin.json" 2>/dev/null || echo "")
                    local status=""
                    if is_enabled "$plugin_name"; then
                        status="✅ enabled"
                    elif is_installed "$plugin_name"; then
                        status="⏸️  disabled"
                    else
                        status="⭕ not installed"
                    fi
                    echo ""
                    echo "  $plugin_name (v$version)"
                    echo "    $description"
                    echo "    Status: $status"
                fi
            done
            ;;
    esac
    
    echo ""
}

# Show plugin info
show_plugin_info() {
    local plugin_name="$1"
    
    if ! validate_plugin "$plugin_name" 2>/dev/null; then
        log_error "Plugin '$plugin_name' not found"
        return 1
    fi
    
    local plugin_file="$PLUGINS_DIR/$plugin_name/plugin.json"
    
    echo ""
    echo "=== Plugin: $plugin_name ==="
    echo ""
    jq -r '"Name: \(.displayName)
Version: \(.version)
Description: \(.description)
Author: \(.author)
License: \(.license)
Category: \(.category)
Tags: \(.tags | join(", "))
Dependencies: \(if .dependencies | length > 0 then .dependencies | join(", ") else "none" end)"' "$plugin_file"
    
    echo ""
    echo "Components:"
    jq -r '
        .components.agents[]? | "  🤖 Agent: \(.name) - \(.description)"
    ' "$plugin_file"
    
    jq -r '
        .components.commands[]? | "  ⚙️  Command: \(.name) - \(.description)"
    ' "$plugin_file"
    
    jq -r '
        .components.skills[]? | "  📚 Skill: \(.name) - \(.description)"
    ' "$plugin_file"
    
    echo ""
    
    local status=""
    if is_enabled "$plugin_name"; then
        status="✅ Enabled"
    elif is_installed "$plugin_name"; then
        status="⏸️  Disabled"
    else
        status="⭕ Not Installed"
    fi
    echo "Status: $status"
    echo ""
}

# Get plugin dependencies
get_plugin_dependencies() {
    local plugin_name="$1"
    local plugin_file="$PLUGINS_DIR/$plugin_name/plugin.json"
    
    if [ -f "$plugin_file" ]; then
        jq -r '.dependencies[]?' "$plugin_file" 2>/dev/null || echo ""
    fi
}

# Get plugins that depend on this plugin
get_dependent_plugins() {
    local target_plugin="$1"
    local dependents=""
    
    for plugin_dir in "$PLUGINS_DIR"/*/; do
        if [ -f "${plugin_dir}plugin.json" ]; then
            local plugin_name=$(basename "$plugin_dir")
            local deps=$(jq -r '.dependencies[]?' "${plugin_dir}plugin.json" 2>/dev/null)
            if echo "$deps" | grep -q "^${target_plugin}$"; then
                dependents="$dependents$plugin_name\n"
            fi
        fi
    done
    
    echo -e "$dependents"
}

# Check dependencies before install
check_dependencies() {
    local plugin_name="$1"
    local deps=$(get_plugin_dependencies "$plugin_name")
    
    for dep in $deps; do
        if ! is_installed "$dep"; then
            log_warning "Dependency '$dep' is not installed"
            read -p "Install '$dep' now? (Y/n) " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]] || [[ -z "$confirm" ]]; then
                install_plugin "$dep"
            else
                log_error "Cannot install '$plugin_name' without dependency '$dep'"
                return 1
            fi
        fi
    done
}

# Update plugin
update_plugin() {
    local plugin_name="$1"
    
    log_info "Updating plugin: $plugin_name"
    
    # Check if installed
    if ! is_installed "$plugin_name"; then
        log_error "Plugin '$plugin_name' is not installed"
        return 1
    fi
    
    # In a real implementation, this would fetch from a remote registry
    # For now, just re-validate the local plugin
    if validate_plugin "$plugin_name"; then
        log_success "Plugin '$plugin_name' is up to date"
    else
        log_error "Failed to update plugin '$plugin_name'"
        return 1
    fi
}

# Show help
show_help() {
    echo ""
    echo "Plugin Manager for Qwen Orchestrator Kit"
    echo ""
    echo "Usage:"
    echo "  plugin-manager.sh install <plugin-name>     Install a plugin"
    echo "  plugin-manager.sh uninstall <plugin-name>   Uninstall a plugin"
    echo "  plugin-manager.sh enable <plugin-name>      Enable a plugin"
    echo "  plugin-manager.sh disable <plugin-name>     Disable a plugin"
    echo "  plugin-manager.sh list [options]            List plugins"
    echo "  plugin-manager.sh info <plugin-name>        Show plugin info"
    echo "  plugin-manager.sh update <plugin-name>      Update a plugin"
    echo ""
    echo "Options:"
    echo "  --installed    Show only installed plugins"
    echo "  --available    Show only available plugins"
    echo ""
    echo "Examples:"
    echo "  plugin-manager.sh install python-development"
    echo "  plugin-manager.sh list --installed"
    echo "  plugin-manager.sh info security-scanning"
    echo ""
}

# Main command handler
main() {
    local command="${1:-help}"
    local plugin_name="${2:-}"
    local option="${3:-}"
    
    # Check for jq
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    init_state
    
    case "$command" in
        install)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            install_plugin "$plugin_name"
            ;;
        uninstall)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            uninstall_plugin "$plugin_name"
            ;;
        enable)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            enable_plugin "$plugin_name"
            ;;
        disable)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            disable_plugin "$plugin_name"
            ;;
        list)
            list_plugins "$plugin_name"
            ;;
        info)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            show_plugin_info "$plugin_name"
            ;;
        update)
            if [ -z "$plugin_name" ]; then
                log_error "Please specify a plugin name"
                show_help
                exit 1
            fi
            update_plugin "$plugin_name"
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

# Run main
main "$@"
