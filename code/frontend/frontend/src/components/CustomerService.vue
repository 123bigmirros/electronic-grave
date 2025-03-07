<template>
    <div class="customer-service">
        <!-- 未展开时的小图标 -->
        <div v-if="!isExpanded" class="service-icon" @click="toggleExpand">
            <i class="fas fa-headset"></i>
        </div>
        
        <!-- 展开后的对话框 -->
        <div v-else class="chat-window">
            <div class="chat-header">
                <span>智能助手</span>
                <button class="close-btn" @click="toggleExpand">×</button>
            </div>
            
            <div class="chat-messages" ref="messageContainer">
                <div v-for="(message, index) in messages" 
                     :key="index" 
                     :class="['message', message.type]">
                    <div class="message-content">{{ message.content }}</div>
                </div>
            </div>
            
            <div class="chat-input">
                <input type="text" 
                       v-model="inputMessage" 
                       @keyup.enter="sendMessage"
                       placeholder="请输入您的问题...">
                <button @click="sendMessage">发送</button>
            </div>
        </div>
    </div>
</template>

<script>
import { io } from 'socket.io-client';

export default {
    name: 'CustomerService',
    props: {
        canvasId: {
            type: [String, Number],
            default: null
        },
        canvasData: {
            type: Object,
            default: () => ({})
        }
    },
    data() {
        return {
            isExpanded: false,
            messages: [],
            inputMessage: '',
            socket: null,
            sessionId: Date.now().toString() // 生成唯一会话ID
        }
    },
    methods: {
        toggleExpand() {
            this.isExpanded = !this.isExpanded;
            if (this.isExpanded && !this.socket) {
                this.connectWebSocket();
            }
        },
        
        connectWebSocket() {
            console.log('开始连接WebSocket...');
            
            this.socket = io('http://127.0.0.1:5001', {
                transports: ['polling'],
                autoConnect: true,
                reconnection: true,
                reconnectionDelay: 1000,
                reconnectionDelayMax: 5000,
                reconnectionAttempts: 5
            });
            
            this.socket.on('connect', () => {
                console.log('Socket连接成功！Socket ID:', this.socket.id);
                // 连接成功后立即发送初始化消息
                this.socket.emit('message', {
                    type: 'init',
                    session_id: this.sessionId,
                    canvas_id: this.canvasId,
                    canvas_data: this.canvasData
                });
            });
            
            this.socket.on('connect_error', (error) => {
                console.error('Socket连接错误:', error);
                this.addMessage('system', '连接失败，请稍后重试');
            });
            
            this.socket.on('response', (response) => {
                console.log('收到服务器响应:', response);
                const message = response?.answer || '无响应';
                const sources = response?.sources || [];
                
                // 构建显示内容，包含来源信息
                let displayContent = message;
                if (sources && sources.length > 0) {
                    displayContent += '\n\n参考来源：\n' + sources.join('\n');
                }
                
                this.addMessage('assistant', displayContent);
            });
            
            this.socket.on('disconnect', () => {
                console.log('Socket连接断开');
                this.addMessage('system', '连接已断开');
            });
        },
        
        sendMessage() {
            if (!this.inputMessage.trim()) return;
            
            this.addMessage('user', this.inputMessage);
            
            if (this.socket && this.socket.connected) {
                this.socket.emit('message', {
                    type: 'message',
                    session_id: this.sessionId,
                    message: this.inputMessage,
                    canvas_id: this.canvasId
                });
            } else {
                console.error('Socket未连接！');
                this.addMessage('system', '连接已断开，请刷新页面重试');
            }
            
            this.inputMessage = '';
        },
        
        addMessage(type, content) {
            this.messages.push({ type, content });
            this.$nextTick(() => {
                const container = this.$refs.messageContainer;
                container.scrollTop = container.scrollHeight;
            });
        }
    }
}
</script>

<style scoped>
.customer-service {
    position: fixed;
    right: 20px;
    bottom: 20px;
    z-index: 1000;
}

.service-icon {
    width: 60px;
    height: 60px;
    background-color: #4CAF50;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: white;
    font-size: 24px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.2);
}

.chat-window {
    width: 350px;
    height: 500px;
    background-color: white;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    display: flex;
    flex-direction: column;
}

.chat-header {
    padding: 15px;
    background-color: #4CAF50;
    color: white;
    border-radius: 10px 10px 0 0;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.close-btn {
    background: none;
    border: none;
    color: white;
    font-size: 24px;
    cursor: pointer;
}

.chat-messages {
    flex-grow: 1;
    padding: 15px;
    overflow-y: auto;
}

.message {
    margin-bottom: 10px;
    display: flex;
    flex-direction: column;
}

.message.user {
    align-items: flex-end;
}

.message.assistant, .message.system {
    align-items: flex-start;
}

.message-content {
    max-width: 80%;
    padding: 8px 12px;
    border-radius: 15px;
    word-wrap: break-word;
}

.user .message-content {
    background-color: #4CAF50;
    color: white;
}

.assistant .message-content {
    background-color: #f1f1f1;
    color: black;
}

.system .message-content {
    background-color: #ffd700;
    color: black;
}

.chat-input {
    padding: 15px;
    display: flex;
    gap: 10px;
}

.chat-input input {
    flex-grow: 1;
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
}

.chat-input button {
    padding: 8px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.chat-input button:hover {
    background-color: #45a049;
}
</style> 