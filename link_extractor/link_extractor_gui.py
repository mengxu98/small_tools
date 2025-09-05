#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Link Extractor GUI Tool
A graphical interface for extracting links from web pages with customizable filtering options
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import threading
import queue
import sys
import os

# Try to import pyperclip for clipboard functionality
try:
    import pyperclip
    CLIPBOARD_AVAILABLE = True
except ImportError:
    CLIPBOARD_AVAILABLE = False

# Add the text_tools directory to the path to import LinkExtractor
sys.path.append(os.path.join(os.path.dirname(__file__), "link_extractor"))
from link_extractor import LinkExtractor


class LinkExtractorGUI:
    """GUI application for the Link Extractor tool"""

    def __init__(self, root):
        self.root = root
        self.root.title("🔗 Web Link Extractor Tool")
        self.root.geometry("1000x750")
        self.root.minsize(900, 650)
        
        # Set window icon (if available)
        try:
            self.root.iconbitmap("link_icon.ico")
        except tk.TclError:
            pass

        # Configure style
        self.setup_styles()

        # Initialize variables
        self.extractor = None
        self.extracted_links = set()
        self.is_extracting = False
        self.message_queue = queue.Queue()

        # Create GUI components
        self.create_widgets()

        # Start message queue processor
        self.process_queue()
        
    def clear_placeholder(self, event):
        """Clear placeholder text when entry gets focus"""
        if self.url_entry.get() == "https://example.com":
            self.url_entry.delete(0, tk.END)
            self.url_entry.config(foreground="black")
    
    def add_placeholder(self, event):
        """Add placeholder text when entry loses focus and is empty"""
        if not self.url_entry.get():
            self.url_entry.insert(0, "https://example.com")
            self.url_entry.config(foreground="gray")

    def setup_styles(self):
        """Setup modern styling for the GUI"""
        style = ttk.Style()
        style.theme_use("clam")

        # Configure custom styles
        style.configure("Title.TLabel", font=("Arial", 18, "bold"), foreground="#2c3e50")
        style.configure("Heading.TLabel", font=("Arial", 12, "bold"), foreground="#34495e")
        style.configure("Success.TLabel", foreground="#27ae60", font=("Arial", 10, "bold"))
        style.configure("Error.TLabel", foreground="#e74c3c", font=("Arial", 10, "bold"))
        style.configure("Info.TLabel", foreground="#3498db", font=("Arial", 10))
        
        # Button styles
        style.configure("Primary.TButton", font=("Arial", 10, "bold"))
        style.configure("Success.TButton", font=("Arial", 10, "bold"))
        style.configure("Danger.TButton", font=("Arial", 10, "bold"))
        
        # Frame styles
        style.configure("Card.TFrame", relief="solid", borderwidth=1)
        # Note: Card.TLabelFrame style may not be supported on all systems

    def create_widgets(self):
        """Create and layout all GUI widgets"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(7, weight=1)

        # Title
        title_label = ttk.Label(
            main_frame, text="🔗 Web Link Extractor Tool", style="Title.TLabel"
        )
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 25))
        
        # Subtitle
        subtitle_label = ttk.Label(
            main_frame, text="Extract and filter links from any webpage", 
            style="Info.TLabel"
        )
        subtitle_label.grid(row=1, column=0, columnspan=3, pady=(0, 20))

        # URL Input Section
        url_frame = ttk.LabelFrame(main_frame, text="🌐 Target Web URL", padding="15")
        url_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 15))
        url_frame.columnconfigure(1, weight=1)

        ttk.Label(url_frame, text="Web URL:", style="Heading.TLabel").grid(
            row=0, column=0, sticky=tk.W, padx=(0, 15)
        )
        self.url_var = tk.StringVar()
        self.url_entry = ttk.Entry(url_frame, textvariable=self.url_var, width=60, font=("Arial", 11))
        self.url_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 15))
        self.url_entry.bind("<Return>", lambda e: self.start_extraction())
        
        # Add placeholder text
        self.url_entry.insert(0, "https://example.com")
        self.url_entry.config(foreground="gray")
        self.url_entry.bind("<FocusIn>", self.clear_placeholder)
        self.url_entry.bind("<FocusOut>", self.add_placeholder)

        # Link Type Selection Section
        link_type_frame = ttk.LabelFrame(
            main_frame, text="⚙️ Link Type Selection", padding="15"
        )
        link_type_frame.grid(
            row=3, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 15)
        )

        # Link type checkboxes
        checkbox_frame = ttk.Frame(link_type_frame)
        checkbox_frame.grid(row=0, column=0, sticky=(tk.W, tk.E))

        # Basic options
        self.include_internal_var = tk.BooleanVar(value=True)
        self.include_external_var = tk.BooleanVar(value=True)
        self.recursive_var = tk.BooleanVar(value=False)

        ttk.Checkbutton(
            checkbox_frame,
            text="🔗 Include Internal Links",
            variable=self.include_internal_var,
        ).grid(row=0, column=0, sticky=tk.W, padx=(0, 25))
        ttk.Checkbutton(
            checkbox_frame,
            text="🌐 Include External Links",
            variable=self.include_external_var,
        ).grid(row=0, column=1, sticky=tk.W, padx=(0, 25))
        ttk.Checkbutton(
            checkbox_frame, text="🔄 Recursive Crawling", variable=self.recursive_var
        ).grid(row=0, column=2, sticky=tk.W)

        # File type filtering
        filter_frame = ttk.Frame(link_type_frame)
        filter_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(10, 0))

        ttk.Label(filter_frame, text="📁 Filter File Types:", style="Heading.TLabel").grid(
            row=0, column=0, sticky=tk.W, padx=(0, 10)
        )
        self.filter_extensions_var = tk.StringVar(value="pdf,jpg,png,gif,mp4,mp3")
        ttk.Entry(filter_frame, textvariable=self.filter_extensions_var, width=35, font=("Arial", 10)).grid(
            row=0, column=1, sticky=tk.W, padx=(0, 20)
        )

        ttk.Label(filter_frame, text="🔍 Filter Keywords:", style="Heading.TLabel").grid(
            row=0, column=2, sticky=tk.W, padx=(0, 10)
        )
        self.filter_keywords_var = tk.StringVar(value="github,gitlab,twitter")
        ttk.Entry(filter_frame, textvariable=self.filter_keywords_var, width=35, font=("Arial", 10)).grid(
            row=0, column=3, sticky=tk.W
        )

        # Advanced options
        advanced_frame = ttk.Frame(link_type_frame)
        advanced_frame.grid(row=2, column=0, sticky=(tk.W, tk.E), pady=(10, 0))

        ttk.Label(advanced_frame, text="📊 Maximum Depth:", style="Heading.TLabel").grid(
            row=0, column=0, sticky=tk.W, padx=(0, 8)
        )
        self.max_depth_var = tk.IntVar(value=2)
        ttk.Spinbox(
            advanced_frame, from_=1, to=5, textvariable=self.max_depth_var, width=8, font=("Arial", 10)
        ).grid(row=0, column=1, sticky=tk.W, padx=(0, 30))

        ttk.Label(advanced_frame, text="📄 Maximum Pages:", style="Heading.TLabel").grid(
            row=0, column=2, sticky=tk.W, padx=(0, 8)
        )
        self.max_pages_var = tk.IntVar(value=50)
        ttk.Spinbox(
            advanced_frame, from_=1, to=200, textvariable=self.max_pages_var, width=8, font=("Arial", 10)
        ).grid(row=0, column=3, sticky=tk.W)

        # Control Buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=4, column=0, columnspan=3, pady=(0, 15))

        self.extract_button = ttk.Button(
            button_frame, text="🚀 Start Extraction", command=self.start_extraction, style="Primary.TButton"
        )
        self.extract_button.grid(row=0, column=0, padx=(0, 15))

        self.stop_button = ttk.Button(
            button_frame, text="⏹️ Stop", command=self.stop_extraction, state="disabled", style="Danger.TButton"
        )
        self.stop_button.grid(row=0, column=1, padx=(0, 15))

        self.clear_button = ttk.Button(
            button_frame, text="🗑️ Clear Results", command=self.clear_results, style="Primary.TButton"
        )
        self.clear_button.grid(row=0, column=2, padx=(0, 15))

        self.export_button = ttk.Button(
            button_frame,
            text="💾 Export Results",
            command=self.export_results,
            state="disabled",
            style="Success.TButton"
        )
        self.export_button.grid(row=0, column=3, padx=(0, 15))

        self.copy_button = ttk.Button(
            button_frame,
            text="📋 Copy to Clipboard",
            command=self.copy_to_clipboard,
            state="disabled",
            style="Primary.TButton"
        )
        self.copy_button.grid(row=0, column=4, padx=(0, 15))

        # Progress Bar
        self.progress_var = tk.StringVar(value="Ready")
        self.progress_label = ttk.Label(main_frame, textvariable=self.progress_var, style="Info.TLabel")
        self.progress_label.grid(
            row=5, column=0, columnspan=3, sticky=tk.W, pady=(0, 8)
        )

        self.progress_bar = ttk.Progressbar(main_frame, mode="indeterminate", length=400)
        self.progress_bar.grid(
            row=6, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 15)
        )

        # Results Display
        results_frame = ttk.LabelFrame(
            main_frame, text="📋 Extraction Results", padding="10"
        )
        results_frame.grid(
            row=7, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 15)
        )
        results_frame.columnconfigure(0, weight=1)
        results_frame.rowconfigure(0, weight=1)

        # Results text area with scrollbar
        self.results_text = scrolledtext.ScrolledText(
            results_frame, height=18, width=90, wrap=tk.WORD, state="disabled",
            font=("Consolas", 10), bg="#f8f9fa", fg="#2c3e50"
        )
        self.results_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), padx=5, pady=5)

        # Status bar
        self.status_var = tk.StringVar(
            value="Ready - Please enter the web URL and select the link type"
        )
        status_bar = ttk.Label(
            main_frame, textvariable=self.status_var, relief=tk.SUNKEN, anchor=tk.W,
            font=("Arial", 9), background="#ecf0f1", foreground="#2c3e50"
        )
        status_bar.grid(
            row=8, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(15, 0)
        )

    def process_queue(self):
        """Process messages from the extraction thread"""
        try:
            while True:
                message = self.message_queue.get_nowait()
                if message["type"] == "progress":
                    self.progress_var.set(message["text"])
                elif message["type"] == "status":
                    self.status_var.set(message["text"])
                elif message["type"] == "result":
                    self.display_results(message["links"])
                elif message["type"] == "error":
                    messagebox.showerror("Error", message["text"])
                    self.stop_extraction()
                elif message["type"] == "complete":
                    self.extraction_complete()
        except queue.Empty:
            pass

        # Schedule next check
        self.root.after(100, self.process_queue)

    def start_extraction(self):
        """Start the link extraction process in a separate thread"""
        url = self.url_var.get().strip()
        if not url:
            messagebox.showwarning("Warning", "Please enter the web URL")
            return

        if not url.startswith(("http://", "https://")):
            url = "https://" + url
            self.url_var.set(url)

        # Update UI state
        self.is_extracting = True
        self.extract_button.config(state="disabled")
        self.stop_button.config(state="normal")
        self.export_button.config(state="disabled")
        self.copy_button.config(state="disabled")
        self.progress_bar.start()

        # Clear previous results
        self.results_text.config(state="normal")
        self.results_text.delete(1.0, tk.END)
        self.results_text.config(state="disabled")

        # Start extraction in separate thread
        thread = threading.Thread(target=self.extract_links_thread, args=(url,))
        thread.daemon = True
        thread.start()

    def extract_links_thread(self, url):
        """Extract links in a separate thread"""
        try:
            # Create extractor
            self.extractor = LinkExtractor(log_level="INFO")

            # Get filter options
            filter_extensions = []
            if self.filter_extensions_var.get().strip():
                filter_extensions = [
                    ext.strip() for ext in self.filter_extensions_var.get().split(",")
                ]

            filter_keywords = []
            if self.filter_keywords_var.get().strip():
                filter_keywords = [
                    kw.strip() for kw in self.filter_keywords_var.get().split(",")
                ]

            # Update progress
            self.message_queue.put(
                {"type": "progress", "text": "🌐 Connecting to the web..."}
            )
            self.message_queue.put(
                {"type": "status", "text": f"🔍 Extracting links from: {url}"}
            )

            # Extract links
            links = self.extractor.extract_links(
                url=url,
                include_external=self.include_external_var.get(),
                filter_extensions=filter_extensions if filter_extensions else None,
                filter_keywords=filter_keywords if filter_keywords else None,
                recursive=self.recursive_var.get(),
                max_depth=self.max_depth_var.get(),
                max_pages=self.max_pages_var.get(),
            )

            if not self.is_extracting:  # Check if stopped
                return

            self.extracted_links = links

            # Send results to main thread
            self.message_queue.put({"type": "result", "links": links})
            self.message_queue.put({"type": "complete"})

        except Exception as e:
            self.message_queue.put(
                {"type": "error", "text": f"Error during extraction: {str(e)}"}
            )

    def display_results(self, links):
        """Display extracted links in the results area"""
        self.results_text.config(state="normal")
        self.results_text.delete(1.0, tk.END)

        if not links:
            self.results_text.insert(tk.END, "❌ No links found\n")
        else:
            # Sort links for better display
            sorted_links = sorted(list(links))

            # Only display links, one per line
            for link in sorted_links:
                self.results_text.insert(tk.END, f"{link}\n")

        self.results_text.config(state="disabled")
        self.results_text.see(tk.END)

    def extraction_complete(self):
        """Handle extraction completion"""
        self.is_extracting = False
        self.extract_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.export_button.config(state="normal")
        self.copy_button.config(state="normal")
        self.progress_bar.stop()

        self.progress_var.set("✅ Extraction Complete")
        self.status_var.set(
            f"✅ Extraction Complete - Found {len(self.extracted_links)} links"
        )

    def stop_extraction(self):
        """Stop the extraction process"""
        self.is_extracting = False
        self.extract_button.config(state="normal")
        self.stop_button.config(state="disabled")
        self.progress_bar.stop()

        self.progress_var.set("⏹️ Stopped")
        self.status_var.set("⏹️ Extraction Stopped")

    def clear_results(self):
        """Clear the results display"""
        self.results_text.config(state="normal")
        self.results_text.delete(1.0, tk.END)
        self.results_text.config(state="disabled")

        self.extracted_links = set()
        self.export_button.config(state="disabled")
        self.copy_button.config(state="disabled")
        self.status_var.set("🗑️ Results Cleared")

    def export_results(self):
        """Export results to a file"""
        if not self.extracted_links:
            messagebox.showwarning("Warning", "No results to export")
            return

        # Ask user for file location
        filename = filedialog.asksaveasfilename(
            title="Save Links File",
            defaultextension=".txt",
            filetypes=[("Text File", "*.txt"), ("All Files", "*.*")],
        )

        if filename:
            try:
                with open(filename, "w", encoding="utf-8") as f:
                    # Only save links, one link per line
                    for link in sorted(self.extracted_links):
                        f.write(f"{link}\n")

                messagebox.showinfo("Success", f"Results saved to: {filename}")

            except Exception as e:
                messagebox.showerror("Error", f"Error saving file: {str(e)}")

    def copy_to_clipboard(self):
        """Copy extracted links to clipboard"""
        if not self.extracted_links:
            messagebox.showwarning("Warning", "No results to copy")
            return
            
        if not CLIPBOARD_AVAILABLE:
            messagebox.showerror("Error", "Clipboard functionality not available. Please install pyperclip:\npip install pyperclip")
            return
            
        try:
            # Prepare links for clipboard (one per line)
            links_text = "\n".join(sorted(self.extracted_links))
            pyperclip.copy(links_text)
            messagebox.showinfo("Success", f"Copied {len(self.extracted_links)} links to clipboard!")
            
        except Exception as e:
            messagebox.showerror("Error", f"Error copying to clipboard: {str(e)}")


def main():
    """Main function to run the GUI application"""
    root = tk.Tk()
    LinkExtractorGUI(root)

    # Center the window
    root.update_idletasks()
    x = (root.winfo_screenwidth() // 2) - (root.winfo_width() // 2)
    y = (root.winfo_screenheight() // 2) - (root.winfo_height() // 2)
    root.geometry(f"+{x}+{y}")

    # Start the GUI
    root.mainloop()


if __name__ == "__main__":
    main()
