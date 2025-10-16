#!/bin/bash

# Function to display messages based on selected language
print_message() {
    local lang="$1"
    shift
    if [[ "$lang" == "cn" ]]; then
        echo "$1"
    else
        echo "$2"
    fi
}

# Function to install wget if it's not installed
install_wget() {
    if command_exists apt; then
        sudo apt-get update && sudo apt-get install -y wget
    elif command_exists yum; then
        sudo yum install -y wget
    elif command_exists brew; then
        brew install wget
    elif command_exists choco; then
        choco install wget
    else
        print_message "$language" "无法确定包管理器，无法自动安装 wget。/ Unable to determine the package manager, unable to install wget automatically." "Unable to determine the package manager, unable to install wget automatically."
        exit 1
    fi
}

# Function to check if a command is available
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to show help
show_help() {
    print_message "$language" "用法: $(basename "$0") [-S|--silent] GEO_ID_1 GEO_ID_2 ..." "Usage: $(basename "$0") [-S|--silent] GEO_ID_1 GEO_ID_2 ..."
    print_message "$language" "-S, --silent 静默模式" "-S, --silent Silent mode"
    print_message "$language" "例如: $(basename "$0") GEO168408 GEO270119" "Example: $(basename "$0") GEO168408 GEO270119"
}

# Check if wget is installed
if ! command_exists wget; then
    print_message "$language" "错误：未安装 wget。是否要安装？ (y/n) / Error: wget is not installed. Do you want to install it? (y/n)" "Error: wget is not installed. Do you want to install it? (y/n)"
    read -p "请输入你的选择: " choice
    if [[ "$choice" == "y" ]]; then
        install_wget
    else
        print_message "$language" "安装已取消，脚本将退出。 / Installation canceled, the script will exit." "Installation canceled, the script will exit."
        exit 1
    fi
fi

# Default values
silent=false
language="en"  # Default language set to English

# Prompt to choose language
echo "$(print_message "$language" "请选择语言 / Please choose a language:")"
echo "1) 中文 (Chinese)"
echo "2) English"

# Read language choice
read -p "$(print_message "$language" '输入选项 (please enter your choice): ' 'Enter your choice: ')" lang_choice

# Set language based on choice
if [[ "$lang_choice" == "1" ]]; then
    language="cn"
else
    language="en"
fi

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -S | --silent)
        silent=true
        shift
        ;;
    -h | --help)
        show_help
        exit 0
        ;;
    *)
        # Handle multiple GEO_IDs
        geo_ids+=("$1")
        shift
        ;;
    esac
done

# Check if at least one GEO_ID is provided
if [ ${#geo_ids[@]} -eq 0 ]; then
    print_message "$language" "错误：请提供至少一个 GSE 编号 / Error: Please provide at least one GSE number." "Error: Please provide at least one GSE number."
    show_help
    exit 1
fi

# Function to download data for a given GEO_ID
download_geo_data() {
    local geo_id="$1"
    # local url="ftp://ftp.ncbi.nlm.nih.gov/geo/series/${geo_id:0:-3}nnn/${geo_id}/"
    local url="ftp://ftp.ncbi.nlm.nih.gov/geo/series/${geo_id:0:6}nnn/${geo_id}/"

    # Create new directory and check if it already exists
    if [ -d "$geo_id" ]; then
        read -p "$(print_message "$language" "目录 '$geo_id' 已存在，是否删除并重新下载？(y/n): " "Directory '$geo_id' already exists. Do you want to delete and re-download? (y/n): ")" confirm
        if [[ "$confirm" == "y" ]]; then
            rm -rf "$geo_id"
        else
            print_message "$language" "下载操作已取消。" "Download operation has been canceled."
            return
        fi
    fi

    # Create new directory
    mkdir -p "$geo_id"

    # Define additional wget options
    wget_options="-r -nH --cut-dirs=3 --timeout=600 --progress=dot"
    if $silent; then
        wget_options="$wget_options -q"
    fi

    # Download data with wget
    print_message "$language" "开始下载 ${geo_id} ..." "Starting download for ${geo_id} ..."
    if $silent; then
        nohup wget $wget_options "${url}" >"${geo_id}/${geo_id}_download.log" 2>&1 &
        print_message "$language" "数据下载 '${geo_id}' 正在后台静默运行。/ The data download for '${geo_id}' is running silently in the background." "The data download for '${geo_id}' is running silently in the background."
        print_message "$language" "请查看 '${geo_id}/${geo_id}_download.log' 以获取进度。" "Check '${geo_id}/${geo_id}_download.log' for progress."
    else
        wget $wget_options "${url}"
        if [ $? -eq 0 ]; then
            print_message "$language" "下载 '${geo_id}' 成功完成。" "The '${geo_id}' download succeeded."
        else
            print_message "$language" "下载 '${geo_id}' 失败，请检查日志。" "The '${geo_id}' download failed, please check the log."
        fi
    fi
}

# Loop through all provided GEO_IDs and download data
for geo_id in "${geo_ids[@]}"; do
    download_geo_data "$geo_id"
done
