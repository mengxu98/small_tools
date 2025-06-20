#!/bin/bash
# ASCII Art Generator Demo
# This script demonstrates various ASCII art generation techniques

# Navigate to the text_tools directory
cd "$(dirname "$0")/../../text_tools" || exit 1

echo "=== ASCII Art Generator Demo ==="
echo ""

# Make sure the script is executable
chmod +x ascii_generate.sh

echo "Demo 1: Basic ASCII art generation"
echo "Generating 'HELLO WORLD' with default Slant font..."
./ascii_generate.sh "HELLO WORLD"
echo ""

echo "Demo 2: Using different fonts"
echo "Generating 'BIG TEXT' with various fonts..."
echo ""

echo "--- Standard Font ---"
./ascii_generate.sh "STANDARD" Standard
echo ""

echo "--- Big Font ---"
./ascii_generate.sh "BIG" Big
echo ""

echo "--- Small Font ---"
./ascii_generate.sh "SMALL" Small
echo ""

echo "Demo 3: Project branding examples"
echo ""

echo "--- Project Logo ---"
./ascii_generate.sh "PROJECT" Banner
echo ""

echo "--- Version Info ---"
./ascii_generate.sh "v2.0" Digital
echo ""

echo "Demo 4: Creating output files"
echo "Generating ASCII art and saving to files..."
./ascii_generate.sh "LOGO" Slant -f logo_output.txt
./ascii_generate.sh "BANNER" Banner -f banner_output.txt

if [ -f "logo_output.txt" ]; then
    echo "✓ Logo saved to logo_output.txt"
fi

if [ -f "banner_output.txt" ]; then
    echo "✓ Banner saved to banner_output.txt"
fi

echo ""
echo "Demo 5: Multiple text processing"
echo "Creating a complete header set..."

texts=("PROJECT" "NAME" "2024")
for text in "${texts[@]}"; do
    echo "Processing: $text"
    ./ascii_generate.sh "$text" Slant
    echo "---"
done

echo ""
echo "ASCII Art Demo completed!"
echo "Try these commands yourself:"
echo "  ./ascii_generate.sh --help                    # Show help"
echo "  ./ascii_generate.sh --list-fonts              # List available fonts"
echo "  ./ascii_generate.sh 'Your Text' FontName      # Generate with specific font"
echo "  ./ascii_generate.sh 'Text' -f output.txt      # Save to file"

# Clean up demo files
rm -f logo_output.txt banner_output.txt 2>/dev/null
echo ""
echo "For more information, see the text_tools/README.md file." 