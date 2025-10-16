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

# Function to install cpolar
install_cpolar() {
    if ! command -v cpolar &> /dev/null; then
        print_message "$lang" "cpolar 未安装，正在安装..." "cpolar is not installed. Installing..."
        sudo apt-get install -y curl
        curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh | sudo bash
        print_message "$lang" "cpolar 安装成功。" "cpolar installed successfully."
    else
        print_message "$lang" "cpolar 已经安装。" "cpolar is already installed."
    fi

    if ! grep -q "authtoken:" /usr/local/etc/cpolar/cpolar.yml 2>/dev/null; then
        read -p "$(print_message "$lang" '请输入您的 cpolar 认证令牌: ' 'Please enter your cpolar authtoken: ')" user_token
        cpolar authtoken "$user_token"
    else
        print_message "$lang" "cpolar 认证令牌已存在，跳过输入。" "cpolar authtoken already exists, skipping input."
    fi

    sudo systemctl enable cpolar
    sudo systemctl start cpolar
    if sudo systemctl is-active --quiet cpolar; then
        print_message "$lang" "cpolar 服务正在运行。" "cpolar service is running."
    else
        print_message "$lang" "启动 cpolar 服务失败，请检查日志。" "Failed to start cpolar service, please check the logs."
    fi

    # Ask user about creating systemd service for cpolar http
    while true; do
        read -p "$(print_message "$lang" '您想为 "cpolar http" 创建 systemd 服务吗？ (y/n): ' 'Do you want to create a systemd service for "cpolar http"? (y/n): ')" create_service
        if [[ "$create_service" == "y" || "$create_service" == "Y" ]]; then
            read -p "$(print_message "$lang" '请输入要使用的端口号（以逗号分隔）: ' 'Enter the port numbers (comma separated): ')" port_input
            IFS=',' read -r -a port_array <<< "$port_input"

            for port_number in "${port_array[@]}"; do
                service_name="cpolar-http-$port_number"
                service_file="/etc/systemd/system/$service_name.service"

                # Check if the service file already exists
                if [[ -f "$service_file" ]]; then
                    read -p "$(print_message "$lang" "$service_file 文件已存在，您想删除并重新创建吗？ (y/n): " "$service_file already exists. Do you want to delete and recreate it? (y/n): ")" user_choice
                    if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
                        sudo rm "$service_file"
                        print_message "$lang" "$service_file 已删除。" "$service_file has been deleted."
                    else
                        print_message "$lang" "跳过创建 $service_file。" "Skipping creation of $service_file."
                        continue  # Skip to the next port number
                    fi
                fi

                print_message "$lang" "正在为 'cpolar http' 在端口 $port_number 创建 systemd 服务..." "Creating systemd service for 'cpolar http' on port $port_number..."

                # Create the service file
                sudo bash -c "cat > $service_file <<EOF
[Unit]
Description=Cpolar HTTP Tunnel Service on port $port_number
After=network.target

[Service]
ExecStart=/usr/local/bin/cpolar http $port_number
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

                sudo systemctl daemon-reload
                sudo systemctl enable "$service_name"
                sudo systemctl start "$service_name"

                if sudo systemctl is-active --quiet "$service_name"; then
                    print_message "$lang" "cpolar-http 服务在端口 $port_number 正在运行，并将在启动时自动启用。" "cpolar-http service on port $port_number is running and will start on boot."
                else
                    print_message "$lang" "启动 cpolar-http 服务在端口 $port_number 失败，请检查日志。" "Failed to start cpolar-http service on port $port_number, please check the logs."
                fi
            done
            break  # Exit the loop after successful creation of services
        elif [[ "$create_service" == "n" || "$create_service" == "N" ]]; then
            print_message "$lang" "跳过 'cpolar http' 的系统服务创建。" "Skipped creating systemd service for 'cpolar http'."
            break  # Exit the loop
        else
            print_message "$lang" "无效输入，请输入 'y' 或 'n'。" "Invalid input, please enter 'y' or 'n'."
        fi
    done
}

# Function to uninstall cpolar
uninstall_cpolar() {
    print_message "$lang" "正在卸载 cpolar..." "Uninstalling cpolar..."
    if command -v cpolar &> /dev/null; then
        curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh | sudo bash -s -- --remove
    fi

    if [[ -f /etc/systemd/system/cpolar.service ]]; then
        sudo systemctl disable cpolar
        sudo systemctl stop cpolar
        sudo rm /etc/systemd/system/cpolar.service
    else
        print_message "$lang" "cpolar 服务文件不存在，跳过。" "cpolar service file does not exist, skipping."
    fi

    for service_file in /etc/systemd/system/cpolar-http-*.service; do
        if [[ -f "$service_file" ]]; then
            service_name=$(basename "$service_file")
            sudo systemctl disable "$service_name"
            sudo systemctl stop "$service_name"
            sudo rm "$service_file"
            print_message "$lang" "$service_name 移除成功。" "$service_name removed successfully."
        fi
    done

    print_message "$lang" "您可能需要执行以下命令以删除依赖软件：apt purge curl unzip" "You may need to execute: apt purge curl unzip to remove dependent software."
    print_message "$lang" "cpolar 已成功卸载。" "cpolar uninstalled successfully."
    print_message "$lang" "提示：如有必要，请手动删除配置和日志文件。" "Info: If necessary, manually delete the configuration and log files."
}

# Main script execution
echo "欢迎使用 cpolar 安装/卸载配置脚本 / Welcome to the cpolar installation/uninstallation script."
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

print_message "$lang" "请选择一个选项:" "Select an option:"
print_message "$lang" "1. 安装 cpolar" "1. Install cpolar"
print_message "$lang" "2. 卸载 cpolar" "2. Uninstall cpolar"

# Read user choice
read -p "$(print_message "$lang" '请输入您的选择 (1 或 2): ' 'Enter your choice (1 or 2): ')" choice

# Validate choice
case $choice in
    1) install_cpolar ;;
    2) uninstall_cpolar ;;
    *) print_message "$lang" "无效选择，退出程序。" "Invalid choice. Exiting." ; exit 1 ;;
esac
