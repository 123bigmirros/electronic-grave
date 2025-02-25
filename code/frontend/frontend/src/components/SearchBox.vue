<template>
    <div class="top-nav">
           
        
        
        <div class="search-container">
            <div class="search-box">
                <input 
                    type="text" 
                    v-model="searchQuery" 
                    placeholder="搜索..." 
                    @input="handleSearch"
                >
                <button @click="handleSearch">搜索</button>
            </div>
            
            <!-- 搜索结果展示 -->
            <div v-if="searchResults.length > 0" class="search-results">
                <div 
                    v-for="result in searchResults" 
                    :key="result.canvas_id" 
                    class="result-item"
                    @click="viewCanvas(result.canvas_id)"
                >
                    <h4>{{ result.title }}</h4>
                    <p class="result-date">{{ result.content_preview }}</p>
                </div>
            </div>
        </div>
        <div class="nav-buttons">
            <button @click="goToPersonal">个人主页</button>
            <button @click="goToCreate">创作</button>
        </div>
    </div>  
</template>

<script>
import request_py from '../utils/requests_py';

export default {
    name: 'SearchBox',
    data() {
        return {
            searchQuery: '',
            searchResults: [],
            chatHistory: []
        }
    },
    methods: {
        async handleSearch() {
            if (!this.searchQuery.trim()) return;
            
            try {
                const response = await request_py({
                    method: 'post',
                    url: '/api/search',
                    data: {
                        query: this.searchQuery,
                        user_id: localStorage.getItem('userId'),
                        chat_history: this.chatHistory
                    }
                });
                
                // 确保正确解析响应数据
                this.searchResults = response.data.sources || [];
                // 更新聊天历史
                if (response.data.answer) {
                    this.chatHistory.push([this.searchQuery, response.data.answer]);
                }
            } catch (error) {
                console.error('搜索失败:', error);
            }
        },
        
        viewCanvas(canvasId) {
            // 导航到只读画布页面
            this.$router.push(`/canvas/view/${canvasId}`);
        },
        goToPersonal() {
                const userId = localStorage.getItem('userId');
                if (!userId || userId === 'undefined') {
                    this.$router.push('/login');
                    return;
                }
                this.$router.push('/personal');
        },
        
        goToCreate() {
            console.log('尝试跳转到 gravepaint 页面');
            this.$router.push('/gravepaint');
        }
    }
}
</script>

<style scoped>
.top-nav {
    position: fixed;
    top: 0;
    right: 0;
    padding: 20px;
    display: flex;
    align-items: center;
    gap: 20px;
    z-index: 1000;
}
.nav-buttons {
    display: flex;
    gap: 10px;
}

.nav-buttons button {
    padding: 8px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.nav-buttons button:hover {
    background-color: #45a049;
}

.search-container {
    width: 100%;
    max-width: 600px;
    margin: 0 auto;
}

.search-box {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 20px;
}

input {
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
    width: 100%;
}

button {
    padding: 8px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

button:hover {
    background-color: #45a049;
}

.search-results {
    margin-top: 20px;
    border: 1px solid #ddd;
    border-radius: 4px;
}

.result-item {
    padding: 15px;
    border-bottom: 1px solid #eee;
    cursor: pointer;
    transition: background-color 0.2s;
}

.result-item:last-child {
    border-bottom: none;
}

.result-item:hover {
    background-color: #f5f5f5;
}

.result-date {
    color: #666;
    font-size: 0.9em;
    margin-top: 5px;
}
</style> 