#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Link Extractor GUI Launcher
Simple launcher script for the Link Extractor GUI tool
"""

import sys
import os

# Add current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    from link_extractor_gui import main

    if __name__ == "__main__":
        print("Start Link Extractor GUI tool...")
        main()

except ImportError as e:
    print(f"Import error: {e}")
    print("Please ensure the required dependencies are installed:")
    print("pip install requests beautifulsoup4")
    sys.exit(1)
except Exception as e:
    print(f"Start failed: {e}")
    sys.exit(1)
