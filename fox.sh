#!/bin/bash

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker 已安装。${NC}"
        docker --version
        
        # 检查是否存在 docker-compose.yml 文件
        if [ -f "docker-compose.yml" ]; then
            echo
            echo -e "${BLUE}正在检查 AI 服务状态...${NC}"
            echo -e "${YELLOW}当前 AI 服务状态：${NC}"
            docker compose  ps
        fi
        
        return 0
    else
        echo -e "${RED}Docker 未安装。${NC}"
        return 1
    fi
}

# Function to install Docker
install_docker() {
    echo "正在安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
}

# Function to install AI services
install_ai_services() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    # 检查install.sh是否存在
    if [ ! -f "install.sh" ]; then
        echo -e "${RED}未找到 install.sh 文件，请确保该文件存在于当前目录。${NC}"
        return 1
    fi
    
    echo -e "${GREEN}正在安装 AI 服务...${NC}"
    
    # 生成随机的APIAUTH (32位随机字符串)
    APIAUTH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    echo -e "${GREEN}已生成APIAUTH配置${NC}"
    
    # 询问用户要安装哪些服务
    INSTALL_GROK=false
    INSTALL_DDD=false
    INSTALL_GPT=false
    
    while true; do
        read -p "是否安装 Grok 服务? (y/n): " yn < /dev/tty
        case $yn in
            [Yy]* ) INSTALL_GROK=true; break;;
            [Nn]* ) break;;
            * ) echo -e "${YELLOW}请输入 y 或 n${NC}";;
        esac
    done
    
    while true; do
        read -p "是否安装 Claude (DDD) 服务? (y/n): " yn < /dev/tty
        case $yn in
            [Yy]* ) INSTALL_DDD=true; break;;
            [Nn]* ) break;;
            * ) echo -e "${YELLOW}请输入 y 或 n${NC}";;
        esac
    done
    
    while true; do
        read -p "是否安装 GPT 服务? (y/n): " yn < /dev/tty
        case $yn in
            [Yy]* ) INSTALL_GPT=true; break;;
            [Nn]* ) break;;
            * ) echo -e "${YELLOW}请输入 y 或 n${NC}";;
        esac
    done
    
    # 获取网关配置
    DEFAULT_CHATPROXY="https://demo.xyhelper.cn"
    echo -n "请输入xyhelper网关 (默认: ${DEFAULT_CHATPROXY})："
    read CHATPROXY < /dev/tty
    # 如果用户直接回车，使用默认值
    CHATPROXY=${CHATPROXY:-$DEFAULT_CHATPROXY}
    
    # 导出环境变量供install.sh使用
    export FOX_APIAUTH="$APIAUTH"
    export FOX_CHATPROXY="$CHATPROXY"
    export FOX_INSTALL_GROK="$INSTALL_GROK"
    export FOX_INSTALL_DDD="$INSTALL_DDD"
    export FOX_INSTALL_GPT="$INSTALL_GPT"
    
    echo -e "${BLUE}正在调用安装脚本...${NC}"
    
    # 给install.sh执行权限并运行
    chmod +x install.sh
    ./install.sh
    
    echo "对fox 部署使用有任何疑问，请扫描二维码添加作者微信"
    echo   "█████████████████████████████████████
█████████████████████████████████████
████ ▄▄▄▄▄ ██▀▄██▀▀▀█▀█▀▀█ ▄▄▄▄▄ ████
████ █   █ █▄▀█▄██  ▄█▄███ █   █ ████
████ █▄▄▄█ ██▄▀▀▄▀  █ █▀▀█ █▄▄▄█ ████
████▄▄▄▄▄▄▄█ █▄█▄▀ █▄▀▄█ █▄▄▄▄▄▄▄████
████   █  ▄ ▄▀█ ▄▄▀▀▀ █▄▄  ██▀▄█▀████
████▀ █▀▀ ▄█▀▀ █▄▀ █▀ █▀▀█ ▄▄█▄ ▄████
████▄▄█ █▄▄▄▀▀ ██▄█   █▄   ██ █▄ ████
████▄ ▀ ▄ ▄ ▀▄▀▀▀▀ ▀▄▀ █▀▀█▄█ █ ▄████
██████▄▀▀▄▄▄▄▄▀▄█▄█▄█ ▀▄   ▄█ ▀▄ ████
████▄▀ █ ▀▄▄▀ ▄██▀ █▀ ▀███▄█▀▀█ ▄████
████▄█▄▄██▄▄▀▄▄█▀█▀   ▀▀ ▄▄▄ █▀▀▀████
████ ▄▄▄▄▄ █ ▀▀█▀ ▄█▀▀▄▄ █▄█  █▄▄████
████ █   █ █▄▀▄▄█ ▀▀▀▄█▀ ▄▄  █▀█ ████
████ █▄▄▄█ █  ▀██▀ █▄▀▀ ▀▄██▄▄█▀▄████
████▄▄▄▄▄▄▄█▄▄██▄▄██████▄█▄▄▄▄█▄▄████
█████████████████████████████████████
█████████████████████████████████████"
}

# Function to restart services
restart_services() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "未找到 docker-compose.yml 文件，请先安装 AI 服务。"
        return 1
    fi
    
    echo "正在重启服务..."
    chmod +x restart.sh
    ./restart.sh
}

# Function to stop services
stop_services() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "未找到 docker-compose.yml 文件，请先安装 AI 服务。"
        return 1
    fi
    
    echo "正在停止服务..."
    chmod +x stop.sh
    ./stop.sh
}

# Function to backup databases
backup_databases() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "未找到 docker-compose.yml 文件，请先安装 AI 服务。"
        return 1
    fi
    
    # 获取当前时间戳
    timestamp=$(date +%Y%m%d-%H%M%S)
    
    # 创建本次备份的目录
    backup_dir="./backups/sql/backup-${timestamp}"
    mkdir -p "${backup_dir}"
    
    echo "正在备份数据库..."
    echo "备份文件将保存在: ${backup_dir}"
    
    # 备份 cool 数据库
    echo "正在备份 cool 数据库..."
    docker compose exec  mysql sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" cool' > "${backup_dir}/cool.sql"
    
    # 备份 grok_cool 数据库
    echo "正在备份 grok_cool 数据库..."
    docker compose exec  mysql sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" grok_cool' > "${backup_dir}/grok_cool.sql"
    
    # 备份 claude_cool 数据库
    echo "正在备份 claude_cool 数据库..."
    docker compose exec  mysql sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" claude_cool' > "${backup_dir}/claude_cool.sql"
    
    echo "数据库备份完成！"
    echo "备份文件保存在: ${backup_dir}"
}

# Function to restore databases
restore_databases() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "未找到 docker-compose.yml 文件，请先安装 AI 服务。"
        return 1
    fi
    
    # 检查备份目录是否存在
    if [ ! -d "./backups" ]; then
        echo "未找到备份目录，请先进行备份。"
        return 1
    fi
    
    # 获取所有备份目录
    backup_dirs=($(ls -d ./backups/sql/backup-* 2>/dev/null))
    
    if [ ${#backup_dirs[@]} -eq 0 ]; then
        echo "未找到任何备份文件。"
        return 1
    fi
    
    # 显示可用的备份
    echo "可用的备份："
    for i in "${!backup_dirs[@]}"; do
        echo "$(($i+1)). ${backup_dirs[$i]}"
    done
    
    # 让用户选择要还原的备份
    while true; do
        read -p "请选择要还原的备份编号 (1-${#backup_dirs[@]}): " choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#backup_dirs[@]} ]; then
            selected_backup="${backup_dirs[$(($choice-1))]}"
            break
        else
            echo "无效的选择，请重新输入。"
        fi
    done
    
    # 确认还原
    read -p "确定要还原备份 ${selected_backup} 吗？这将覆盖现有数据！(y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "已取消还原。"
        return 0
    fi
    
    echo "正在还原数据库..."
    
    # 还原 cool 数据库
    if [ -f "${selected_backup}/cool.sql" ]; then
        echo "正在还原 cool 数据库..."
        docker compose exec  -T mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" cool' < "${selected_backup}/cool.sql"
    fi
    
    # 还原 grok_cool 数据库
    if [ -f "${selected_backup}/grok_cool.sql" ]; then
        echo "正在还原 grok_cool 数据库..."
        docker compose exec  -T mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" grok_cool' < "${selected_backup}/grok_cool.sql"
    fi
    
    # 还原 claude_cool 数据库
    if [ -f "${selected_backup}/claude_cool.sql" ]; then
        echo "正在还原 claude_cool 数据库..."
        docker compose exec  -T mysql sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" claude_cool' < "${selected_backup}/claude_cool.sql"
    fi
    
    echo "数据库还原完成！"
}

# Function to setup auto backup
setup_auto_backup() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "未找到 docker-compose.yml 文件，请先安装 AI 服务。"
        return 1
    fi

    # 检查是否已经设置了自动备份
    crontab -l 2>/dev/null | grep -q "auto_backup.sh"
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}检测到已经设置了自动备份任务。${NC}"
        read -p "是否要取消自动备份？(y/n): " cancel
        if [[ $cancel =~ ^[Yy]$ ]]; then
            # 删除现有的自动备份任务
            (crontab -l 2>/dev/null | grep -v "auto_backup.sh") | crontab -
            echo -e "${GREEN}已取消自动备份任务。${NC}"
        fi
        return 0
    fi

    # 设置自动备份
    echo -e "${BLUE}正在设置每天凌晨4点自动备份...${NC}"
    
    # 获取脚本所在目录的绝对路径
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    
    # 确保备份脚本有执行权限
    chmod +x "${SCRIPT_DIR}/auto_backup.sh"
    
    # 添加定时任务
    (crontab -l 2>/dev/null; echo "0 4 * * * ${SCRIPT_DIR}/auto_backup.sh >> ${SCRIPT_DIR}/backups/auto_backup.log 2>&1") | crontab -
    
    echo -e "${GREEN}自动备份已设置完成！${NC}"
    echo -e "${BLUE}系统将在每天凌晨4点自动进行数据库备份${NC}"
    echo -e "${YELLOW}备份日志将保存在 backups/auto_backup.log${NC}"
}

# Function to update and restart fox services
update_and_restart_fox() {
    if ! check_docker; then
        echo "Docker 未安装，请先安装 Docker。"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "未找到 docker-compose.yml 文件，请先安装 AI 服务。"
        return 1
    fi
    
    echo -e "${BLUE}正在更新 fox 服务...${NC}"
    docker compose pull chatgpt-share-server-fox
    
    echo -e "${BLUE}正在重启 fox 服务...${NC}"
    docker compose up -d chatgpt-share-server-fox
    
    echo -e "${GREEN}fox 服务已更新并重启完成！${NC}"
}

# Main menu
while true; do
    echo -e "${GREEN}请选择操作：${NC}"
    echo -e "${YELLOW}1. 安装 Docker${NC}"
    echo -e "${YELLOW}2. 安装 fox 服务${NC}"
    echo -e "${BLUE}3. 更新并重启 fox 服务${NC}"
    echo -e "${BLUE}4. 更新并重启所有服务${NC}"
    echo -e "${BLUE}5. 停止服务${NC}"
    echo -e "${MAGENTA}6. 备份数据库${NC}"
    echo -e "${MAGENTA}7. 还原数据库${NC}"
    echo -e "${CYAN}8. 设置自动备份${NC}"
    echo -e "${RED}9. 退出${NC}"
    
    read -p "请输入选项 (1-9): " choice < /dev/tty
    
    case $choice in
        1)
            install_docker
            ;;
        2)
            install_ai_services
            ;;
        3)
            update_and_restart_fox
            ;;
        4)
            restart_services
            ;;
        5)
            stop_services
            ;;
        6)
            backup_databases
            ;;
        7)
            restore_databases
            ;;
        8)
            setup_auto_backup
            ;;
        9)
            echo -e "${RED}正在退出...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选项，请重新输入。${NC}"
            ;;
    esac
    
    echo
done
