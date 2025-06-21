#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Link extractor usage examples
"""

from link_extractor import LinkExtractor


def example_usage():
    """Demonstrate how to use the link extractor"""

    # Create link extractor instance
    extractor = LinkExtractor()

    # Example website URL
    test_url = "https://www.example.com"

    print("=== Link Extractor Usage Examples ===\n")

    # 1. Basic usage: extract all links
    print("1. Extract all links:")
    links = extractor.extract_links(test_url)
    extractor.print_links(limit=10)  # Show only first 10

    # 2. Extract internal links only
    print("\n2. Extract internal links only:")
    internal_links = extractor.extract_links(test_url, include_external=False)

    # 3. Filter specific file types and keywords
    print("\n3. Filter PDF, image files and git/lab sites:")
    filtered_links = extractor.extract_links(
        test_url, 
        filter_extensions=["pdf", "jpg", "png", "gif"],
        filter_keywords=["github", "gitlab"]
    )

    # 4. Recursive crawling (limited example)
    print("\n4. Recursive crawling (max 2 pages, depth 2):")
    recursive_links = extractor.extract_links(
        test_url,
        recursive=True,
        max_depth=2,
        max_pages=2
    )
    
    # 5. Show statistics
    print("\n5. Statistics:")
    extractor.print_statistics()

    # 6. Save to file
    print("\n6. Save to file:")
    extractor.save_to_file("example_links.txt")


if __name__ == "__main__":
    example_usage()
