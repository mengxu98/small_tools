#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Academic Article Scraper (via PubMed API)
A flexible tool to retrieve academic articles from PubMed with various search parameters
Supports multiple journals, institutions, authors, and date ranges
"""

import requests
import xml.etree.ElementTree as ET
import time
import csv
import json
import argparse
import logging
from typing import List, Dict, Optional, Union
import re
from datetime import datetime, timedelta
import os
import sys


class AcademicArticleScraper:
    """
    A comprehensive academic article scraper using PubMed API
    """

    def __init__(self, log_level: str = "INFO"):
        """
        Initialize the scraper

        Args:
            log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        """
        self.base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
        self.esearch_url = f"{self.base_url}esearch.fcgi"
        self.efetch_url = f"{self.base_url}efetch.fcgi"
        self.esummary_url = f"{self.base_url}esummary.fcgi"
        self.articles = []

        # Setup logging
        self.setup_logging(log_level)

        # Common journal mappings
        self.journal_mappings = {
            "pnas": "Proc Natl Acad Sci U S A",
            "nature": "Nature",
            "science": "Science",
            "cell": "Cell",
            "nejm": "N Engl J Med",
            "lancet": "Lancet",
            "jama": "JAMA",
            "plos_one": "PLoS One",
            "nature_methods": "Nat Methods",
            "nature_biotechnology": "Nat Biotechnol",
            "nature_genetics": "Nat Genet",
            "nature_medicine": "Nat Med",
            "cell_metabolism": "Cell Metab",
            "molecular_cell": "Mol Cell",
            "developmental_cell": "Dev Cell",
            "current_biology": "Curr Biol",
            "trends_biochem_sci": "Trends Biochem Sci",
            "annual_review_biochem": "Annu Rev Biochem",
            "jbc": "J Biol Chem",
            "embo_j": "EMBO J",
            "nucleic_acids_res": "Nucleic Acids Res",
            "plant_cell": "Plant Cell",
            "plant_physiol": "Plant Physiol",
            "plant_journal": "Plant J",
        }

    def setup_logging(self, log_level: str):
        """Setup logging configuration"""
        logging.basicConfig(
            level=getattr(logging, log_level.upper()),
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[
                logging.StreamHandler(sys.stdout),
                logging.FileHandler("academic_scraper.log"),
            ],
        )
        self.logger = logging.getLogger(__name__)

    def search_articles(
        self,
        affiliations: Union[str, List[str]] = None,
        journals: Union[str, List[str]] = None,
        authors: Union[str, List[str]] = None,
        keywords: Union[str, List[str]] = None,
        date_from: str = None,
        date_to: str = None,
        max_results: int = 1000,
        sort_by: str = "date",
    ) -> List[str]:
        """
        Search for articles with flexible parameters

        Args:
            affiliations: Institution name(s) to search for
            journals: Journal name(s) to search in
            authors: Author name(s) to search for
            keywords: Keywords to search for
            date_from: Start date (YYYY/MM/DD format)
            date_to: End date (YYYY/MM/DD format)
            max_results: Maximum number of results
            sort_by: Sort order (date, relevance, author, journal)

        Returns:
            List of article IDs
        """
        search_terms = []

        # Build search query components
        if affiliations:
            if isinstance(affiliations, str):
                affiliations = [affiliations]
            affiliation_terms = [f'"{aff}"[Affiliation]' for aff in affiliations]
            search_terms.append(f"({' OR '.join(affiliation_terms)})")

        if journals:
            if isinstance(journals, str):
                journals = [journals]
            # Map journal shortcuts to full names
            expanded_journals = []
            for journal in journals:
                if journal.lower() in self.journal_mappings:
                    expanded_journals.append(self.journal_mappings[journal.lower()])
                else:
                    expanded_journals.append(journal)
            journal_terms = [f'"{journal}"[Journal]' for journal in expanded_journals]
            search_terms.append(f"({' OR '.join(journal_terms)})")

        if authors:
            if isinstance(authors, str):
                authors = [authors]
            author_terms = [f'"{author}"[Author]' for author in authors]
            search_terms.append(f"({' OR '.join(author_terms)})")

        if keywords:
            if isinstance(keywords, str):
                keywords = [keywords]
            keyword_terms = [f'"{keyword}"[All Fields]' for keyword in keywords]
            search_terms.append(f"({' OR '.join(keyword_terms)})")

        # Date range
        if date_from or date_to:
            if not date_from:
                date_from = "1900/01/01"
            if not date_to:
                date_to = datetime.now().strftime("%Y/%m/%d")
            search_terms.append(
                f'("{date_from}"[Date - Publication] : "{date_to}"[Date - Publication])'
            )

        if not search_terms:
            raise ValueError("At least one search parameter must be provided")

        # Combine all search terms
        search_query = " AND ".join(search_terms)

        self.logger.info(f"Search query: {search_query}")

        params = {
            "db": "pubmed",
            "term": search_query,
            "retmax": max_results,
            "retmode": "xml",
            "sort": sort_by,
        }

        try:
            response = requests.get(self.esearch_url, params=params)
            response.raise_for_status()

            # Parse XML response
            root = ET.fromstring(response.content)

            # Get article ID list
            id_list = []
            for id_elem in root.findall(".//Id"):
                id_list.append(id_elem.text)

            count = root.find(".//Count")
            total_count = int(count.text) if count is not None else 0

            self.logger.info(
                f"Found {total_count} articles, retrieving details for the first {len(id_list)} articles"
            )

            return id_list

        except requests.RequestException as e:
            self.logger.error(f"Search request error: {e}")
            return []
        except ET.ParseError as e:
            self.logger.error(f"XML parsing error: {e}")
            return []

    def fetch_article_details(self, pmid_list: List[str]) -> List[Dict]:
        """
        Retrieve detailed information for articles

        Args:
            pmid_list: List of PubMed IDs

        Returns:
            List of detailed article information
        """
        if not pmid_list:
            return []

        self.logger.info(
            f"Retrieving detailed information for {len(pmid_list)} articles..."
        )

        # PubMed API recommends retrieving at most 200 articles at once
        batch_size = 100
        all_articles = []

        for i in range(0, len(pmid_list), batch_size):
            batch_ids = pmid_list[i : i + batch_size]
            self.logger.info(
                f"Processing batch {i // batch_size + 1}, containing {len(batch_ids)} articles"
            )

            # Get abstract information
            batch_articles = self._fetch_batch_abstracts(batch_ids)
            all_articles.extend(batch_articles)

            # Add delay to comply with NCBI usage restrictions
            time.sleep(1)

        self.articles = all_articles
        return all_articles

    def _fetch_batch_abstracts(self, pmid_list: List[str]) -> List[Dict]:
        """Retrieve abstract information for a batch of articles"""
        params = {
            "db": "pubmed",
            "id": ",".join(pmid_list),
            "retmode": "xml",
            "rettype": "abstract",
        }

        try:
            response = requests.get(self.efetch_url, params=params)
            response.raise_for_status()

            # Parse XML
            root = ET.fromstring(response.content)

            articles = []
            for article_elem in root.findall(".//PubmedArticle"):
                article_info = self._parse_article_xml(article_elem)
                if article_info:
                    articles.append(article_info)

            return articles

        except Exception as e:
            self.logger.error(f"Error retrieving article details: {e}")
            return []

    def _parse_article_xml(self, article_elem) -> Optional[Dict]:
        """Parse XML information for a single article"""
        try:
            article_info = {}

            # Get PMID
            pmid_elem = article_elem.find(".//PMID")
            if pmid_elem is not None:
                article_info["pmid"] = pmid_elem.text
                article_info["url"] = (
                    f"https://pubmed.ncbi.nlm.nih.gov/{pmid_elem.text}/"
                )

            # Get title
            title_elem = article_elem.find(".//ArticleTitle")
            if title_elem is not None:
                title = ET.tostring(title_elem, encoding="unicode", method="text")
                article_info["title"] = title.strip()

            # Get authors
            authors = []
            for author_elem in article_elem.findall(".//Author"):
                lastname = author_elem.find(".//LastName")
                forename = author_elem.find(".//ForeName")
                if lastname is not None:
                    name = lastname.text
                    if forename is not None:
                        name = f"{forename.text} {name}"
                    authors.append(name)

            if authors:
                article_info["authors"] = "; ".join(authors)
                article_info["first_author"] = authors[0] if authors else ""
                article_info["last_author"] = authors[-1] if authors else ""
                article_info["author_count"] = len(authors)

            # Get journal information
            journal_elem = article_elem.find(".//Journal/Title")
            if journal_elem is not None:
                article_info["journal"] = journal_elem.text

            # Get journal abbreviation
            journal_abbr_elem = article_elem.find(".//Journal/ISOAbbreviation")
            if journal_abbr_elem is not None:
                article_info["journal_abbr"] = journal_abbr_elem.text

            # Get volume and issue
            volume_elem = article_elem.find(".//Volume")
            if volume_elem is not None:
                article_info["volume"] = volume_elem.text

            issue_elem = article_elem.find(".//Issue")
            if issue_elem is not None:
                article_info["issue"] = issue_elem.text

            # Get pages
            pages_elem = article_elem.find(".//Pagination/MedlinePgn")
            if pages_elem is not None:
                article_info["pages"] = pages_elem.text

            # Get publication date
            pub_date = article_elem.find(".//PubDate")
            if pub_date is not None:
                year = pub_date.find(".//Year")
                month = pub_date.find(".//Month")
                day = pub_date.find(".//Day")

                date_parts = []
                if year is not None:
                    date_parts.append(year.text)
                    article_info["year"] = int(year.text)
                if month is not None:
                    date_parts.append(month.text)
                if day is not None:
                    date_parts.append(day.text)

                if date_parts:
                    article_info["publication_date"] = " ".join(date_parts)

            # Get abstract
            abstract_elem = article_elem.find(".//AbstractText")
            if abstract_elem is not None:
                abstract = ET.tostring(abstract_elem, encoding="unicode", method="text")
                article_info["abstract"] = abstract.strip()
                article_info["abstract_length"] = len(abstract.strip())

            # Get keywords/MeSH terms
            mesh_terms = []
            for descriptor_elem in article_elem.findall(
                ".//MeshHeading/DescriptorName"
            ):
                if descriptor_elem.text:
                    mesh_terms.append(descriptor_elem.text)

            if mesh_terms:
                article_info["mesh_terms"] = "; ".join(mesh_terms[:10])  # Take first 10
                article_info["category"] = self._infer_category_from_mesh(mesh_terms)

            # Get DOI
            elocation_elem = article_elem.find('.//ELocationID[@EIdType="doi"]')
            if elocation_elem is not None:
                article_info["doi"] = elocation_elem.text

            # Get PMC ID
            pmc_elem = article_elem.find('.//ELocationID[@EIdType="pmc"]')
            if pmc_elem is not None:
                article_info["pmc"] = pmc_elem.text

            # Get author affiliations
            affiliations = []
            for affiliation_elem in article_elem.findall(
                ".//AffiliationInfo/Affiliation"
            ):
                if affiliation_elem.text:
                    affiliations.append(affiliation_elem.text)

            if affiliations:
                article_info["affiliations"] = "; ".join(set(affiliations[:5]))
                article_info["affiliation_count"] = len(set(affiliations))

            # Get publication type
            pub_types = []
            for pub_type_elem in article_elem.findall(".//PublicationType"):
                if pub_type_elem.text:
                    pub_types.append(pub_type_elem.text)

            if pub_types:
                article_info["publication_types"] = "; ".join(pub_types)

            return article_info

        except Exception as e:
            self.logger.error(f"Error parsing article XML: {e}")
            return None

    def _infer_category_from_mesh(self, mesh_terms: List[str]) -> str:
        """Infer article category from MeSH terms"""
        category_keywords = {
            "Cell Biology": [
                "Cell",
                "Cellular",
                "Protein",
                "Gene Expression",
                "Signal Transduction",
                "Cell Division",
                "Cell Cycle",
                "Apoptosis",
                "Mitochondria",
                "Cytoplasm",
            ],
            "Plant Biology": [
                "Plant",
                "Plants",
                "Arabidopsis",
                "Rice",
                "Crop",
                "Agriculture",
                "Photosynthesis",
                "Plant Development",
                "Chloroplast",
                "Stomata",
            ],
            "Genetics": [
                "Gene",
                "Genetic",
                "DNA",
                "RNA",
                "Chromosome",
                "Mutation",
                "Genome",
                "Genotype",
                "Phenotype",
                "Allele",
                "Heredity",
            ],
            "Biochemistry": [
                "Enzyme",
                "Metabolism",
                "Biochemical",
                "Metabolic",
                "Biosynthesis",
                "Catalysis",
                "Substrate",
                "Kinetics",
                "Pathway",
            ],
            "Microbiology": [
                "Bacteria",
                "Virus",
                "Microorganism",
                "Pathogen",
                "Infection",
                "Antibiotic",
                "Microbe",
                "Bacterial",
                "Viral",
            ],
            "Neuroscience": [
                "Brain",
                "Neuron",
                "Neural",
                "Behavior",
                "Memory",
                "Synaptic",
                "Cognitive",
                "Nervous System",
                "Neurotransmitter",
            ],
            "Immunology": [
                "Immune",
                "Immunity",
                "Antibody",
                "T Cell",
                "B Cell",
                "Vaccine",
                "Inflammatory",
                "Cytokine",
                "Immunotherapy",
            ],
            "Environmental Science": [
                "Environment",
                "Climate",
                "Ecology",
                "Pollution",
                "Soil",
                "Ecosystem",
                "Conservation",
                "Biodiversity",
            ],
            "Medicine": [
                "Patient",
                "Treatment",
                "Therapy",
                "Disease",
                "Clinical",
                "Diagnosis",
                "Drug",
                "Pharmaceutical",
                "Medical",
            ],
            "Cancer Research": [
                "Cancer",
                "Tumor",
                "Oncology",
                "Carcinoma",
                "Metastasis",
                "Chemotherapy",
                "Radiation",
                "Neoplasm",
            ],
        }

        mesh_text = " ".join(mesh_terms).lower()

        # Score each category
        category_scores = {}
        for category, keywords in category_keywords.items():
            score = 0
            for keyword in keywords:
                if keyword.lower() in mesh_text:
                    score += 1
            if score > 0:
                category_scores[category] = score

        if category_scores:
            # Return the category with the highest score
            return max(category_scores, key=category_scores.get)

        return "Other"

    def save_to_csv(self, filename: str = None):
        """Save results to CSV file"""
        if not self.articles:
            self.logger.warning("No article data to save")
            return

        if filename is None:
            filename = f"articles_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"

        fieldnames = [
            "pmid",
            "title",
            "first_author",
            "last_author",
            "author_count",
            "authors",
            "journal",
            "journal_abbr",
            "volume",
            "issue",
            "pages",
            "year",
            "publication_date",
            "category",
            "mesh_terms",
            "abstract",
            "abstract_length",
            "doi",
            "pmc",
            "affiliations",
            "affiliation_count",
            "publication_types",
            "url",
        ]

        with open(filename, "w", newline="", encoding="utf-8") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for article in self.articles:
                writer.writerow(article)

        self.logger.info(f"Saved {len(self.articles)} articles to {filename}")

    def save_to_json(self, filename: str = None):
        """Save results to JSON file"""
        if filename is None:
            filename = f"articles_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        with open(filename, "w", encoding="utf-8") as jsonfile:
            json.dump(self.articles, jsonfile, ensure_ascii=False, indent=2)

        self.logger.info(f"Saved {len(self.articles)} articles to {filename}")

    def save_statistics(self, filename: str = None):
        """Save statistical summary to text file"""
        if not self.articles:
            self.logger.warning("No article data to save statistics")
            return

        if filename is None:
            filename = f"statistics_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"

        with open(filename, "w", encoding="utf-8") as txtfile:
            txtfile.write("=== Academic Articles - Statistical Summary ===\n")
            txtfile.write("=" * 60 + "\n\n")

            txtfile.write(f"Total number of articles: {len(self.articles)}\n")
            txtfile.write(
                f"Data retrieved on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
            )

            # Journal distribution
            journals = {}
            for article in self.articles:
                journal = article.get("journal", "Unknown")
                journals[journal] = journals.get(journal, 0) + 1

            txtfile.write("Distribution by Journal:\n")
            txtfile.write("-" * 40 + "\n")
            for journal, count in sorted(
                journals.items(), key=lambda x: x[1], reverse=True
            )[:10]:
                percentage = (count / len(self.articles)) * 100
                txtfile.write(f"  {journal}: {count} articles ({percentage:.1f}%)\n")

            # Category statistics
            categories = {}
            for article in self.articles:
                category = article.get("category", "Uncategorized")
                categories[category] = categories.get(category, 0) + 1

            txtfile.write(f"\nClassification by Subject Area:\n")
            txtfile.write("-" * 40 + "\n")
            for category, count in sorted(
                categories.items(), key=lambda x: x[1], reverse=True
            ):
                percentage = (count / len(self.articles)) * 100
                txtfile.write(f"  {category}: {count} articles ({percentage:.1f}%)\n")

            # Year statistics
            years = {}
            for article in self.articles:
                year = article.get("year", 0)
                if year:
                    years[year] = years.get(year, 0) + 1

            if years:
                txtfile.write(f"\nPublication Distribution by Year:\n")
                txtfile.write("-" * 40 + "\n")
                for year, count in sorted(years.items(), reverse=True)[:10]:
                    txtfile.write(f"  {year}: {count} articles\n")

            # Author statistics
            author_counts = [
                article.get("author_count", 0)
                for article in self.articles
                if article.get("author_count")
            ]
            if author_counts:
                avg_authors = sum(author_counts) / len(author_counts)
                txtfile.write(f"\nAuthor Statistics:\n")
                txtfile.write("-" * 40 + "\n")
                txtfile.write(f"  Average number of authors: {avg_authors:.1f}\n")
                txtfile.write(f"  Maximum authors: {max(author_counts)}\n")
                txtfile.write(f"  Minimum authors: {min(author_counts)}\n")

            # Recent articles
            txtfile.write(f"\nMost Recent 10 Articles:\n")
            txtfile.write("-" * 40 + "\n")
            recent_articles = sorted(
                self.articles, key=lambda x: x.get("year", 0), reverse=True
            )[:10]
            for i, article in enumerate(recent_articles, 1):
                txtfile.write(f"{i:2d}. {article.get('title', 'No title')}\n")
                txtfile.write(f"    Journal: {article.get('journal', 'Unknown')}\n")
                txtfile.write(f"    Year: {article.get('year', 'Unknown')}\n")
                txtfile.write(f"    Authors: {article.get('author_count', 0)}\n")
                if article.get("url"):
                    txtfile.write(f"    URL: {article['url']}\n")
                txtfile.write("\n")

        self.logger.info(f"Saved statistical summary to {filename}")

    def print_summary(self):
        """Print summary information"""
        if not self.articles:
            print("No articles found")
            return

        print(f"\n=== Academic Articles Summary ===")
        print(f"Total number of articles: {len(self.articles)}")

        # Journal distribution
        journals = {}
        for article in self.articles:
            journal = article.get("journal", "Unknown")
            journals[journal] = journals.get(journal, 0) + 1

        print(f"\nTop 5 Journals:")
        for journal, count in sorted(
            journals.items(), key=lambda x: x[1], reverse=True
        )[:5]:
            print(f"  {journal}: {count} articles")

        # Category statistics
        categories = {}
        for article in self.articles:
            category = article.get("category", "Uncategorized")
            categories[category] = categories.get(category, 0) + 1

        print(f"\nClassification by subject area:")
        for category, count in sorted(
            categories.items(), key=lambda x: x[1], reverse=True
        ):
            print(f"  {category}: {count} articles")

        # Year statistics
        years = {}
        for article in self.articles:
            year = article.get("year", 0)
            if year:
                years[year] = years.get(year, 0) + 1

        if years:
            print(f"\nMost productive years:")
            for year, count in sorted(years.items(), key=lambda x: x[1], reverse=True)[
                :5
            ]:
                print(f"  {year}: {count} articles")


def main():
    """Main function with command line interface"""
    parser = argparse.ArgumentParser(
        description="Academic Article Scraper via PubMed API"
    )

    # Search parameters
    parser.add_argument(
        "--affiliations", "-a", nargs="+", help="Institution names to search for"
    )
    parser.add_argument(
        "--journals",
        "-j",
        nargs="+",
        help="Journal names to search in (use shortcuts like 'pnas', 'nature', 'science')",
    )
    parser.add_argument(
        "--authors", "-au", nargs="+", help="Author names to search for"
    )
    parser.add_argument("--keywords", "-k", nargs="+", help="Keywords to search for")
    parser.add_argument("--date-from", help="Start date (YYYY/MM/DD format)")
    parser.add_argument("--date-to", help="End date (YYYY/MM/DD format)")
    parser.add_argument(
        "--max-results",
        "-m",
        type=int,
        default=500,
        help="Maximum number of results (default: 500)",
    )
    parser.add_argument(
        "--sort-by",
        choices=["date", "relevance", "author", "journal"],
        default="date",
        help="Sort order",
    )

    # Output options
    parser.add_argument(
        "--output-prefix", "-o", default="articles", help="Output filename prefix"
    )
    parser.add_argument("--no-csv", action="store_true", help="Don't save CSV file")
    parser.add_argument("--no-json", action="store_true", help="Don't save JSON file")
    parser.add_argument(
        "--no-stats", action="store_true", help="Don't save statistics file"
    )

    # Other options
    parser.add_argument(
        "--log-level",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        default="INFO",
        help="Logging level",
    )
    parser.add_argument(
        "--list-journals", action="store_true", help="List available journal shortcuts"
    )

    args = parser.parse_args()

    scraper = AcademicArticleScraper(log_level=args.log_level)

    # List available journals
    if args.list_journals:
        print("Available journal shortcuts:")
        for shortcut, full_name in sorted(scraper.journal_mappings.items()):
            print(f"  {shortcut:<20} -> {full_name}")
        return

    # Check if at least one search parameter is provided
    if not any([args.affiliations, args.journals, args.authors, args.keywords]):
        print("Error: At least one search parameter must be provided")
        print("Use --help for more information")
        return

    try:
        # Search for articles
        pmid_list = scraper.search_articles(
            affiliations=args.affiliations,
            journals=args.journals,
            authors=args.authors,
            keywords=args.keywords,
            date_from=args.date_from,
            date_to=args.date_to,
            max_results=args.max_results,
            sort_by=args.sort_by,
        )

        if pmid_list:
            # Retrieve detailed article information
            articles = scraper.fetch_article_details(pmid_list)

            if articles:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

                # Save results
                if not args.no_csv:
                    scraper.save_to_csv(f"{args.output_prefix}_{timestamp}.csv")
                if not args.no_json:
                    scraper.save_to_json(f"{args.output_prefix}_{timestamp}.json")
                if not args.no_stats:
                    scraper.save_statistics(
                        f"{args.output_prefix}_stats_{timestamp}.txt"
                    )

                # Print summary
                scraper.print_summary()
            else:
                print("Failed to retrieve detailed article information")
        else:
            print("No articles found with the specified criteria")

    except Exception as e:
        print(f"Error: {e}")
        scraper.logger.error(f"Application error: {e}")


if __name__ == "__main__":
    main()
