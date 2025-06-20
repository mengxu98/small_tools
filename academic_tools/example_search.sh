#!/bin/bash
# Academic Article Search Examples
# This script demonstrates various usage patterns for the academic article scraper

# Navigate to the academic_tools directory
cd "$(dirname "$0")/../../academic_tools" || exit 1

echo "=== Academic Article Scraper Examples ==="
echo ""

# Example 1: Basic institutional search
echo "Example 1: Search for Harvard University articles in Nature and Science"
echo "Command: python3 academic_article_scraper.py --affiliations 'Harvard University' --journals nature science --max-results 50"
echo ""

# Example 2: Keyword-based search
echo "Example 2: Search for CRISPR research in top journals"
echo "Command: python3 academic_article_scraper.py --keywords 'CRISPR' 'gene editing' --journals nature science cell --max-results 100"
echo ""

# Example 3: Date range search
echo "Example 3: Search for recent AI research (2023-2024)"
echo "Command: python3 academic_article_scraper.py --keywords 'artificial intelligence' 'machine learning' --journals nature science --date-from '2023/01/01' --date-to '2024/12/31' --max-results 200"
echo ""

# Example 4: Multi-institution collaboration
echo "Example 4: Search for collaborations between MIT and Stanford"
echo "Command: python3 academic_article_scraper.py --affiliations 'MIT' 'Stanford University' --journals pnas nature --max-results 75"
echo ""

# Example 5: Author-specific search
echo "Example 5: Search for specific author's work"
echo "Command: python3 academic_article_scraper.py --authors 'Smith J' --journals nature science --max-results 50"
echo ""

echo "To run any of these examples, copy the command and execute it from the academic_tools directory."
echo "You can also modify the parameters to suit your specific research needs."
echo ""
echo "For more detailed information, see the academic_tools/README.md file." 