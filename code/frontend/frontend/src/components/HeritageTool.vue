<template>
    <div
        class="canvas-item heritage-tool"
        :style="{
            left: position.left + 'px',
            top: position.top + 'px',
            width: position.width + 'px',
            height: position.height + 'px'
        }"
        @mousedown="startDrag"
        @keydown.backspace="deleteComponent"
        tabindex="0"
    >
        <!-- 添加调整大小的手柄 -->
        <div class="resize-handle top-left" @mousedown.stop="startResize('top-left')"></div>
        <div class="resize-handle top-right" @mousedown.stop="startResize('top-right')"></div>
        <div class="resize-handle bottom-left" @mousedown.stop="startResize('bottom-left')"></div>
        <div class="resize-handle bottom-right" @mousedown.stop="startResize('bottom-right')"></div>

        <!-- 编辑模式 -->
        <template v-if="isEditMode">
            <div v-if="!isConfigured" class="heritage-config">
                <h4>遗嘱公开设置</h4>
                <div class="form-group">
                    <label>公开时间：</label>
                    <input type="datetime-local" v-model="publicTime" />
                </div>
                <button @click="confirmConfig" class="config-btn">确认设置</button>
            </div>

            <div v-else>
                <div class="header">
                    <div class="heritage-header">
                        公开时间：{{ formatDate(publicTime) }}
                    </div>
                    <button class="add-button" @click="editHeritage">+</button>
                </div>
                
                <div v-if="!isEditing" class="heritage-display">
                    <div class="heritage-items">
                        <div v-for="(item, index) in heritageItems" :key="index" class="heritage-item">
                            {{ item.content }}
                            <span class="visibility-badge">{{ item.isPrivate ? '有缘者得' : '所有人可见' }}</span>
                        </div>
                    </div>
                </div>

                <div v-else class="heritage-editor">
                    <div class="add-item-form">
                        <textarea v-model="newItemContent" placeholder="输入遗产信息" @keydown.esc="cancelEdit"></textarea>
                        <div class="form-controls">
                            <label>
                                <input type="checkbox" v-model="newItemIsPrivate">
                                有缘者得
                            </label>
                            <button @click="addHeritageItem" class="add-item-btn">添加</button>
                        </div>
                    </div>
                </div>
            </div>
        </template>

        <!-- 显示模式 -->
        <template v-else>
            <div class="header">
                <div class="heritage-header" v-if="!isTimeToShow">
                    距离公开还有：{{ countdownText }}
                </div>
                <div class="heritage-header" v-else>
                    公开时间：{{ formatDate(publicTime) }}
                </div>
            </div>
            
            <div v-if="isTimeToShow" class="heritage-display">
                <div class="heritage-items">
                    <!-- 非私密内容 -->
                    <div v-for="(item, index) in nonePrivateItems" :key="'public-'+index" class="heritage-item">
                        {{ item.content }}
                        <span class="visibility-badge">所有人可见</span>
                    </div>
                    
                    <!-- 私密内容 -->
                    <div v-if="hasPrivateItems" class="heritage-item private-item">
                        <button 
                            class="request-btn"
                            @click="requestPrivateContent"
                            :disabled="isRequesting"
                        >
                            {{ isRequesting ? '请求中...' : '点击争抢有缘内容' }}
                        </button>
                    </div>
                </div>
            </div>
        </template>
    </div>
</template>

<script>
import request from '../utils/request'

export default {
    props: {
        initialPosition: {
            type: Object,
            default: () => ({
                left: 100,
                top: 100,
                width: 300,
                height: 200
            })
        },
        isEditMode: {
            type: Boolean,
            default: true
        }
    },
    data() {
        return {
            position: { ...this.initialPosition },
            isConfigured: false,
            isEditing: false,
            publicTime: '',
            heritageItems: [],
            newItemContent: '',
            newItemIsPrivate: false,
            dragging: false,
            offsetX: 0,
            offsetY: 0,
            countdown: null,
            remainingTime: 0,
            currentTime: new Date(),
            nonePrivateItems: [],
            hasPrivateItems: false,
            isRequesting: false,
            heritageId: null,
            resizing: false,
            resizeHandle: null,
            initialWidth: 0,
            initialHeight: 0,
            initialLeft: 0,
            initialTop: 0,
        };
    },
    computed: {
        isTimeToShow() {
            return this.currentTime >= new Date(this.publicTime);
        },
        countdownText() {
            if (this.remainingTime <= 0) return '已公开';
            
            const days = Math.floor(this.remainingTime / (24 * 60 * 60));
            const hours = Math.floor((this.remainingTime % (24 * 60 * 60)) / (60 * 60));
            const minutes = Math.floor((this.remainingTime % (60 * 60)) / 60);
            const seconds = Math.floor(this.remainingTime % 60);
            
            let text = '';
            if (days > 0) text += `${days}天`;
            if (hours > 0) text += `${hours}小时`;
            if (minutes > 0) text += `${minutes}分钟`;
            text += `${seconds}秒`;
            
            return text;
        }
    },
    methods: {
        formatDate(date) {
            const dateObj = new Date(date);
            if (dateObj.getFullYear() === 1970) {
                return '未设置';
            }
            return dateObj.toLocaleString();
        },
        confirmConfig() {
            if (!this.publicTime) {
                this.publicTime = '1970-01-01T00:00:00';
            }
            this.isConfigured = true;
            this.$emit('configureHeritage', {
                publicTime: this.publicTime
            });
        },
        addHeritageItem() {
            if (!this.newItemContent.trim()) {
                alert('请输入遗产信息！');
                return;
            }
            this.heritageItems.push({
                content: this.newItemContent,
                isPrivate: this.newItemIsPrivate
            });
            this.newItemContent = '';
            this.$emit('updateContent', {
                publicTime: this.publicTime,
                items: this.heritageItems
            });
            this.isEditing = false;
        },
        editHeritage() {
            this.isEditing = true;
        },
        cancelEdit() {
            this.isEditing = false;
            this.newItemContent = '';
        },
        startDrag(event) {
            if (event.target.tagName.toLowerCase() === 'input' || 
                event.target.tagName.toLowerCase() === 'textarea' ||
                event.target.tagName.toLowerCase() === 'button') {
                return;
            }
            this.dragging = true;
            this.offsetX = event.clientX - this.position.left;
            this.offsetY = event.clientY - this.position.top;
            window.addEventListener('mousemove', this.onDrag);
            window.addEventListener('mouseup', this.stopDrag);
        },
        onDrag(event) {
            if (this.dragging) {
                this.position.left = event.clientX - this.offsetX;
                this.position.top = event.clientY - this.offsetY;
                this.$emit('updatePosition', this.position);
            }
        },
        stopDrag() {
            this.dragging = false;
            window.removeEventListener('mousemove', this.onDrag);
            window.removeEventListener('mouseup', this.stopDrag);
        },
        updateCountdown() {
            this.currentTime = new Date();
            const targetTime = new Date(this.publicTime).getTime();
            const now = this.currentTime.getTime();
            this.remainingTime = Math.max(0, Math.floor((targetTime - now) / 1000));
        },
        startCountdown() {
            this.updateCountdown();
            
            if (this.countdown) {
                clearInterval(this.countdown);
            }
            
            if (!this.isTimeToShow) {
                this.countdown = setInterval(() => {
                    this.updateCountdown();
                    
                    if (this.isTimeToShow) {
                        clearInterval(this.countdown);
                        // 到达公开时间后获取内容
                        this.fetchNonePrivateContent();
                    }
                }, 1000);
            } else {
                // 如果已经到达公开时间，直接获取内容
                this.fetchNonePrivateContent();
            }
        },
        async fetchNonePrivateContent() {
            try {
                const response = await request.get('/canvas/heritage/NonePrivateHeritage');
                if (response.data.success) {
                    this.nonePrivateItems = response.data.data || [];
                    this.hasPrivateItems = response.data.data.some(item => item.isPrivate);
                }
            } catch (error) {
                console.error('获取公开内容失败:', error);
            }
        },
        async requestPrivateContent() {
            this.isRequesting = true;
            try {
                const response = await request.post('/canvas/heritage/getheritage', {
                    heritageId: this.heritageId
                });
                if (response.data.success) {
                    await this.fetchNonePrivateContent();
                } else {
                    alert('很遗憾，您与这份遗产无缘');
                }
            } catch (error) {
                console.error('请求私密内容失败:', error);
                alert('请求失败，请稍后重试');
            } finally {
                this.isRequesting = false;
            }
        },
        startResize(handle) {
            this.resizing = true;
            this.resizeHandle = handle;
            this.initialWidth = this.position.width;
            this.initialHeight = this.position.height;
            this.initialLeft = this.position.left;
            this.initialTop = this.position.top;
            
            window.addEventListener('mousemove', this.onResize);
            window.addEventListener('mouseup', this.stopResize);
        },
        onResize(event) {
            if (!this.resizing) return;

            // 计算鼠标移动的距离
            const mouseX = event.clientX;
            const mouseY = event.clientY;
            
            // 预先声明所有可能用到的变量
            let newWidthBL, newHeightTR, newWidthTL, newHeightTL;

            switch (this.resizeHandle) {
                case 'bottom-right':
                    // 直接使用鼠标位置计算新的宽度和高度
                    this.position.width = Math.max(100, mouseX - this.position.left);
                    this.position.height = Math.max(100, mouseY - this.position.top);
                    break;
                    
                case 'bottom-left':
                    newWidthBL = Math.max(100, this.initialLeft + this.initialWidth - mouseX);
                    this.position.left = Math.min(this.initialLeft + this.initialWidth - 100, mouseX);
                    this.position.width = newWidthBL;
                    this.position.height = Math.max(100, mouseY - this.position.top);
                    break;
                    
                case 'top-right':
                    newHeightTR = Math.max(100, this.initialTop + this.initialHeight - mouseY);
                    this.position.top = Math.min(this.initialTop + this.initialHeight - 100, mouseY);
                    this.position.width = Math.max(100, mouseX - this.position.left);
                    this.position.height = newHeightTR;
                    break;
                    
                case 'top-left':
                    newWidthTL = Math.max(100, this.initialLeft + this.initialWidth - mouseX);
                    newHeightTL = Math.max(100, this.initialTop + this.initialHeight - mouseY);
                    this.position.left = Math.min(this.initialLeft + this.initialWidth - 100, mouseX);
                    this.position.top = Math.min(this.initialTop + this.initialHeight - 100, mouseY);
                    this.position.width = newWidthTL;
                    this.position.height = newHeightTL;
                    break;
            }

            // 发送更新事件
            this.$emit('updatePosition', this.position);
        },
        stopResize() {
            this.resizing = false;
            window.removeEventListener('mousemove', this.onResize);
            window.removeEventListener('mouseup', this.stopResize);
        },
        deleteComponent() {
            if (!this.isEditing && !this.isConfigured) {  // 只在非编辑状态且未配置时允许删除
                this.$emit('delete');
            }
        }
    },
    watch: {
        publicTime: {
            handler(newVal) {
                if (newVal) {
                    this.startCountdown();
                }
            },
            immediate: true
        },
        isTimeToShow: {
            handler(newVal) {
                if (newVal) {
                    this.fetchNonePrivateContent();
                }
            },
            immediate: true
        }
    },
    mounted() {
        if (this.publicTime) {
            this.startCountdown();
        }
    },
    beforeUnmount() {
        if (this.countdown) {
            clearInterval(this.countdown);
        }
    }
};
</script>

<style scoped>
.heritage-tool {
    position: absolute;
    padding: 15px;
    background-color: #f5f5f5;
    border: 1px solid #ddd;
    border-radius: 8px;
    cursor: move;
}

.heritage-config {
    text-align: center;
}

.form-group {
    margin: 10px 0;
}

.heritage-display {
    cursor: pointer;
}

.heritage-header {
    font-size: 14px;
    color: #666;
    margin-bottom: 10px;
}

.heritage-items {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.heritage-item {
    background: white;
    padding: 8px;
    border-radius: 4px;
    border: 1px solid #ddd;
    margin-bottom: 8px;
    position: relative;
}

.visibility-badge {
    font-size: 12px;
    color: #666;
    float: right;
}

.heritage-editor {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.add-item-form {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

textarea {
    width: 100%;
    min-height: 60px;
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
}

.form-controls {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

button {
    padding: 5px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

button:hover {
    background-color: #45a049;
}

.done-btn {
    width: 100%;
    margin-top: 10px;
}

.header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px;
}

.heritage-header {
    font-size: 14px;
    color: #666;
}

.add-button {
    background: none;
    border: none;
    color: #666;
    font-size: 20px;
    padding: 0;
    cursor: pointer;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.add-button:hover {
    color: #333;
}

.heritage-display {
    padding: 0 10px;
}

.add-item-btn {
    padding: 8px 20px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
}

.add-item-btn:hover {
    background-color: #45a049;
}

.heritage-editor {
    padding-top: 20px;
}

.countdown-text {
    color: #ff4444;
    font-weight: bold;
}

.request-btn {
    width: 100%;
    padding: 8px;
    margin-top: 5px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 0.3s;
}

.request-btn:hover {
    background-color: #45a049;
}

.request-btn:disabled {
    background-color: #cccccc;
    cursor: not-allowed;
}

.private-item {
    background-color: #f8f8f8;
    border: 1px dashed #ddd;
}

.heritage-item {
    margin-bottom: 10px;
    padding: 12px;
    border-radius: 6px;
    background-color: white;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.visibility-badge {
    font-size: 12px;
    color: #666;
    float: right;
    padding: 2px 6px;
    background-color: #f0f0f0;
    border-radius: 3px;
}

.resize-handle {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: white;
    border: 1px solid #666;
    border-radius: 50%;
}

.top-left {
    top: -5px;
    left: -5px;
    cursor: nw-resize;
}

.top-right {
    top: -5px;
    right: -5px;
    cursor: ne-resize;
}

.bottom-left {
    bottom: -5px;
    left: -5px;
    cursor: sw-resize;
}

.bottom-right {
    bottom: -5px;
    right: -5px;
    cursor: se-resize;
}

.canvas-item {
    outline: none;
}
</style> 