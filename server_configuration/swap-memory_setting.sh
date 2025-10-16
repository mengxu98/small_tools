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

# Function to create or update swap memory
create_swap() {
    local size_gb="$1"
    local size_kb=$((size_gb * 1024 * 1024))  # Convert GB to KB
    local swap_file="/swap/swapfile"

    # Check if /swap directory exists, if not, create it
    if [[ ! -d "/swap" ]]; then
        sudo mkdir -p /swap
    fi

    print_message "$lang" "正在设置交换内存大小为 ${size_gb}G..." "Setting swap memory size to ${size_gb}G..."
    sudo dd if=/dev/zero of="$swap_file" bs=1024 count="$size_kb"
    sudo chmod 600 "$swap_file"
    sudo mkswap "$swap_file"
    sudo swapon "$swap_file"

    # Update fstab for persistence
    print_message "$lang" "更新 /etc/fstab 以使交换内存在重启后保持有效..." "Updating /etc/fstab for swap persistence..."
    echo "$swap_file swap swap defaults 0 0" | sudo tee -a /etc/fstab
    print_message "$lang" "交换内存设置完成." "Swap memory setup completed."
}

# Function to remove or decrease swap size
remove_swap() {
    local swap_file="/swap/swapfile"
    print_message "$lang" "正在删除或减少交换内存..." "Removing or reducing swap memory..."
    sudo swapoff "$swap_file"
    sudo rm "$swap_file"
    sudo sed -i "/$swap_file/d" /etc/fstab  # Remove entry from fstab
    print_message "$lang" "交换内存已删除." "Swap memory removed."
}

# Main script execution
echo "交换内存设置脚本"
echo "Swap memory setup script"
echo "请选择语言 / Please select a language:"
echo "1. 中文"
echo "2. English"

# Read language choice
read -p "请输入您的选择 (1 或 2): " lang_choice

# Set language based on choice
if [[ "$lang_choice" == "1" ]]; then
    lang="cn"
else
    lang="en"
fi

# Provide options for actions
print_message "$lang" "请选择操作:" "Select an operation:"
print_message "$lang" "1. 创建或更新交换内存" "1. Create or update swap memory"
print_message "$lang" "2. 删除或减少交换内存" "2. Remove or reduce swap memory"

# Read user choice
read -p "$(print_message "$lang" '请输入您的选择 (1 或 2): ' 'Enter your choice (1 or 2): ')" choice

# Execute based on user choice
if [[ "$choice" == "1" ]]; then
    read -p "$(print_message "$lang" '请输入虚拟内存大小 (以G为单位): ' 'Enter swap size (in GB): ')" swap_size
    create_swap "$swap_size"
elif [[ "$choice" == "2" ]]; then
    remove_swap
else
    print_message "$lang" "无效选择，退出程序。" "Invalid choice. Exiting." && exit 1
fi
