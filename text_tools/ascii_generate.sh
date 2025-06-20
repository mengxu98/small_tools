#!/bin/bash
# ASCII Art Generator
# Generates ASCII art from text using FIGlet with various font options
# 
# FIGlet homepage: http://www.figlet.org/
# Font source: https://github.com/xero/figlet-fonts/
#
# Usage examples:
#   ./ascii_generate.sh                           # Default "hello world" text
#   ./ascii_generate.sh "Your Text Here"         # Custom text
#   ./ascii_generate.sh "Text" Slant             # Custom text with specific font
#   ./ascii_generate.sh "Text" -f output.txt     # Save to file
#   ./ascii_generate.sh "Text" Banner -f logo.txt # Font and file output

# Default values
text="hello world"
font="Slant"
output_file=""
show_help=false

# Function to display help
show_usage() {
    echo "ASCII Art Generator - Create ASCII art from text using FIGlet"
    echo ""
    echo "Usage: $0 [TEXT] [FONT] [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  TEXT              Text to convert to ASCII art (default: 'hello world')"
    echo "  FONT              Font name to use (default: 'Slant')"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE   Save output to specified file"
    echo "  -h, --help        Show this help message"
    echo "  --list-fonts      List available fonts"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Generate default text"
    echo "  $0 'My Project'                       # Custom text"
    echo "  $0 'Title' Big                        # Custom text with Big font"
    echo "  $0 'Logo' Slant -f logo.txt          # Save to file"
    echo ""
    echo "Common fonts: Standard, Big, Small, Slant, Shadow, Block, Banner"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        show_usage
        ;;
    --list-fonts)
        echo "Available fonts:"
        figlet -f list 2>/dev/null || echo "FIGlet not installed or fonts not available"
        exit 0
        ;;
    -f | --file)
        output_file="$2"
        shift 2
        ;;
    *)
        if [[ -z "$text" || "$text" == "hello world" ]]; then
            text="$1"
        else
            font="$1"
        fi
        shift
        ;;
    esac
done

# Check if figlet is installed
FIGLET_CMD=$(which figlet)
if [ -z "$FIGLET_CMD" ]; then
    echo "Error: FIGlet is not installed. Please install it first."
    echo ""
    echo "Installation instructions:"
    echo "  macOS:           brew install figlet"
    echo "  Ubuntu/Debian:   sudo apt-get install figlet"
    echo "  CentOS/RHEL:     sudo yum install figlet"
    echo "  Arch Linux:      sudo pacman -S figlet"
    echo ""
    exit 1
fi

# Check if the font is available
font_path=""
if [ -f "${font}.flf" ]; then
    # Font file in current directory
    font_path="./${font}.flf"
    echo "Using local font file: ${font}.flf"
elif [ -f "text_tools/${font}.flf" ]; then
    # Font file in text_tools directory
    font_path="text_tools/${font}.flf"
    echo "Using font file: text_tools/${font}.flf"
else
    # Try system font or built-in font
    echo "Attempting to use system font: $font"
fi

# Generate ASCII art using figlet
if [ -n "$font_path" ]; then
    # Use specific font file
    if ascii_art=$("$FIGLET_CMD" -f "$font_path" "$text" 2>/dev/null); then
        echo "ASCII art generated successfully with $font font."
    else
        echo "Warning: Failed to use $font font, falling back to default."
        ascii_art=$("$FIGLET_CMD" "$text")
    fi
else
    # Try system font or use default
    if ascii_art=$("$FIGLET_CMD" -f "$font" "$text" 2>/dev/null); then
        echo "ASCII art generated successfully with $font font."
    else
        echo "Warning: Font '$font' not found, using default font."
        ascii_art=$("$FIGLET_CMD" "$text")
    fi
fi

# Display the ASCII art
echo ""
echo "Generated ASCII Art:"
echo "=================================================="
echo "$ascii_art"
echo "=================================================="
echo ""

# Save to file if specified
if [ -n "$output_file" ]; then
    # Add .txt extension if not present
    if [[ ! "$output_file" =~ \.(txt|md|rst)$ ]]; then
        output_file="${output_file}.txt"
    fi
    
    # Create output directory if it doesn't exist
    output_dir=$(dirname "$output_file")
    if [ "$output_dir" != "." ] && [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
        echo "Created directory: $output_dir"
    fi
    
    # Save the ASCII art
    echo "$ascii_art" > "$output_file"
    echo "✓ ASCII art saved to: $output_file"
    echo "  File size: $(wc -c < "$output_file") bytes"
    echo "  Lines: $(echo "$ascii_art" | wc -l)"
fi

echo "ASCII art generation completed successfully!"
echo "Text: '$text'"
echo "Font: $font"
if [ -n "$output_file" ]; then
    echo "Output: $output_file"
fi
