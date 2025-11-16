#!/bin/bash
#
# log_message.sh - Shell implementation of R log_message function
# Provides formatted message printing with colors, styles, timestamps, and indentation
#

# Default values
_LOG_MESSAGE_VERBOSE="${LOG_MESSAGE_VERBOSE:-true}"
_LOG_MESSAGE_CLI_MODEL="${LOG_MESSAGE_CLI_MODEL:-true}"
_LOG_MESSAGE_TIMESTAMP="${LOG_MESSAGE_TIMESTAMP:-true}"
_LOG_MESSAGE_TIMESTAMP_FORMAT="${LOG_MESSAGE_TIMESTAMP_FORMAT:-%Y-%m-%d %H:%M:%S}"
_LOG_MESSAGE_TIMESTAMP_STYLE="${LOG_MESSAGE_TIMESTAMP_STYLE:-true}"
_LOG_MESSAGE_LEVEL="${LOG_MESSAGE_LEVEL:-1}"
_LOG_MESSAGE_SYMBOL="${LOG_MESSAGE_SYMBOL:-  }"

# ANSI color codes
_ANSI_RESET="\033[0m"
_ANSI_BOLD="\033[1m"
_ANSI_DIM="\033[2m"
_ANSI_UNDERLINE="\033[4m"
_ANSI_STRIKETHROUGH="\033[9m"
_ANSI_INVERSE="\033[7m"

# Check if terminal supports colors
_supports_colors() {
    if [[ -t 1 ]] && [[ "${TERM}" != "dumb" ]]; then
        if command -v tput >/dev/null 2>&1; then
            local colors=$(tput colors 2>/dev/null || echo "0")
            [[ "$colors" -ge 8 ]]
        else
            [[ -n "${TERM}" ]] && [[ "${TERM}" != "dumb" ]]
        fi
    else
        return 1
    fi
}

# Get verbose option
_get_verbose() {
    local verbose="${1:-}"
    
    if [[ -n "${LOG_MESSAGE_VERBOSE}" ]]; then
        if [[ "${LOG_MESSAGE_VERBOSE}" == "true" ]] || [[ "${LOG_MESSAGE_VERBOSE}" == "1" ]]; then
            verbose="true"
        elif [[ "${LOG_MESSAGE_VERBOSE}" == "false" ]] || [[ "${LOG_MESSAGE_VERBOSE}" == "0" ]]; then
            verbose="false"
        fi
    fi
    
    if [[ -z "${verbose}" ]]; then
        verbose="true"
    fi
    
    [[ "${verbose}" == "true" ]] || [[ "${verbose}" == "1" ]]
}

# Check if color is valid
_check_color() {
    local color="$1"
    
    if [[ -z "${color}" ]]; then
        return 1
    fi
    
    # Named colors
    local valid_colors=(
        "black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"
        "grey" "gray" "silver" "none"
        "br_black" "br_red" "br_green" "br_yellow" "br_blue"
        "br_magenta" "br_cyan" "br_white"
    )
    
    for valid_color in "${valid_colors[@]}"; do
        if [[ "${color}" == "${valid_color}" ]]; then
            return 0
        fi
    done
    
    # Hex color format
    if [[ "${color}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        return 0
    fi
    
    return 1
}

# Convert hex color to ANSI 256-color code
_hex_to_ansi() {
    local hex="$1"
    local bg="${2:-false}"
    
    # Remove # if present
    hex="${hex#\#}"
    
    # Extract RGB components
    local r=$((0x${hex:0:2}))
    local g=$((0x${hex:2:2}))
    local b=$((0x${hex:4:2}))
    
    # Convert to 256-color palette
    # Using the 6x6x6 color cube formula
    local r_idx=$((r * 5 / 255))
    local g_idx=$((g * 5 / 255))
    local b_idx=$((b * 5 / 255))
    local color_code=$((16 + 36 * r_idx + 6 * g_idx + b_idx))
    
    if [[ "${bg}" == "true" ]]; then
        echo "\033[48;5;${color_code}m"
    else
        echo "\033[38;5;${color_code}m"
    fi
}

# Make color style function
_make_color_style() {
    local color="$1"
    local bg="${2:-false}"
    
    if ! _supports_colors; then
        echo ""
        return
    fi
    
    # Named colors
    case "${color}" in
        black)
            [[ "${bg}" == "true" ]] && echo "\033[40m" || echo "\033[30m"
            ;;
        red)
            [[ "${bg}" == "true" ]] && echo "\033[41m" || echo "\033[31m"
            ;;
        green)
            [[ "${bg}" == "true" ]] && echo "\033[42m" || echo "\033[32m"
            ;;
        yellow)
            [[ "${bg}" == "true" ]] && echo "\033[43m" || echo "\033[33m"
            ;;
        blue)
            [[ "${bg}" == "true" ]] && echo "\033[44m" || echo "\033[34m"
            ;;
        magenta)
            [[ "${bg}" == "true" ]] && echo "\033[45m" || echo "\033[35m"
            ;;
        cyan)
            [[ "${bg}" == "true" ]] && echo "\033[46m" || echo "\033[36m"
            ;;
        white)
            [[ "${bg}" == "true" ]] && echo "\033[47m" || echo "\033[37m"
            ;;
        grey|gray)
            [[ "${bg}" == "true" ]] && echo "\033[100m" || echo "\033[90m"
            ;;
        silver)
            [[ "${bg}" == "true" ]] && echo "\033[47m" || echo "\033[37m"
            ;;
        none)
            echo ""
            ;;
        br_black)
            [[ "${bg}" == "true" ]] && echo "\033[100m" || echo "\033[90m"
            ;;
        br_red)
            [[ "${bg}" == "true" ]] && echo "\033[101m" || echo "\033[91m"
            ;;
        br_green)
            [[ "${bg}" == "true" ]] && echo "\033[102m" || echo "\033[92m"
            ;;
        br_yellow)
            [[ "${bg}" == "true" ]] && echo "\033[103m" || echo "\033[93m"
            ;;
        br_blue)
            [[ "${bg}" == "true" ]] && echo "\033[104m" || echo "\033[94m"
            ;;
        br_magenta)
            [[ "${bg}" == "true" ]] && echo "\033[105m" || echo "\033[95m"
            ;;
        br_cyan)
            [[ "${bg}" == "true" ]] && echo "\033[106m" || echo "\033[96m"
            ;;
        br_white)
            [[ "${bg}" == "true" ]] && echo "\033[107m" || echo "\033[97m"
            ;;
        *)
            # Try hex color
            if [[ "${color}" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
                _hex_to_ansi "${color}" "${bg}"
            else
                echo ""
            fi
            ;;
    esac
}

# Apply text styles
_apply_text_style() {
    local text="$1"
    local styles="$2"
    
    if ! _supports_colors || [[ -z "${styles}" ]]; then
        echo "${text}"
        return
    fi
    
    local result="${text}"
    IFS=',' read -ra STYLE_ARRAY <<< "${styles}"
    
    for style in "${STYLE_ARRAY[@]}"; do
        style=$(echo "${style}" | xargs) # trim whitespace
        case "${style}" in
            bold)
                result="${_ANSI_BOLD}${result}${_ANSI_RESET}"
                ;;
            underline)
                result="${_ANSI_UNDERLINE}${result}${_ANSI_RESET}"
                ;;
            dim)
                result="${_ANSI_DIM}${result}${_ANSI_RESET}"
                ;;
            strikethrough)
                result="${_ANSI_STRIKETHROUGH}${result}${_ANSI_RESET}"
                ;;
            inverse)
                result="${_ANSI_INVERSE}${result}${_ANSI_RESET}"
                ;;
        esac
    done
    
    echo "${result}"
}

# Style formatting
_style_formatting() {
    local msg="$1"
    local text_color="$2"
    local back_color="$3"
    local text_style="$4"
    
    local result="${msg}"
    
    if ! _supports_colors; then
        echo "${result}"
        return
    fi
    
    # Apply background color
    if [[ -n "${back_color}" ]] && _check_color "${back_color}"; then
        local bg_code=$(_make_color_style "${back_color}" true)
        result="${bg_code}${result}${_ANSI_RESET}"
    fi
    
    # Apply text color
    if [[ -n "${text_color}" ]] && _check_color "${text_color}"; then
        local fg_code=$(_make_color_style "${text_color}" false)
        result="${fg_code}${result}${_ANSI_RESET}"
    fi
    
    # Apply text styles
    if [[ -n "${text_style}" ]]; then
        result=$(_apply_text_style "${result}" "${text_style}")
    fi
    
    echo "${result}"
}

# Get indent part
_get_indent_part() {
    local symbol="$1"
    local level="$2"
    
    if [[ "${symbol}" != "  " ]]; then
        local indent=""
        for ((i=0; i<level; i++)); do
            indent="${indent}${symbol}"
        done
        echo "${indent} "
    elif [[ "${level}" -gt 1 ]]; then
        local indent=""
        for ((i=1; i<level; i++)); do
            indent="${indent}  "
        done
        echo "${indent}"
    else
        echo ""
    fi
}

# Build message from arguments
_build_message() {
    local msg=""
    for arg in "$@"; do
        msg="${msg}${arg}"
    done
    echo "${msg}"
}

# Validate parameters
_validate_params() {
    local level="$1"
    local symbol="$2"
    local text_color="$3"
    local back_color="$4"
    local text_style="$5"
    
    # Validate level
    if ! [[ "${level}" =~ ^[0-9]+$ ]] || [[ "${level}" -lt 1 ]] || [[ "${level}" -gt 10 ]]; then
        echo "Error: level must be a positive integer between 1 and 10" >&2
        return 1
    fi
    
    # Validate symbol (should be non-empty string)
    if [[ -z "${symbol}" ]]; then
        echo "Error: symbol must be a non-empty string" >&2
        return 1
    fi
    
    # Validate text_color
    if [[ -n "${text_color}" ]] && ! _check_color "${text_color}"; then
        echo "Error: text_color must be a valid color name or hex code" >&2
        return 1
    fi
    
    # Validate back_color
    if [[ -n "${back_color}" ]] && ! _check_color "${back_color}"; then
        echo "Error: back_color must be a valid color name or hex code" >&2
        return 1
    fi
    
    # Check if text and background colors are the same
    if [[ -n "${text_color}" ]] && [[ -n "${back_color}" ]] && [[ "${text_color}" == "${back_color}" ]]; then
        echo "Error: text_color and back_color cannot be the same" >&2
        return 1
    fi
    
    # Validate text_style
    if [[ -n "${text_style}" ]]; then
        local valid_styles=("bold" "underline" "dim" "strikethrough" "inverse")
        IFS=',' read -ra STYLE_ARRAY <<< "${text_style}"
        for style in "${STYLE_ARRAY[@]}"; do
            style=$(echo "${style}" | xargs)
            local valid=false
            for valid_style in "${valid_styles[@]}"; do
                if [[ "${style}" == "${valid_style}" ]]; then
                    valid=true
                    break
                fi
            done
            if [[ "${valid}" == "false" ]]; then
                echo "Error: text_style must be one or more of: bold, underline, dim, strikethrough, inverse" >&2
                return 1
            fi
        done
    fi
    
    return 0
}

# Format line with style
_format_line_with_style() {
    local line="$1"
    local prefix="$2"
    local text_color="$3"
    local back_color="$4"
    local text_style="$5"
    local timestamp_style="$6"
    
    if [[ "${timestamp_style}" == "true" ]]; then
        local full_line="${prefix}${line}"
        _style_formatting "${full_line}" "${text_color}" "${back_color}" "${text_style}"
    else
        local styled_line=$(_style_formatting "${line}" "${text_color}" "${back_color}" "${text_style}")
        echo "${prefix}${styled_line}"
    fi
}

# Output CLI message based on type
_output_cli_message() {
    local message="$1"
    local message_type="$2"
    
    case "${message_type}" in
        info)
            if _supports_colors; then
                echo -e "\033[34mℹ\033[0m ${message}"
            else
                echo "[INFO] ${message}"
            fi
            ;;
        success)
            if _supports_colors; then
                echo -e "\033[32m✓\033[0m ${message}"
            else
                echo "[SUCCESS] ${message}"
            fi
            ;;
        warning)
            if _supports_colors; then
                echo -e "\033[33m!\033[0m ${message}"
            else
                echo "[WARNING] ${message}"
            fi
            ;;
        running)
            if _supports_colors; then
                echo -e "\033[36m◉\033[0m ${message}"
            else
                echo "[RUNNING] ${message}"
            fi
            ;;
        *)
            echo "${message}"
            ;;
    esac
}

# Output message
_output_message() {
    local msg="$1"
    local message_type="$2"
    local cli_model="$3"
    local text_color="$4"
    local back_color="$5"
    local text_style="$6"
    local timestamp="$7"
    local timestamp_format="$8"
    local level="$9"
    local symbol="${10}"
    local multiline_indent="${11}"
    local timestamp_style="${12}"
    
    # Check if message contains newlines
    if [[ "${cli_model}" == "true" ]] && [[ "${msg}" == *$'\n'* ]]; then
        local IFS=$'\n'
        local lines=($(echo -e "${msg}"))
        local first_line=true
        
        for line in "${lines[@]}"; do
            if [[ "${first_line}" == "true" ]] || [[ "${multiline_indent}" == "true" ]]; then
                local timestamp_part=""
                if [[ "${timestamp}" == "true" ]]; then
                    timestamp_part="[$(date +"${timestamp_format}")] "
                fi
                local indent_part=$(_get_indent_part "${symbol}" "${level}")
                local prefix="${timestamp_part}${indent_part}"
            else
                local indent_part=$(_get_indent_part "${symbol}" "${level}")
                local alignment_spaces=""
                if [[ "${timestamp}" == "true" ]]; then
                    # Calculate timestamp width
                    local sample_timestamp="[$(date +"${timestamp_format}")] "
                    alignment_spaces=$(printf "%${#sample_timestamp}s" "")
                fi
                local prefix="${alignment_spaces}${indent_part}"
            fi
            
            local formatted_line=$(_format_line_with_style \
                "${line}" \
                "${prefix}" \
                "${text_color}" \
                "${back_color}" \
                "${text_style}" \
                "${timestamp_style}")
            
            _output_cli_message "${formatted_line}" "${message_type}"
            first_line=false
        done
        return
    fi
    
    # Single line message
    local timestamp_part=""
    if [[ "${timestamp}" == "true" ]]; then
        timestamp_part="[$(date +"${timestamp_format}")] "
    fi
    local indent_part=$(_get_indent_part "${symbol}" "${level}")
    
    if [[ "${symbol}" != "  " ]]; then
        local symbol_repeat=""
        for ((i=0; i<level; i++)); do
            symbol_repeat="${symbol_repeat}${symbol}"
        done
        local final_msg="${timestamp_part}${symbol_repeat} ${msg}"
    else
        local final_msg="${timestamp_part}${indent_part}${msg}"
    fi
    
    if [[ "${cli_model}" == "true" ]]; then
        if [[ -n "${text_color}" ]] || [[ -n "${back_color}" ]] || [[ -n "${text_style}" ]]; then
            if [[ "${timestamp_style}" == "true" ]]; then
                final_msg=$(_style_formatting "${final_msg}" "${text_color}" "${back_color}" "${text_style}")
            else
                local styled_msg=$(_style_formatting "${msg}" "${text_color}" "${back_color}" "${text_style}")
                if [[ "${symbol}" != "  " ]]; then
                    local symbol_repeat=""
                    for ((i=0; i<level; i++)); do
                        symbol_repeat="${symbol_repeat}${symbol}"
                    done
                    final_msg="${timestamp_part}${symbol_repeat} ${styled_msg}"
                else
                    final_msg="${timestamp_part}${indent_part}${styled_msg}"
                fi
            fi
        fi
        _output_cli_message "${final_msg}" "${message_type}"
    else
        local formatted_msg="${msg}"
        if [[ -n "${text_color}" ]] || [[ -n "${back_color}" ]] || [[ -n "${text_style}" ]]; then
            formatted_msg=$(_style_formatting "${formatted_msg}" "${text_color}" "${back_color}" "${text_style}")
        fi
        
        local prefix=""
        case "${message_type}" in
            info)
                prefix=""
                ;;
            success)
                prefix="SUCCESS: "
                ;;
            warning)
                prefix="WARNING: "
                ;;
            running)
                prefix="RUNNING: "
                ;;
        esac
        echo "${prefix}${formatted_msg}"
    fi
}

# Main log_message function
log_message() {
    # Default values
    local verbose="${_LOG_MESSAGE_VERBOSE}"
    local message_type="info"
    local cli_model="${_LOG_MESSAGE_CLI_MODEL}"
    local level="${_LOG_MESSAGE_LEVEL}"
    local symbol="${_LOG_MESSAGE_SYMBOL}"
    local text_color=""
    local back_color=""
    local text_style=""
    local multiline_indent="false"
    local timestamp="${_LOG_MESSAGE_TIMESTAMP}"
    local timestamp_format="${_LOG_MESSAGE_TIMESTAMP_FORMAT}"
    local timestamp_style="${_LOG_MESSAGE_TIMESTAMP_STYLE}"
    
    # Parse arguments
    local message_parts=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --message-type|-t)
                message_type="$2"
                shift 2
                ;;
            --text-color|-c)
                text_color="$2"
                shift 2
                ;;
            --back-color|-b)
                back_color="$2"
                shift 2
                ;;
            --text-style|-s)
                text_style="$2"
                shift 2
                ;;
            --level|-l)
                level="$2"
                shift 2
                ;;
            --symbol|-y)
                symbol="$2"
                shift 2
                ;;
            --timestamp|-T)
                timestamp="true"
                shift
                ;;
            --no-timestamp)
                timestamp="false"
                shift
                ;;
            --timestamp-format)
                timestamp_format="$2"
                shift 2
                ;;
            --timestamp-style)
                timestamp_style="$2"
                shift 2
                ;;
            --multiline-indent)
                multiline_indent="true"
                shift
                ;;
            --verbose|-v)
                verbose="$2"
                shift 2
                ;;
            --cli-model)
                cli_model="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                return 1
                ;;
            *)
                message_parts+=("$1")
                shift
                ;;
        esac
    done
    
    # Validate message_type
    case "${message_type}" in
        info|success|warning|error|running)
            ;;
        *)
            echo "Error: message_type must be one of: info, success, warning, error, running" >&2
            return 1
            ;;
    esac
    
    # Get verbose
    if ! _get_verbose "${verbose}"; then
        return 0
    fi
    
    # Build message
    local msg=$(_build_message "${message_parts[@]}")
    
    # Handle error type
    if [[ "${message_type}" == "error" ]]; then
        _output_message \
            "${msg}" \
            "${message_type}" \
            "${cli_model}" \
            "${text_color}" \
            "${back_color}" \
            "${text_style}" \
            "${timestamp}" \
            "${timestamp_format}" \
            "${level}" \
            "${symbol}" \
            "${multiline_indent}" \
            "${timestamp_style}" >&2
        exit 1
    fi
    
    # Validate parameters
    if ! _validate_params "${level}" "${symbol}" "${text_color}" "${back_color}" "${text_style}"; then
        return 1
    fi
    
    # Output message
    _output_message \
        "${msg}" \
        "${message_type}" \
        "${cli_model}" \
        "${text_color}" \
        "${back_color}" \
        "${text_style}" \
        "${timestamp}" \
        "${timestamp_format}" \
        "${level}" \
        "${symbol}" \
        "${multiline_indent}" \
        "${timestamp_style}"
}

# If script is executed directly (not sourced), treat first argument as message
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_message "$@"
fi

