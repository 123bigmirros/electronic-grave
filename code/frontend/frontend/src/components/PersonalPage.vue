<template>
    <div class="personal-page">
        <SearchBox />
        <!-- 用户信息区域 -->
        <div class="user-info">
            <h2>个人主页</h2>
            <p>用户名：{{ username }}</p>
        </div>

        <!-- 画布列表区域 -->
        <div class="canvas-list">
            <h3>我的画布</h3>
            <div class="canvas-grid">
                <div v-for="canvas in canvasList" 
                     :key="canvas.id" 
                     class="canvas-item"
                     @click="viewCanvas(canvas.id)">
                    <div class="canvas-header">
                        <h4>{{ canvas.title }}</h4>
                        <span class="visibility-badge" :class="{ 'public': canvas.isPublic }">
                            {{ canvas.isPublic ? '公开' : '私密' }}
                        </span>
                    </div>
                    <div class="canvas-actions">
                        <button @click.stop="editCanvas(canvas.id)" class="edit-btn">编辑</button>
                        <button @click.stop="deleteCanvas(canvas.id)" class="delete-btn">删除</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import request from '../utils/request';
import SearchBox from './SearchBox.vue';
export default {
    name: 'PersonalPage',
    components: {
        SearchBox
    },
    data() {
        return {
            username: '',
            canvasList: []
        };
    },
    methods: {
        // 获取用户信息
        async getUserInfo() {
            try {
                const response = await request({
                    url: '/user/info/get',
                    method: 'post',
                    headers: {
                        "userId": localStorage.getItem('userId')
                    }
                });
                
                if (response.data.code === 1) {
                    this.username = response.data.data.username;
                    // alert(this.username);
                }
            } catch (error) {
                alert('获取用户信息失败:', error);
            }
        },

        // 获取用户的画布列表
        async getCanvasList() {
            try {
                const response = await request({
                    url: '/user/canvas/list',
                    method: 'post',
                    headers: {
                        "userId": localStorage.getItem('userId')
                    }
                });

                if (response.data.code === 1) {
                    this.canvasList = response.data.data;
                }
            } catch (error) {
                console.error('获取画布列表失败:', error);
            }
        },

        // 查看画布
        viewCanvas(canvasId) {
            this.$router.push(`/canvas/${canvasId}`);
        },

        // 编辑画布
        editCanvas(canvasId) {
            this.$router.push(`/gravepaint/${canvasId}`);
        },

        // 删除画布
        async deleteCanvas(canvasId) {
            if (!confirm('确定要删除这个画布吗？')) {
                return;
            }
            alert
            try {
                const response = await request({
                    url: `/user/canvas/delete/${canvasId}`,
                    method: 'get',
                    headers: {
                        "userId": localStorage.getItem('userId')
                    }
                });

                if (response.data.code === 1) {
                    // alert('删除成功');
                    this.getCanvasList(); // 重新获取列表
                } else {
                    alert('删除失败：' + response.data.msg);
                }
            } catch (error) {
                console.error('删除画布失败:', error);
                alert('删除失败，请稍后重试');
            }
        }
    },
    mounted() {
        // 检查用户是否登录
        const userId = localStorage.getItem('userId');
        if (!userId || userId === 'undefined') {
            this.$router.push('/login');
            return;
        }

        // 获取用户信息和画布列表
        this.getUserInfo();
        this.getCanvasList();
    }
};
</script>

<style scoped>
.personal-page {
    padding: 20px;
    max-width: 1200px;
    margin: 0 auto;
}

.user-info {
    background-color: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}

.canvas-list {
    background-color: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.canvas-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
    margin-top: 20px;
}

.canvas-item {
    background-color: #f5f5f5;
    border-radius: 8px;
    padding: 15px;
    cursor: pointer;
    transition: transform 0.2s;
}

.canvas-item:hover {
    transform: translateY(-2px);
}

.canvas-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
}

.canvas-header h4 {
    margin: 0;
    font-size: 16px;
}

.visibility-badge {
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    background-color: #e0e0e0;
}

.visibility-badge.public {
    background-color: #4CAF50;
    color: white;
}

.canvas-actions {
    display: flex;
    gap: 10px;
    margin-top: 10px;
}

.edit-btn, .delete-btn {
    padding: 6px 12px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    flex: 1;
}

.edit-btn {
    background-color: #4CAF50;
    color: white;
}

.delete-btn {
    background-color: #f44336;
    color: white;
}

.edit-btn:hover {
    background-color: #45a049;
}

.delete-btn:hover {
    background-color: #da190b;
}
</style> 