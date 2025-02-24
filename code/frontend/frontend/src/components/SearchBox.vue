<template>
    <div class="search-container">
        <div class="search-box">
            <input 
                type="text" 
                v-model="searchQuery" 
                placeholder="搜索..." 
                @keyup.enter="handleSearch"
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
                <p class="result-date">{{ new Date(result.created_at).toLocaleDateString() }}</p>
            </div>
        </div>
    </div>
</template>

<script>
import request from '../utils/request';

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
                const response = await request({
                    method: 'post',
                    url: '/api/search',
                    data: {
                        query: this.searchQuery,
                        user_id: localStorage.getItem('userId'),
                        chat_history: this.chatHistory
                    }
                });
                
                this.searchResults = response.data.sources;
                // 更新聊天历史
                this.chatHistory.push([this.searchQuery, response.data.answer]);
            } catch (error) {
                console.error('搜索失败:', error);
            }
        },
        
        viewCanvas(canvasId) {
            // 导航到只读画布页面
            this.$router.push(`/canvas/view/${canvasId}`);
        }
    }
}
</script>

<style scoped>
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