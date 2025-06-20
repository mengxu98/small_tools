#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PNAS Article Scraper (via PubMed API)
Retrieve articles from Huazhong Agricultural University published in PNAS,
including article titles and subject classifications
"""

import requests
import xml.etree.ElementTree as ET
import time
import csv
import json
from typing import List, Dict, Optional
import re


class PNASPubMedScraper:
    def __init__(self):
        self.base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
        self.esearch_url = f"{self.base_url}esearch.fcgi"
        self.efetch_url = f"{self.base_url}efetch.fcgi"
        self.esummary_url = f"{self.base_url}esummary.fcgi"
        self.articles = []

    def search_articles(
        self,
        affiliation: str = "Huazhong Agricultural University",
        journal: str = "Proc Natl Acad Sci U S A",
        max_results: int = 1000,
    ) -> List[str]:
        """
        Search for articles from specified institution published in PNAS using PubMed

        Args:
            affiliation: Institution name
            journal: Journal name
            max_results: Maximum number of results

        Returns:
            List of article IDs
        """
        print(f"Searching for articles from {affiliation} published in {journal}...")

        # Build search query
        # Search for articles published in PNAS with affiliation containing Huazhong Agricultural University
        search_term = f'("{journal}"[Journal]) AND ("{affiliation}"[Affiliation])'

        params = {
            "db": "pubmed",
            "term": search_term,
            "retmax": max_results,
            "retmode": "xml",
            "sort": "date",
        }

        try:
            print(f"Search query: {search_term}")
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

            print(f"Found {total_count} articles, retrieving details for the first {len(id_list)} articles")

            return id_list

        except requests.RequestException as e:
            print(f"Search request error: {e}")
            return []
        except ET.ParseError as e:
            print(f"XML parsing error: {e}")
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

        print(f"Retrieving detailed information for {len(pmid_list)} articles...")

        # PubMed API recommends retrieving at most 200 articles at once
        batch_size = 100
        all_articles = []

        for i in range(0, len(pmid_list), batch_size):
            batch_ids = pmid_list[i : i + batch_size]
            print(f"Processing batch {i // batch_size + 1}, containing {len(batch_ids)} articles")

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
            print(f"Error retrieving article details: {e}")
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
                # Remove HTML tags
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

            # Get journal information
            journal_elem = article_elem.find(".//Journal/Title")
            if journal_elem is not None:
                article_info["journal"] = journal_elem.text

            # Get publication date
            pub_date = article_elem.find(".//PubDate")
            if pub_date is not None:
                year = pub_date.find(".//Year")
                month = pub_date.find(".//Month")
                day = pub_date.find(".//Day")

                date_parts = []
                if year is not None:
                    date_parts.append(year.text)
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

            # Get keywords/MeSH terms (can be used as classification reference)
            mesh_terms = []
            for descriptor_elem in article_elem.findall(
                ".//MeshHeading/DescriptorName"
            ):
                if descriptor_elem.text:
                    mesh_terms.append(descriptor_elem.text)

            if mesh_terms:
                article_info["mesh_terms"] = "; ".join(mesh_terms[:5])  # Take only first 5
                # Try to infer general subject classification from MeSH terms
                article_info["category"] = self._infer_category_from_mesh(mesh_terms)

            # Get DOI
            elocation_elem = article_elem.find('.//ELocationID[@EIdType="doi"]')
            if elocation_elem is not None:
                article_info["doi"] = elocation_elem.text

            # Get author affiliations
            affiliations = []
            for affiliation_elem in article_elem.findall(
                ".//AffiliationInfo/Affiliation"
            ):
                if affiliation_elem.text:
                    affiliations.append(affiliation_elem.text)

            if affiliations:
                article_info["affiliations"] = "; ".join(
                    set(affiliations[:3])
                )  # Remove duplicates and take first 3

            return article_info

        except Exception as e:
            print(f"Error parsing article XML: {e}")
            return None

    def _infer_category_from_mesh(self, mesh_terms: List[str]) -> str:
        """Infer article category from MeSH terms"""
        # Define common subject classification keywords
        category_keywords = {
            "Cell Biology": [
                "Cell",
                "Cellular",
                "Protein",
                "Gene Expression",
                "Signal Transduction",
                "Cell Division",
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
            ],
            "Genetics": [
                "Gene",
                "Genetic",
                "DNA",
                "RNA",
                "Chromosome",
                "Mutation",
                "Genome",
            ],
            "Biochemistry": [
                "Enzyme",
                "Metabolism",
                "Biochemical",
                "Metabolic",
                "Biosynthesis",
            ],
            "Microbiology": [
                "Bacteria",
                "Virus",
                "Microorganism",
                "Pathogen",
                "Infection",
            ],
            "Neuroscience": ["Brain", "Neuron", "Neural", "Behavior", "Memory"],
            "Immunology": ["Immune", "Immunity", "Antibody", "T Cell", "B Cell"],
            "Environmental Science": [
                "Environment",
                "Climate",
                "Ecology",
                "Pollution",
                "Soil",
            ],
        }

        mesh_text = " ".join(mesh_terms).lower()

        for category, keywords in category_keywords.items():
            for keyword in keywords:
                if keyword.lower() in mesh_text:
                    return category

        return "Other"

    def save_to_csv(self, filename: str = "pnas_huazhong_articles_pubmed.csv"):
        """Save results to CSV file"""
        if not self.articles:
            print("No article data to save")
            return

        with open(filename, "w", newline="", encoding="utf-8") as csvfile:
            fieldnames = [
                "pmid",
                "title",
                "authors",
                "journal",
                "publication_date",
                "category",
                "mesh_terms",
                "abstract",
                "doi",
                "affiliations",
                "url",
            ]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for article in self.articles:
                writer.writerow(article)

        print(f"Saved {len(self.articles)} articles to {filename}")

    def save_to_json(self, filename: str = "pnas_huazhong_articles_pubmed.json"):
        """Save results to JSON file"""
        with open(filename, "w", encoding="utf-8") as jsonfile:
            json.dump(self.articles, jsonfile, ensure_ascii=False, indent=2)

        print(f"Saved {len(self.articles)} articles to {filename}")

    def save_statistics(self, filename: str = "pnas_huazhong_statistics.txt"):
        """Save statistical summary to text file"""
        if not self.articles:
            print("No article data to save statistics")
            return

        with open(filename, "w", encoding="utf-8") as txtfile:
            txtfile.write("=== PNAS Articles from Huazhong Agricultural University - Statistical Summary ===\n")
            txtfile.write("=" * 80 + "\n\n")
            
            txtfile.write(f"Total number of articles: {len(self.articles)}\n")
            txtfile.write(f"Data retrieved on: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            # Category statistics
            categories = {}
            for article in self.articles:
                category = article.get("category", "Uncategorized")
                categories[category] = categories.get(category, 0) + 1

            txtfile.write("Classification by Subject Area:\n")
            txtfile.write("-" * 40 + "\n")
            for category, count in sorted(
                categories.items(), key=lambda x: x[1], reverse=True
            ):
                percentage = (count / len(self.articles)) * 100
                txtfile.write(f"  {category}: {count} articles ({percentage:.1f}%)\n")

            # Year statistics
            years = {}
            for article in self.articles:
                pub_date = article.get("publication_date", "")
                year_match = re.search(r"\d{4}", pub_date)
                if year_match:
                    year = year_match.group()
                    years[year] = years.get(year, 0) + 1

            if years:
                txtfile.write(f"\nPublication Distribution by Year:\n")
                txtfile.write("-" * 40 + "\n")
                for year, count in sorted(years.items(), reverse=True):
                    txtfile.write(f"  {year}: {count} articles\n")

            # Recent articles
            txtfile.write(f"\nMost Recent 10 Articles:\n")
            txtfile.write("-" * 40 + "\n")
            for i, article in enumerate(self.articles[:10], 1):
                txtfile.write(f"{i:2d}. {article.get('title', 'No title')}\n")
                if article.get("category"):
                    txtfile.write(f"    Subject area: {article['category']}\n")
                if article.get("publication_date"):
                    txtfile.write(f"    Publication date: {article['publication_date']}\n")
                if article.get("url"):
                    txtfile.write(f"    URL: {article['url']}\n")
                txtfile.write("\n")

            # Most prolific years
            if years:
                txtfile.write("Most Productive Years:\n")
                txtfile.write("-" * 40 + "\n")
                top_years = sorted(years.items(), key=lambda x: x[1], reverse=True)[:5]
                for year, count in top_years:
                    txtfile.write(f"  {year}: {count} articles\n")

        print(f"Saved statistical summary to {filename}")

    def print_summary(self):
        """Print summary information"""
        if not self.articles:
            print("No articles found")
            return

        print(f"\n=== Summary of PNAS Articles from Huazhong Agricultural University ===")
        print(f"Total number of articles: {len(self.articles)}")

        # Category statistics
        categories = {}
        for article in self.articles:
            category = article.get("category", "Uncategorized")
            categories[category] = categories.get(category, 0) + 1

        print(f"\nClassification by inferred subject area:")
        for category, count in sorted(
            categories.items(), key=lambda x: x[1], reverse=True
        ):
            print(f"  {category}: {count} articles")

        # Year statistics
        years = {}
        for article in self.articles:
            pub_date = article.get("publication_date", "")
            year_match = re.search(r"\d{4}", pub_date)
            if year_match:
                year = year_match.group()
                years[year] = years.get(year, 0) + 1

        if years:
            print(f"\nPublication distribution by year:")
            for year, count in sorted(years.items(), reverse=True):
                print(f"  {year}: {count} articles")

        print(f"\nMost recent 10 articles:")
        for i, article in enumerate(self.articles[:10], 1):
            print(f"{i:2d}. {article.get('title', 'No title')}")
            if article.get("category"):
                print(f"    Inferred subject area: {article['category']}")
            if article.get("publication_date"):
                print(f"    Publication date: {article['publication_date']}")
            print()


def main():
    """Main function"""
    print("PNAS Article Scraper for Huazhong Agricultural University (via PubMed API)")
    print("=" * 80)

    scraper = PNASPubMedScraper()

    # Search for article IDs
    pmid_list = scraper.search_articles(
        "Huazhong Agricultural University", "Proc Natl Acad Sci U S A", max_results=500
    )

    if pmid_list:
        # Retrieve detailed article information
        articles = scraper.fetch_article_details(pmid_list)

        if articles:
            # Save results
            scraper.save_to_csv()
            scraper.save_to_json()
            scraper.save_statistics()

            # Print summary
            scraper.print_summary()
        else:
            print("Failed to retrieve detailed article information")
    else:
        print("No articles found")


if __name__ == "__main__":
    main()
