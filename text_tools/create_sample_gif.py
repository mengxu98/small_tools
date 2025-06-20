#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GIF Creation Demo Script
This script demonstrates how to use the GIF generator with sample images
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import subprocess

def create_sample_images():
    """Create sample images for GIF demonstration"""
    sample_dir = Path("sample_images")
    sample_dir.mkdir(exist_ok=True)
    
    # Create a series of simple colored rectangles
    colors = [
        (255, 100, 100),  # Red
        (100, 255, 100),  # Green
        (100, 100, 255),  # Blue
        (255, 255, 100),  # Yellow
        (255, 100, 255),  # Magenta
        (100, 255, 255),  # Cyan
    ]
    
    size = (400, 300)
    
    for i, color in enumerate(colors):
        # Create image
        img = Image.new('RGB', size, color)
        draw = ImageDraw.Draw(img)
        
        # Add frame number
        try:
            # Try to use a default font
            font = ImageFont.load_default()
        except:
            font = None
        
        text = f"Frame {i+1}"
        if font:
            # Get text size and center it
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            x = (size[0] - text_width) // 2
            y = (size[1] - text_height) // 2
            draw.text((x, y), text, fill=(255, 255, 255), font=font)
        else:
            # Fallback without font
            draw.text((size[0]//2 - 30, size[1]//2), text, fill=(255, 255, 255))
        
        # Add border
        draw.rectangle([0, 0, size[0]-1, size[1]-1], outline=(0, 0, 0), width=3)
        
        # Save image
        img.save(sample_dir / f"frame_{i+1:02d}.png")
    
    print(f"Created {len(colors)} sample images in {sample_dir}")
    return sample_dir

def run_gif_examples(sample_dir):
    """Run various GIF creation examples"""
    
    # Get the path to the gif_generator script
    script_path = Path(__file__).parent.parent.parent / "media_tools" / "gif_generator.py"
    
    if not script_path.exists():
        print(f"Error: GIF generator script not found at {script_path}")
        return
    
    print("\n=== GIF Creation Examples ===")
    
    # Example 1: Basic GIF creation
    print("\nExample 1: Basic GIF from image directory")
    cmd = [
        "python3", str(script_path),
        "--input_dir", str(sample_dir),
        "--output", "demo_basic.gif",
        "--duration", "500"
    ]
    print(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Basic GIF created successfully")
        else:
            print(f"Error: {result.stderr}")
    except Exception as e:
        print(f"Error running command: {e}")
    
    # Example 2: Fast animation
    print("\nExample 2: Fast animation GIF")
    cmd = [
        "python3", str(script_path),
        "--input_dir", str(sample_dir),
        "--output", "demo_fast.gif",
        "--duration", "100",
        "--optimize"
    ]
    print(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Fast animation GIF created successfully")
        else:
            print(f"Error: {result.stderr}")
    except Exception as e:
        print(f"Error running command: {e}")
    
    # Example 3: Resized GIF
    print("\nExample 3: Resized and optimized GIF")
    cmd = [
        "python3", str(script_path),
        "--input_dir", str(sample_dir),
        "--output", "demo_small.gif",
        "--duration", "300",
        "--resize", "200x150",
        "--optimize"
    ]
    print(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Resized GIF created successfully")
        else:
            print(f"Error: {result.stderr}")
    except Exception as e:
        print(f"Error running command: {e}")
    
    # Example 4: Limited loop GIF
    print("\nExample 4: GIF with limited loops")
    cmd = [
        "python3", str(script_path),
        "--input_dir", str(sample_dir),
        "--output", "demo_loop3.gif",
        "--duration", "800",
        "--loop", "3"
    ]
    print(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Limited loop GIF created successfully")
        else:
            print(f"Error: {result.stderr}")
    except Exception as e:
        print(f"Error running command: {e}")

def list_created_gifs():
    """List all created GIF files"""
    print("\n=== Created GIF Files ===")
    gif_files = list(Path(".").glob("demo_*.gif"))
    
    if gif_files:
        for gif_file in sorted(gif_files):
            size = gif_file.stat().st_size
            size_kb = size / 1024
            print(f"  {gif_file.name}: {size_kb:.1f} KB ({size:,} bytes)")
    else:
        print("  No GIF files created")

def main():
    """Main demo function"""
    print("GIF Generator Demo Script")
    print("=" * 50)
    
    # Create sample images
    sample_dir = create_sample_images()
    
    # Run GIF creation examples
    run_gif_examples(sample_dir)
    
    # List created files
    list_created_gifs()
    
    print("\n=== Demo Complete ===")
    print("Files created:")
    print("  - sample_images/: Directory with sample PNG files")
    print("  - demo_*.gif: Various GIF examples")
    print("")
    print("You can view the GIF files with any image viewer or web browser.")
    print("To clean up demo files, run:")
    print("  rm -rf sample_images/ demo_*.gif")
    print("")
    print("For more options, see media_tools/README.md")

if __name__ == "__main__":
    main() 