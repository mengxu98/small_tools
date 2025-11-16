#!/bin/bash
#
# uninstall.sh - Uninstallation script for log_message.sh
# Removes the script and optionally cleans up PATH entries
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
USER_LOCAL_BIN="${HOME}/.local/bin"
SYSTEM_BIN="/usr/local/bin"

# Files to remove
USER_LOCAL_SCRIPT="${USER_LOCAL_BIN}/log_message.sh"
USER_LOCAL_WRAPPER="${USER_LOCAL_BIN}/log_message"
SYSTEM_SCRIPT="${SYSTEM_BIN}/log_message.sh"
SYSTEM_WRAPPER="${SYSTEM_BIN}/log_message"

# Get shell config file
get_shell_config() {
    local shell_name=$(basename "${SHELL}")
    local config_file=""
    
    case "${shell_name}" in
        bash)
            if [[ -f "${HOME}/.bashrc" ]]; then
                config_file="${HOME}/.bashrc"
            elif [[ -f "${HOME}/.bash_profile" ]]; then
                config_file="${HOME}/.bash_profile"
            fi
            ;;
        zsh)
            if [[ -f "${HOME}/.zshrc" ]]; then
                config_file="${HOME}/.zshrc"
            fi
            ;;
    esac
    
    echo "${config_file}"
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Remove PATH entry
remove_from_path() {
    local dir="$1"
    local config_file="$2"
    
    if [[ -z "${config_file}" ]] || [[ ! -f "${config_file}" ]]; then
        return 1
    fi
    
    # Check if PATH entry exists
    if grep -q "PATH.*${dir}" "${config_file}" 2>/dev/null; then
        # Create backup
        cp "${config_file}" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Remove lines containing the PATH entry and installer comment
        sed -i.bak "/# Added by log_message installer/d" "${config_file}"
        sed -i.bak "/PATH.*${dir}/d" "${config_file}"
        
        # Remove backup file created by sed
        rm -f "${config_file}.bak"
        
        echo -e "${GREEN}✓${NC} Removed PATH entry from ${config_file}"
        return 0
    fi
    
    return 1
}

# Main uninstallation function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}log_message.sh Uninstallation${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local found_installation=false
    
    # Check user-local installation
    if file_exists "${USER_LOCAL_SCRIPT}"; then
        found_installation=true
        echo -e "Found user-local installation: ${BLUE}${USER_LOCAL_SCRIPT}${NC}"
        
        read -p "Remove user-local installation? [y/N]: " confirm
        if [[ "${confirm}" =~ ^[Yy]$ ]]; then
            rm -f "${USER_LOCAL_SCRIPT}"
            echo -e "${GREEN}✓${NC} Removed ${USER_LOCAL_SCRIPT}"
            
            if file_exists "${USER_LOCAL_WRAPPER}"; then
                rm -f "${USER_LOCAL_WRAPPER}"
                echo -e "${GREEN}✓${NC} Removed ${USER_LOCAL_WRAPPER}"
            fi
            
            # Remove from PATH
            local config_file=$(get_shell_config)
            if remove_from_path "${USER_LOCAL_BIN}" "${config_file}"; then
                echo -e "${YELLOW}Note: You may need to restart your terminal for PATH changes to take effect${NC}"
            fi
        fi
    fi
    
    # Check system-wide installation
    if file_exists "${SYSTEM_SCRIPT}"; then
        found_installation=true
        echo -e "Found system-wide installation: ${BLUE}${SYSTEM_SCRIPT}${NC}"
        
        if ! command -v sudo >/dev/null 2>&1; then
            echo -e "${YELLOW}Warning: sudo not found. Cannot remove system-wide installation.${NC}"
        else
            read -p "Remove system-wide installation? [y/N]: " confirm
            if [[ "${confirm}" =~ ^[Yy]$ ]]; then
                sudo rm -f "${SYSTEM_SCRIPT}"
                echo -e "${GREEN}✓${NC} Removed ${SYSTEM_SCRIPT}"
                
                if file_exists "${SYSTEM_WRAPPER}"; then
                    sudo rm -f "${SYSTEM_WRAPPER}"
                    echo -e "${GREEN}✓${NC} Removed ${SYSTEM_WRAPPER}"
                fi
            fi
        fi
    fi
    
    if [[ "${found_installation}" == "false" ]]; then
        echo -e "${YELLOW}No installation found.${NC}"
        echo -e "Checked locations:"
        echo -e "  - ${USER_LOCAL_SCRIPT}"
        echo -e "  - ${SYSTEM_SCRIPT}"
        exit 0
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Uninstallation completed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Note: If you modified your shell config, you may want to:${NC}"
    echo -e "  1. Review the backup files created during installation"
    echo -e "  2. Restart your terminal"
}

# Run main function
main "$@"

