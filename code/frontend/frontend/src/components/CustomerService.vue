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
import request_py from '@/utils/requests_py'

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
            isLoading: false
        }
    },
    methods: {
        toggleExpand() {
            this.isExpanded = !this.isExpanded;
            if (this.isExpanded && this.messages.length === 0) {
                this.sendInitMessage();
            }
        },
        
        async sendInitMessage() {
            try {
                const response = await this.sendRequest({
                    type: 'init',
                    canvas_id: this.canvasId,
                    canvas_data: this.canvasData,
                    history: this.messages
                });
                
                if (response.data.answer) {
                    this.addMessage('assistant', response.data.answer);
                }
            } catch (error) {
                console.error('初始化请求失败:', error);
                this.addMessage('system', '连接失败，请稍后重试');
            }
        },
        
        async sendMessage() {
            if (!this.inputMessage.trim() || this.isLoading) return;
            
            const currentMessage = this.inputMessage;
            this.addMessage('user', currentMessage);
            this.inputMessage = ''; // 立即清空输入框
            this.isLoading = true;
            
            try {
                const response = await this.sendRequest({
                    type: 'message',
                    message: currentMessage,
                    canvas_id: this.canvasId,
                    canvas_data: this.canvasData,
                    history: this.messages
                });
                
                if (response.data.answer) {
                    this.addMessage('assistant', response.data.answer);
                }
            } catch (error) {
                console.error('发送消息失败:', error);
                this.addMessage('system', '发送失败，请稍后重试');
            } finally {
                this.isLoading = false;
            }
        },
        
        async sendRequest(data) {
            return await request_py.post('/api/chat', data);
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