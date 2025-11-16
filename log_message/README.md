# log_message.sh

A shell script implementation of the R [log_message](https://mengxu98.github.io/thisutils/reference/log_message.html) function, providing formatted message printing with colors, styles, timestamps, and indentation for bash and zsh scripts.

## Features

- **Message Types**: info, success, warning, error, running
- **Color Support**: Named colors, bright colors, and hexadecimal color codes
- **Text Styles**: bold, underline, dim, strikethrough, inverse
- **Timestamps**: Configurable format with optional styling
- **Indentation**: Customizable levels and symbols
- **Multi-line Support**: Format each line independently
- **Verbose Control**: Local and global (via environment variable)

## Installation

### Quick Install

Run the installation script:

```bash
cd log_message
./install.sh
```

The installer will:
1. Detect your OS (macOS or Linux)
2. Ask for installation type (user-local or system-wide)
3. Install the script to the chosen location
4. Update your PATH automatically
5. Create a wrapper script for easy access

### Installation Types

#### User-local Installation (Recommended)
- Location: `~/.local/bin/log_message.sh`
- No sudo required
- User-specific installation
- PATH automatically updated in your shell config

#### System-wide Installation
- Location: `/usr/local/bin/log_message.sh`
- Requires sudo
- Available to all users
- `/usr/local/bin` is typically already in system PATH

### Manual Installation

If you prefer to install manually:

```bash
# Copy script to desired location
cp log_message.sh ~/.local/bin/log_message.sh
chmod +x ~/.local/bin/log_message.sh

# Add to PATH (if not already)
echo 'export PATH="${PATH}:~/.local/bin"' >> ~/.bashrc  # or ~/.zshrc
source ~/.bashrc  # or source ~/.zshrc
```

## Usage

### Basic Usage

Source the script in your shell script:

```bash
#!/bin/bash
source ~/.local/bin/log_message.sh

log_message "Hello, world!"
log_message "Processing..." --message-type success
log_message "Warning message" --message-type warning
log_message "Error occurred" --message-type error
```

### Message Types

```bash
log_message "Info message" --message-type info
log_message "Success message" --message-type success
log_message "Warning message" --message-type warning
log_message "Error message" --message-type error  # Exits with code 1
log_message "Running task" --message-type running
```

### Colors

#### Named Colors

```bash
# Basic colors
log_message "Red text" --text-color red
log_message "Green text" --text-color green
log_message "Blue text" --text-color blue

# Bright colors
log_message "Bright red" --text-color br_red
log_message "Bright green" --text-color br_green

# Background colors
log_message "Text with background" --back-color yellow
log_message "Colored text and background" --text-color white --back-color blue
```

#### Hexadecimal Colors

```bash
log_message "Custom color" --text-color "#FF5733"
log_message "Custom background" --back-color "#33FF57"
```

#### Supported Colors

**Basic Colors**: black, red, green, yellow, blue, magenta, cyan, white, grey, silver, none

**Bright Colors**: br_black, br_red, br_green, br_yellow, br_blue, br_magenta, br_cyan, br_white

### Text Styles

```bash
log_message "Bold text" --text-style bold
log_message "Underlined text" --text-style underline
log_message "Dim text" --text-style dim
log_message "Strikethrough" --text-style strikethrough
log_message "Inverse colors" --text-style inverse

# Multiple styles
log_message "Bold and underlined" --text-style "bold,underline"
```

### Indentation

```bash
# Level-based indentation
log_message "Level 1" --level 1
log_message "Level 2" --level 2
log_message "Level 3" --level 3

# Custom symbol
log_message "Custom indent" --symbol "->" --level 2
log_message "Hash indent" --symbol "#####" --level 1
```

### Timestamps

```bash
# Default timestamp
log_message "With timestamp"

# Disable timestamp
log_message "No timestamp" --no-timestamp

# Custom format
log_message "Custom format" --timestamp-format "%Y-%m-%d %H:%M:%S"

# Timestamp styling
log_message "Styled timestamp" --text-color red --timestamp-style true
log_message "Unstyled timestamp" --text-color blue --timestamp-style false
```

### Multi-line Messages

```bash
# Basic multi-line
log_message "Line 1\nLine 2\nLine 3"

# Multi-line with per-line formatting
log_message "Line 1\nLine 2\nLine 3" --multiline-indent --text-color blue
```

### Verbose Control

```bash
# Disable output
log_message "Hidden message" --verbose false

# Global verbose control via environment variable
export LOG_MESSAGE_VERBOSE=false
log_message "This won't be printed"
export LOG_MESSAGE_VERBOSE=true
log_message "This will be printed"
```

### Combined Examples

```bash
# Success message with custom color and style
log_message "Task completed!" \
    --message-type success \
    --text-color br_green \
    --text-style bold \
    --level 2

# Warning with background
log_message "Important warning" \
    --message-type warning \
    --text-color black \
    --back-color yellow \
    --text-style bold

# Custom formatted error
log_message "Critical error" \
    --message-type error \
    --text-color "#FF0000" \
    --text-style "bold,underline" \
    --level 1 \
    --symbol "!!!"
```

## Parameters Reference

| Parameter | Short | Description | Default |
|-----------|-------|-------------|---------|
| `--message-type` | `-t` | Message type: info, success, warning, error, running | info |
| `--text-color` | `-c` | Text color (name or hex code) | (none) |
| `--back-color` | `-b` | Background color (name or hex code) | (none) |
| `--text-style` | `-s` | Text style: bold, underline, dim, strikethrough, inverse | (none) |
| `--level` | `-l` | Indentation level (1-10) | 1 |
| `--symbol` | `-y` | Custom indentation symbol | "  " |
| `--timestamp` | `-T` | Enable timestamp | true |
| `--no-timestamp` | | Disable timestamp | |
| `--timestamp-format` | | Timestamp format string | "%Y-%m-%d %H:%M:%S" |
| `--timestamp-style` | | Apply styling to timestamp (true/false) | true |
| `--multiline-indent` | | Apply formatting to each line | false |
| `--verbose` | `-v` | Enable/disable output | true |
| `--cli-model` | | Use enhanced formatting | true |

## Environment Variables

- `LOG_MESSAGE_VERBOSE`: Global verbose control (true/false)
- `LOG_MESSAGE_CLI_MODEL`: Global CLI model setting (true/false)
- `LOG_MESSAGE_TIMESTAMP`: Global timestamp setting (true/false)
- `LOG_MESSAGE_TIMESTAMP_FORMAT`: Global timestamp format
- `LOG_MESSAGE_TIMESTAMP_STYLE`: Global timestamp style setting (true/false)
- `LOG_MESSAGE_LEVEL`: Global default level
- `LOG_MESSAGE_SYMBOL`: Global default symbol

## Examples

### Complete Example Script

```bash
#!/bin/bash
source ~/.local/bin/log_message.sh

log_message "Starting script..." --message-type info --text-color blue

log_message "Step 1: Initializing" --level 1
log_message "Step 2: Processing data" --level 1 --message-type running

log_message "Processing item 1" --level 2 --text-color cyan
log_message "Processing item 2" --level 2 --text-color cyan

log_message "All steps completed!" --message-type success --text-color br_green --text-style bold

log_message "Summary:\n- Item 1: OK\n- Item 2: OK" --multiline-indent --level 1
```

### Error Handling

```bash
#!/bin/bash
source ~/.local/bin/log_message.sh

if ! command -v some_command >/dev/null 2>&1; then
    log_message "some_command not found!" --message-type error
    # Script exits here with code 1
fi

# This won't be reached if error occurs
log_message "Continuing..."
```

### Colors Not Showing

If colors don't appear:
1. Check if your terminal supports colors: `echo $TERM`
2. Verify color support: `tput colors` (should show 8 or more)
3. Colors are automatically disabled in non-interactive terminals

### Script Not Found

If you get "command not found":
1. Check if script is in PATH: `which log_message.sh`
2. Verify installation location
3. Reload shell config: `source ~/.bashrc` or `source ~/.zshrc`

### Permission Denied

If you get permission errors:
1. Make script executable: `chmod +x log_message.sh`
2. Check directory permissions
3. For system-wide install, ensure sudo access

## Uninstallation

Use the provided uninstall script:

```bash
./uninstall.sh
```

Or manually remove:
```bash
rm ~/.local/bin/log_message.sh
rm ~/.local/bin/log_message
# Remove PATH entry from shell config if needed
```

## License

This script is provided as-is for use in your projects.

## Contributing

Feel free to submit issues or improvements!

