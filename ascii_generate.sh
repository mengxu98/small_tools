#!/bin/bash
# This script generates an ASCII art logo using figlet
# figlet is from: http://www.figlet.org/
# It converts the figlet output to a format that can be used in R
# It uses the figlet font "Slant", from source: https://github.com/xero/figlet-fonts/blob/master/Slant.flf

# example1: bash figlet.sh
# example2: bash figlet.sh "hello world"
# example3: bash figlet.sh "hello world" -f output.txt

# Parse command line arguments
text="hello world"
output_file=""

while [[ $# -gt 0 ]]; do
    case $1 in
    -f | --file)
        output_file="$2"
        shift 2
        ;;
    *)
        text="$1"
        shift
        ;;
    esac
done

# Find figlet command
FIGLET_CMD=$(which figlet)
if [ -z "$FIGLET_CMD" ]; then
    echo "Error: figlet is not installed. Please install it first."
    echo "On macOS: brew install figlet"
    echo "On Ubuntu/Debian: sudo apt-get install figlet"
    echo "On CentOS/RHEL: sudo yum install figlet"
    exit 1
fi

# Check if Slant font exists in current directory
slant_font="Slant.flf"
if [ ! -f "$slant_font" ]; then
    echo "Slant font not found in current directory."
    echo "Attempting to download..."

    # Download font from GitHub
    if curl -s -o "$slant_font" "https://raw.githubusercontent.com/xero/figlet-fonts/master/Slant.flf"; then
        echo "Font downloaded successfully."
        font_installed=true
    else
        echo "Failed to download Slant font. Using default font."
        font_installed=false
    fi
else
    font_installed=true
fi

# Generate ASCII art using figlet
if [ "$font_installed" = true ]; then
    ascii_art=$("$FIGLET_CMD" -f ./Slant "$text" | sed 's/\\/./g')
else
    ascii_art=$("$FIGLET_CMD" "$text" | sed 's/\\/./g')
fi

# Print the ASCII art to the console
echo "ASCII art generated:"
echo "--------------------------------------------------"
echo "$ascii_art"
echo "--------------------------------------------------"

# Save to file if specified
if [ -n "$output_file" ]; then
    # Ensure the file has .txt extension
    if [[ ! "$output_file" =~ \.txt$ ]]; then
        output_file="${output_file}.txt"
    fi
    echo "$ascii_art" >"$output_file"
    echo "ASCII art saved to: $output_file"
fi

# Clean up downloaded font if it was downloaded
if [ "$font_installed" = true ] && [ -f "$slant_font" ]; then
    rm "$slant_font"
    echo "Temporary font file cleaned up."
fi
