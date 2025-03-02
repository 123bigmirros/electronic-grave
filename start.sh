#!/bin/bash

# 服务器启动脚本
# 用于启动前端和后端服务

echo "启动所有服务..."

# 启动前端服务
start_frontend() {
  echo "启动前端服务..."
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
  cd code/backend/grave && conda activate grave && python -m controller.search_api
}

# 启动后端Socket API服务
start_backend_socket() {
  echo "启动后端Socket API服务..."
  cd code/backend/grave && conda activate grave && python -m controller.socket_api
}

# 在不同的终端窗口中启动各服务
gnome-terminal --tab --title="前端" -- bash -c "start_frontend; exec bash"
gnome-terminal --tab --title="后端Spring" -- bash -c "start_backend_springboot; exec bash"
gnome-terminal --tab --title="后端搜索API" -- bash -c "start_backend_search; exec bash"
gnome-terminal --tab --title="后端Socket API" -- bash -c "start_backend_socket; exec bash"

echo "所有服务已启动"
