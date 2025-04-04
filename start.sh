#!/bin/bash

# 服务器启动脚本
# 用于启动前端和后端服务

echo "启动所有服务..."

# 启动前端服务
start_frontend() {
  echo "启动前端服务..."
  sudo systemctl stop nginx
  cd code/frontend/frontend && yarn serve
}

# 启动后端Spring Boot服务
start_backend_springboot() {
  echo "启动后端Spring Boot服务..."
  cd code/backend/grave && mvn spring-boot:run
}

# 启动后端搜索API服务
start_backend_search() {
  echo "启动后端搜索API服务..."
  
  export OPENAI_API_BASE="https://api.chatanywhere.tech/v1"
  export OPENAI_API_KEY=""
  
  # 方法1：使用conda run (推荐)
  # cd code/backend/python && conda run -n grave python -m controller.search_api
  
  # 或者方法2：手动初始化conda (如果方法1不行)
  # cd code/backend/python
  # eval "$(conda shell.bash hook)"
  # conda activate grave
  # python -m controller.search_api
  
  # 或者方法3：使用完整路径 (如果前两种方法都不行)
  cd code/backend/python
  /root/anaconda3/envs/grave/bin/python -m controller.search_api
}

# 使用screen在后台启动各服务，将函数定义包含在传递给screen的命令中
screen -dmS frontend bash -c "$(declare -f start_frontend); start_frontend; exec bash"
sleep 2
screen -dmS backend-spring bash -c "$(declare -f start_backend_springboot); start_backend_springboot; exec bash"
sleep 5
screen -dmS backend-search bash -c "$(declare -f start_backend_search); start_backend_search; exec bash"

echo "所有服务已启动"
echo "查看所有screen会话: screen -ls"
echo "连接到特定会话: screen -r [会话名]"
echo "例如: screen -r frontend"
echo "从会话中分离: Ctrl+A 然后按 D"
