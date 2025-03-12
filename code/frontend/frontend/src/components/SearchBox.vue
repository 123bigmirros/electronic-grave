<template>
    <div>
        <!-- 触发区域 - 当鼠标移动到页面顶部时显示导航栏 -->
        <div class="nav-trigger" @mouseenter="expandNav"></div>
        
        <div 
            class="top-nav" 
            :class="{ 'expanded': isExpanded }"
            @mouseenter="expandNav" 
            @mouseleave="collapseNav"
        >
            <div class="nav-content">
                <div class="search-container">
                    <div class="search-box">
                        <input 
                            type="text" 
                            v-model="searchQuery" 
                            placeholder="搜索..."
                            @focus="expandNav"
                        >
                        <button class="nav-button" @click="handleSearch">搜索</button>
                    </div>
                    
                    <!-- 搜索结果展示 -->
                    <div 
                        v-if="searchResults.length > 0" 
                        class="search-results"
                        v-click-outside="closeSearchResults"
                    >
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
                    <button class="nav-button" @click="goToHome">主页</button>
                    <button class="nav-button" @click="goToPersonal">个人主页</button>
                    <button class="nav-button" @click="goToCreate">创作</button>
                </div>
            </div>
        </div>
    </div>  
</template>

<script>
import request_py from '../utils/requests_py';

export default {
    name: 'SearchBox',
    directives: {
        'click-outside': {
            mounted(el, binding) {
                el._clickOutside = (event) => {
                    if (!(el === event.target || el.contains(event.target))) {
                        binding.value(event);
                    }
                };
                document.addEventListener('click', el._clickOutside);
            },
            unmounted(el) {
                document.removeEventListener('click', el._clickOutside);
            },
        },
    },
    data() {
        return {
            searchQuery: '',
            searchResults: [],
            chatHistory: [],
            isExpanded: false
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
                // 展开导航栏以显示结果
                this.expandNav();
            } catch (error) {
                console.error('搜索失败:', error);
            }
        },
        
        viewCanvas(canvasId) {
            // 导航到只读画布页面
            this.$router.push(`/canvas/view/${canvasId}`);
        },
        
        goToHome() {
            this.$router.push('/');
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
            console.log('尝试创建新画布');
            this.$router.push('/gravepaint/new');
        },
        
        closeSearchResults() {
            this.searchResults = [];
            // 如果没有搜索结果，可以考虑收缩导航栏
            this.collapseNav();
        },
        
        expandNav() {
            this.isExpanded = true;
        },
        
        collapseNav() {
            // 如果有搜索结果或者搜索框有内容，则不收缩
            if (this.searchResults.length > 0 || this.searchQuery.trim()) {
                return;
            }
            this.isExpanded = false;
        }
    }
}
</script>

<style scoped>
.nav-trigger {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    height: 10px;
    z-index: 1001;
}

.top-nav {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    padding: 5px 15px;
    background-color: rgba(255, 255, 255, 0.9);
    z-index: 1000;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    transform: translateY(-100%); /* 完全隐藏 */
    transition: transform 0.3s ease;
}

.top-nav.expanded {
    transform: translateY(0);
}

.nav-content {
    display: flex;
    align-items: center;
    justify-content: flex-end;
    max-width: 1200px;
    margin: 0 auto;
    gap: 20px;
}

.search-container {
    position: relative;
    width: 300px;
}

.search-box {
    display: flex;
    align-items: center;
    gap: 10px;
}

.search-box input {
    flex: 1;
    height: 36px;
    padding: 0 12px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 14px;
    box-sizing: border-box;
}

.nav-buttons {
    display: flex;
    gap: 10px;
    align-items: center;
}

.nav-button {
    height: 36px;
    padding: 0 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    white-space: nowrap;
    display: flex;
    align-items: center;
    justify-content: center;
}

.nav-button:hover {
    background-color: #45a049;
}

.search-results {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    margin-top: 5px;
    background: white;
    border: 1px solid #ddd;
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    max-height: 400px;
    overflow-y: auto;
}

.result-item {
    padding: 12px 15px;
    border-bottom: 1px solid #eee;
    cursor: pointer;
}

.result-item:last-child {
    border-bottom: none;
}

.result-item:hover {
    background-color: #f5f5f5;
}

.result-item h4 {
    margin: 0 0 5px 0;
    font-size: 14px;
}

.result-date {
    color: #666;
    font-size: 12px;
    margin: 0;
}
</style> 