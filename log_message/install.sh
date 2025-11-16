#!/bin/bash
#
# install.sh - Installation script for log_message.sh
# Supports both system-wide and user-local installation
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="${SCRIPT_DIR}/log_message.sh"

# Installation paths
USER_LOCAL_BIN="${HOME}/.local/bin"
SYSTEM_BIN="/usr/local/bin"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

# Check if PATH contains directory
path_contains() {
    local dir="$1"
    [[ ":${PATH}:" == *":${dir}:"* ]]
}

# Add directory to PATH in shell config
add_to_path() {
    local dir="$1"
    local config_file="$2"
    
    if [[ -z "${config_file}" ]]; then
        echo -e "${YELLOW}Warning: Could not detect shell config file.${NC}"
        echo -e "Please manually add the following to your shell configuration:"
        echo -e "  export PATH=\"\${PATH}:${dir}\""
        return 1
    fi
    
    # Check if already in PATH
    if path_contains "${dir}"; then
        echo -e "${GREEN}✓${NC} ${dir} is already in PATH"
        return 0
    fi
    
    # Backup config file
    if [[ -f "${config_file}" ]]; then
        cp "${config_file}" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Add to PATH
    local path_line="export PATH=\"\${PATH}:${dir}\""
    
    # Check if line already exists
    if grep -q "PATH.*${dir}" "${config_file}" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} PATH entry already exists in ${config_file}"
    else
        echo "" >> "${config_file}"
        echo "# Added by log_message installer" >> "${config_file}"
        echo "${path_line}" >> "${config_file}"
        echo -e "${GREEN}✓${NC} Added ${dir} to PATH in ${config_file}"
    fi
    
    return 0
}

# Install script
install_script() {
    local install_dir="$1"
    local install_path="${install_dir}/log_message.sh"
    local need_sudo="$2"
    
    # Create directory if it doesn't exist
    if [[ "${need_sudo}" == "true" ]]; then
        if [[ ! -d "${install_dir}" ]]; then
            echo -e "${BLUE}Creating directory ${install_dir}...${NC}"
            sudo mkdir -p "${install_dir}"
        fi
        echo -e "${BLUE}Installing to ${install_path}...${NC}"
        sudo cp "${SOURCE_SCRIPT}" "${install_path}"
        sudo chmod +x "${install_path}"
    else
        if [[ ! -d "${install_dir}" ]]; then
            echo -e "${BLUE}Creating directory ${install_dir}...${NC}"
            mkdir -p "${install_dir}"
        fi
        echo -e "${BLUE}Installing to ${install_path}...${NC}"
        cp "${SOURCE_SCRIPT}" "${install_path}"
        chmod +x "${install_path}"
    fi
    
    echo -e "${GREEN}✓${NC} Script installed successfully"
}

# Create wrapper function for sourcing
create_wrapper() {
    local install_dir="$1"
    local wrapper_path="${install_dir}/log_message"
    
    cat > "${wrapper_path}" << 'EOF'
#!/bin/bash
# Wrapper script to source log_message.sh
source "$(dirname "$0")/log_message.sh"
log_message "$@"
EOF
    
    chmod +x "${wrapper_path}"
    echo -e "${GREEN}✓${NC} Created wrapper script"
}

# Main installation function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}log_message.sh Installation${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Check if source script exists
    if [[ ! -f "${SOURCE_SCRIPT}" ]]; then
        echo -e "${RED}Error: ${SOURCE_SCRIPT} not found!${NC}"
        exit 1
    fi
    
    # Detect OS
    local os=$(detect_os)
    echo -e "Detected OS: ${GREEN}${os}${NC}"
    echo ""
    
    # Ask for installation type
    echo -e "Installation type:"
    echo -e "  1) User-local (${USER_LOCAL_BIN}) - Recommended, no sudo required"
    echo -e "  2) System-wide (${SYSTEM_BIN}) - Requires sudo, available to all users"
    echo ""
    read -p "Choose installation type [1/2] (default: 1): " install_choice
    install_choice="${install_choice:-1}"
    
    local install_dir=""
    local need_sudo="false"
    
    case "${install_choice}" in
        1)
            install_dir="${USER_LOCAL_BIN}"
            need_sudo="false"
            ;;
        2)
            install_dir="${SYSTEM_BIN}"
            need_sudo="true"
            if ! command_exists sudo; then
                echo -e "${RED}Error: sudo command not found!${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Invalid choice${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "Installing to: ${BLUE}${install_dir}${NC}"
    echo ""
    
    # Install script
    install_script "${install_dir}" "${need_sudo}"
    
    # Create wrapper
    if [[ "${need_sudo}" == "true" ]]; then
        sudo bash -c "$(declare -f create_wrapper); create_wrapper ${install_dir}"
    else
        create_wrapper "${install_dir}"
    fi
    
    # Add to PATH if user-local
    if [[ "${install_choice}" == "1" ]]; then
        echo ""
        echo -e "${BLUE}Updating PATH...${NC}"
        local config_file=$(get_shell_config)
        add_to_path "${install_dir}" "${config_file}"
    else
        echo ""
        echo -e "${YELLOW}Note: ${SYSTEM_BIN} is typically already in system PATH${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Usage:"
    echo -e "  ${BLUE}source ${install_dir}/log_message.sh${NC}"
    echo -e "  ${BLUE}log_message \"Hello, world!\" --message-type success${NC}"
    echo ""
    echo -e "Or use the wrapper:"
    echo -e "  ${BLUE}${install_dir}/log_message \"Hello, world!\" --message-type success${NC}"
    echo ""
    
    if [[ "${install_choice}" == "1" ]]; then
        echo -e "${YELLOW}Note: You may need to restart your terminal or run:${NC}"
        echo -e "  ${BLUE}source $(get_shell_config)${NC}"
    fi
}

# Run main function
main "$@"

