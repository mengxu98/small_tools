#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Web Link Extractor
Extract all links from a given web page and save to txt file
"""

import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import argparse
import logging
import sys
from typing import Set, List
import time
from datetime import datetime


class LinkExtractor:
    """Web link extractor class"""

    def __init__(self, log_level: str = "INFO"):
        """
        Initialize the link extractor

        Args:
            log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        """
        self.links = set()
        self.setup_logging(log_level)

        # Set request headers to simulate browser
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }

    def setup_logging(self, log_level: str):
        """Setup logging configuration"""
        logging.basicConfig(
            level=getattr(logging, log_level.upper()),
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[logging.StreamHandler(sys.stdout)],
        )
        self.logger = logging.getLogger(__name__)

    def extract_links(
        self,
        url: str,
        include_external: bool = True,
        filter_extensions: List[str] = None,
        filter_keywords: List[str] = None,
        recursive: bool = False,
        max_depth: int = 2,
        max_pages: int = 100,
    ) -> Set[str]:
        """
        Extract all links from the specified URL
        
        Args:
            url: Target webpage URL
            include_external: Whether to include external links
            filter_extensions: List of file extensions to filter out
            filter_keywords: List of keywords to filter out from URLs
            recursive: Whether to recursively crawl found links
            max_depth: Maximum depth for recursive crawling
            max_pages: Maximum number of pages to crawl
            
        Returns:
            Set containing all links
        """
        if recursive:
            return self._extract_links_recursive(
                url, include_external, filter_extensions, filter_keywords, max_depth, max_pages
            )
        else:
            links = self._extract_single_page(url, include_external, filter_extensions, filter_keywords)
            self.links = links
            self.logger.info(f"Extracted {len(links)} links")
            return links

    def _extract_single_page(
        self,
        url: str,
        include_external: bool = True,
        filter_extensions: List[str] = None,
        filter_keywords: List[str] = None,
    ) -> Set[str]:
        """Extract links from a single page"""
        try:
            self.logger.info(f"Visiting: {url}")

            # Send HTTP request
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            response.encoding = response.apparent_encoding

            # Parse HTML content
            soup = BeautifulSoup(response.text, "html.parser")

            # Get base URL for handling relative paths
            base_url = f"{urlparse(url).scheme}://{urlparse(url).netloc}"

            # Extract all href attributes from a tags
            links = set()
            for link in soup.find_all("a", href=True):
                href = link["href"].strip()

                # Skip empty links and special links
                if (
                    not href
                    or href.startswith("#")
                    or href.startswith("javascript:")
                    or href.startswith("mailto:")
                ):
                    continue

                # Convert to absolute URL
                absolute_url = urljoin(url, href)

                # Clean URL (remove fragment)
                parsed_url = urlparse(absolute_url)
                clean_url = (
                    f"{parsed_url.scheme}://{parsed_url.netloc}{parsed_url.path}"
                )
                if parsed_url.query:
                    clean_url += f"?{parsed_url.query}"

                # Check whether to include external links
                if not include_external:
                    if not clean_url.startswith(base_url):
                        continue

                # Filter specific file extensions
                if filter_extensions:
                    url_path = parsed_url.path.lower()
                    if any(url_path.endswith(ext.lower()) for ext in filter_extensions):
                        continue

                # Filter keywords (git, lab, html endings)
                default_keywords = ["git", "lab", "twitter", "me","com/"]
                if filter_keywords:
                    default_keywords.extend(filter_keywords)
                
                if any(keyword.lower() in clean_url.lower() for keyword in default_keywords):
                    continue
                
                # Filter html endings
                if clean_url.lower().endswith('.html'):
                    continue

                links.add(clean_url)

            return links

        except requests.RequestException as e:
            self.logger.error(f"Request error: {e}")
            return set()
        except Exception as e:
            self.logger.error(f"Error: {e}")
            return set()

    def _extract_links_recursive(
        self,
        start_url: str,
        include_external: bool = True,
        filter_extensions: List[str] = None,
        filter_keywords: List[str] = None,
        max_depth: int = 2,
        max_pages: int = 100,
    ) -> Set[str]:
        """Extract links recursively from multiple pages"""
        all_links = set()
        visited_urls = set()
        urls_to_visit = [(start_url, 0)]  # (url, depth)
        pages_crawled = 0

        while urls_to_visit and pages_crawled < max_pages:
            current_url, current_depth = urls_to_visit.pop(0)
            
            if current_url in visited_urls or current_depth >= max_depth:
                continue
            
            visited_urls.add(current_url)
            pages_crawled += 1
            
            self.logger.info(f"Crawling page {pages_crawled} (depth {current_depth}): {current_url}")
            
            # Extract links from current page
            page_links = self._extract_single_page(
                current_url, include_external, filter_extensions, filter_keywords
            )
            
            all_links.update(page_links)
            
            # Add new links for next level crawling (if not at max depth)
            if current_depth < max_depth - 1:
                for link in page_links:
                    if link not in visited_urls:
                        urls_to_visit.append((link, current_depth + 1))
            
            # Add small delay to be respectful
            time.sleep(0.5)

        self.links = all_links
        self.logger.info(f"Recursive crawling completed, visited {pages_crawled} pages, extracted {len(all_links)} links")
        
        return all_links

    def save_to_file(self, filename: str = None, sort_links: bool = True):
        """
        Save links to txt file

        Args:
            filename: Output filename
            sort_links: Whether to sort links
        """
        if not self.links:
            self.logger.warning("No links to save")
            return

        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"extracted_links_{timestamp}.txt"

        links_list = sorted(list(self.links)) if sort_links else list(self.links)

        try:
            with open(filename, "w", encoding="utf-8") as f:
                for link in links_list:
                    f.write(f"{link}\n")

            self.logger.info(f"Saved {len(links_list)} links to {filename}")

        except Exception as e:
            self.logger.error(f"Error saving file: {e}")

    def print_links(self, limit: int = None):
        """
        Print extracted links

        Args:
            limit: Limit the number of links to display
        """
        if not self.links:
            print("No links found")
            return

        print(f"\n=== Extracted links (total {len(self.links)}) ===")

        links_list = sorted(list(self.links))
        display_links = links_list[:limit] if limit else links_list

        for i, link in enumerate(display_links, 1):
            print(f"{i:3d}. {link}")

        if limit and len(links_list) > limit:
            print(f"... {len(links_list) - limit} more links")

    def get_statistics(self) -> dict:
        """
        Get link statistics

        Returns:
            Dictionary containing statistics
        """
        if not self.links:
            return {}

        stats = {
            "total_links": len(self.links),
            "domain_distribution": {},
            "protocol_distribution": {},
            "file_types": {},
        }

        for link in self.links:
            parsed = urlparse(link)

            # Domain distribution
            domain = parsed.netloc
            stats["domain_distribution"][domain] = (
                stats["domain_distribution"].get(domain, 0) + 1
            )

            # Protocol distribution
            protocol = parsed.scheme
            stats["protocol_distribution"][protocol] = (
                stats["protocol_distribution"].get(protocol, 0) + 1
            )

            # File type distribution
            path = parsed.path.lower()
            if "." in path:
                ext = path.split(".")[-1]
                if len(ext) <= 5:  # Assume file extensions don't exceed 5 characters
                    stats["file_types"][ext] = stats["file_types"].get(ext, 0) + 1

        return stats

    def print_statistics(self):
        """Print statistics information"""
        stats = self.get_statistics()

        if not stats:
            print("No statistics")
            return

        print(f"\n=== Link statistics ===")
        print(f"Total links: {stats['total_links']}")

        # Domain distribution
        print(f"\nDomain distribution:")
        for domain, count in sorted(
            stats["domain_distribution"].items(), key=lambda x: x[1], reverse=True
        )[:10]:
            percentage = (count / stats["total_links"]) * 100
            print(f"  {domain}: {count} ({percentage:.1f}%)")

        # Protocol distribution
        if stats["protocol_distribution"]:
            print(f"\nProtocol distribution:")
            for protocol, count in stats["protocol_distribution"].items():
                percentage = (count / stats["total_links"]) * 100
                print(f"  {protocol}: {count} ({percentage:.1f}%)")

        # File type distribution
        if stats["file_types"]:
            print(f"\nFile type distribution (top 10):")
            for file_type, count in sorted(
                stats["file_types"].items(), key=lambda x: x[1], reverse=True
            )[:10]:
                percentage = (count / stats["total_links"]) * 100
                print(f"  .{file_type}: {count} ({percentage:.1f}%)")


def main():
    """Main function to handle command line arguments"""
    parser = argparse.ArgumentParser(description="Extract all links from web pages")

    # Required arguments
    parser.add_argument("url", help="URL of the web page to extract links from")

    # Optional arguments
    parser.add_argument(
        "--output",
        "-o",
        help="Output filename (default: extracted_links_timestamp.txt)",
    )
    parser.add_argument(
        "--no-external", action="store_true", help="Exclude external links"
    )
    parser.add_argument(
        "--filter-ext", nargs="+", help="Filter file extensions (e.g. pdf jpg png)"
    )
    parser.add_argument(
        "--filter-keywords", nargs="+", help="Filter URLs containing keywords (default: git, lab, html endings are filtered)"
    )
    parser.add_argument(
        "--recursive", action="store_true", help="Recursively crawl found links"
    )
    parser.add_argument(
        "--max-depth", type=int, default=2, help="Maximum depth for recursive crawling (default: 2)"
    )
    parser.add_argument(
        "--max-pages", type=int, default=100, help="Maximum number of pages to crawl (default: 100)"
    )
    parser.add_argument(
        "--show-links", type=int, metavar="N", help="Show first N links"
    )
    parser.add_argument("--no-save", action="store_true", help="Don't save to file")
    parser.add_argument("--show-stats", action="store_true", help="Show statistics")
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Logging level",
    )

    args = parser.parse_args()

    # Create link extractor
    extractor = LinkExtractor(log_level=args.log_level)

    try:
        # Extract links
        links = extractor.extract_links(
            url=args.url,
            include_external=not args.no_external,
            filter_extensions=args.filter_ext,
            filter_keywords=args.filter_keywords,
            recursive=args.recursive,
            max_depth=args.max_depth,
            max_pages=args.max_pages,
        )

        if links:
            # Display links
            if args.show_links is not None:
                extractor.print_links(limit=args.show_links)

            # Show statistics
            if args.show_stats:
                extractor.print_statistics()

            # Save to file
            if not args.no_save:
                extractor.save_to_file(filename=args.output)

        else:
            print("No links found")

    except KeyboardInterrupt:
        print("\nOperation interrupted by user")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
