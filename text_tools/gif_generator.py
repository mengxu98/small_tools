#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GIF Generator - Create Animated GIFs from Image Sequences

This script creates animated GIFs from image sequences with customizable settings.
Supports various image formats and provides options for optimization and quality control.

Features:
- Multiple input formats: JPEG, PNG, BMP, TIFF, GIF, WEBP
- Customizable frame duration and loop count
- Image resizing and quality optimization
- Batch processing from directories
- Command-line interface with comprehensive options

Usage Examples:
    # Create GIF from image directory
    python3 gif_generator.py --input_dir images/ --output animation.gif
    
    # Create GIF from specific images
    python3 gif_generator.py --input_images img1.jpg img2.jpg img3.jpg --output sequence.gif
    
    # Create optimized GIF with custom settings
    python3 gif_generator.py --input_dir frames/ --output optimized.gif --duration 200 --optimize
"""

import argparse
import os
import sys
from pathlib import Path
from PIL import Image
import glob
from typing import List, Optional, Tuple


class GIFGenerator:
    """Class to handle GIF generation from image sequences"""
    
    SUPPORTED_FORMATS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tif', '.gif', '.webp'}
    
    def __init__(self):
        self.images = []
        self.output_path = "output.gif"
        self.duration = 500  # milliseconds
        self.loop = 0  # 0 = infinite loop
        self.optimize = False
        self.quality = 85
        self.resize = None
        
    def load_images_from_directory(self, directory: str) -> List[str]:
        """Load all supported image files from directory"""
        image_files = []
        directory = Path(directory)
        
        if not directory.exists():
            print(f"Error: Directory '{directory}' does not exist.")
            return []
            
        print(f"Scanning directory: {directory}")
        
        for ext in self.SUPPORTED_FORMATS:
            pattern = str(directory / f"*{ext}")
            files = glob.glob(pattern, recursive=False)
            image_files.extend(files)
            
            # Also check uppercase extensions
            pattern = str(directory / f"*{ext.upper()}")
            files = glob.glob(pattern, recursive=False)
            image_files.extend(files)
        
        # Sort files naturally (handles numeric sequences)
        image_files.sort()
        
        print(f"Found {len(image_files)} image files")
        return image_files
    
    def load_images_from_list(self, image_paths: List[str]) -> List[str]:
        """Load images from provided list of paths"""
        valid_images = []
        
        for path in image_paths:
            if Path(path).exists():
                ext = Path(path).suffix.lower()
                if ext in self.SUPPORTED_FORMATS:
                    valid_images.append(path)
                else:
                    print(f"Warning: Unsupported format '{ext}' for file '{path}'")
            else:
                print(f"Warning: File '{path}' does not exist")
        
        print(f"Loaded {len(valid_images)} valid image files")
        return valid_images
    
    def process_image(self, image_path: str) -> Optional[Image.Image]:
        """Process individual image with resizing and optimization"""
        try:
            img = Image.open(image_path)
            
            # Convert to RGB if necessary (handles RGBA, P mode, etc.)
            if img.mode not in ('RGB', 'L'):
                if img.mode == 'RGBA':
                    # Handle transparency by creating white background
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    background.paste(img, mask=img.split()[-1])  # Use alpha channel as mask
                    img = background
                else:
                    img = img.convert('RGB')
            
            # Resize if specified
            if self.resize:
                img = img.resize(self.resize, Image.Resampling.LANCZOS)
                
            return img
            
        except Exception as e:
            print(f"Error processing image '{image_path}': {e}")
            return None
    
    def create_gif(self, image_paths: List[str]) -> bool:
        """Create GIF from list of image paths"""
        if not image_paths:
            print("Error: No image paths provided")
            return False
            
        print(f"Processing {len(image_paths)} images...")
        
        # Process all images
        processed_images = []
        for i, image_path in enumerate(image_paths):
            print(f"Processing image {i+1}/{len(image_paths)}: {Path(image_path).name}")
            img = self.process_image(image_path)
            if img:
                processed_images.append(img)
        
        if not processed_images:
            print("Error: No valid images could be processed")
            return False
        
        print(f"Successfully processed {len(processed_images)} images")
        
        # Create output directory if it doesn't exist
        output_dir = Path(self.output_path).parent
        if output_dir != Path('.'):
            output_dir.mkdir(parents=True, exist_ok=True)
        
        # Save as GIF
        try:
            print(f"Creating GIF: {self.output_path}")
            print(f"Settings: duration={self.duration}ms, loop={self.loop}, optimize={self.optimize}")
            
            processed_images[0].save(
                self.output_path,
                save_all=True,
                append_images=processed_images[1:],
                duration=self.duration,
                loop=self.loop,
                optimize=self.optimize
            )
            
            # Get file size for reporting
            file_size = os.path.getsize(self.output_path)
            file_size_mb = file_size / (1024 * 1024)
            
            print(f"✓ GIF created successfully!")
            print(f"  Output: {self.output_path}")
            print(f"  Frames: {len(processed_images)}")
            print(f"  File size: {file_size_mb:.2f} MB ({file_size:,} bytes)")
            print(f"  Dimensions: {processed_images[0].size}")
            
            return True
            
        except Exception as e:
            print(f"Error creating GIF: {e}")
            return False


def parse_resize_argument(resize_str: str) -> Optional[Tuple[int, int]]:
    """Parse resize argument in format 'WIDTHxHEIGHT'"""
    if not resize_str:
        return None
        
    try:
        if 'x' in resize_str.lower():
            width, height = resize_str.lower().split('x')
            return (int(width), int(height))
        else:
            # Single number - make it square
            size = int(resize_str)
            return (size, size)
    except ValueError:
        print(f"Error: Invalid resize format '{resize_str}'. Use format like '800x600' or '800'")
        return None


def main():
    """Main function with command line interface"""
    parser = argparse.ArgumentParser(
        description="Create animated GIFs from image sequences",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --input_dir screenshots/ --output demo.gif
  %(prog)s --input_images img1.jpg img2.jpg img3.jpg --output sequence.gif
  %(prog)s --input_dir frames/ --output optimized.gif --duration 200 --optimize --resize 800x600
  %(prog)s --input_dir photos/ --output slideshow.gif --duration 1000 --loop 3
        """
    )
    
    # Input options (mutually exclusive)
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument(
        '--input_dir', '-d',
        help='Directory containing image files'
    )
    input_group.add_argument(
        '--input_images', '-i',
        nargs='+',
        help='List of image file paths'
    )
    
    # Output options
    parser.add_argument(
        '--output', '-o',
        default='output.gif',
        help='Output GIF filename (default: output.gif)'
    )
    
    # Animation options
    parser.add_argument(
        '--duration',
        type=int,
        default=500,
        help='Frame duration in milliseconds (default: 500)'
    )
    parser.add_argument(
        '--loop',
        type=int,
        default=0,
        help='Number of loops (0 = infinite, default: 0)'
    )
    
    # Quality options
    parser.add_argument(
        '--optimize',
        action='store_true',
        help='Enable GIF optimization (reduces file size)'
    )
    parser.add_argument(
        '--quality',
        type=int,
        default=85,
        choices=range(1, 96),
        metavar='1-95',
        help='JPEG quality for optimization (1-95, default: 85)'
    )
    parser.add_argument(
        '--resize',
        help='Resize images to specified dimensions (e.g., 800x600 or 800)'
    )
    
    # Parse arguments
    args = parser.parse_args()
    
    # Validate arguments
    if args.duration < 1:
        print("Error: Duration must be at least 1 millisecond")
        sys.exit(1)
    
    if args.loop < 0:
        print("Error: Loop count cannot be negative")
        sys.exit(1)
        
    # Parse resize argument
    resize_dims = parse_resize_argument(args.resize) if args.resize else None
    
    # Create GIF generator
    generator = GIFGenerator()
    generator.output_path = args.output
    generator.duration = args.duration
    generator.loop = args.loop
    generator.optimize = args.optimize
    generator.quality = args.quality
    generator.resize = resize_dims
    
    # Load images
    if args.input_dir:
        image_paths = generator.load_images_from_directory(args.input_dir)
    else:
        image_paths = generator.load_images_from_list(args.input_images)
    
    if not image_paths:
        print("Error: No valid images found")
        sys.exit(1)
    
    # Create GIF
    success = generator.create_gif(image_paths)
    
    if success:
        print("\n🎉 GIF generation completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ GIF generation failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
