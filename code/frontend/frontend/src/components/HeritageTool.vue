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
                    
                    <!-- 已获得的私密内容 -->
                    <div v-if="receivedPrivateItem" class="heritage-item private-item received">
                        {{ receivedPrivateItem.content }}
                        <span class="visibility-badge special">有缘者得</span>
                    </div>
                    
                    <!-- 争抢按钮移到最下方 - 如果没有收到私密内容则显示 -->
                    <div v-if="!receivedPrivateItem" class="heritage-item private-item request-container">
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
        },
        initialPublicTime: {
            type: String,
            default: ''
        },
        initialHeritageItems: {
            type: Array,
            default: () => []
        },
        heritageId: {
            type: String,
            default: null
        }
    },
    data() {
        return {
            position: { ...this.initialPosition },
            isConfigured: this.initialPublicTime !== '' || this.initialHeritageItems.length > 0,
            isEditing: false,
            publicTime: this.initialPublicTime || '',
            heritageItems: [...this.initialHeritageItems],
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
            resizing: false,
            resizeHandle: null,
            initialWidth: 0,
            initialHeight: 0,
            initialLeft: 0,
            initialTop: 0,
            receivedPrivateItem: null,
            contentLoaded: false
        };
    },
    computed: {
        isTimeToShow() {
            return this.publicTime && this.currentTime >= new Date(this.publicTime);
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
            
            if (this.remainingTime === 0 && !this.contentLoaded && !this.isEditMode) {
                this.contentLoaded = true;
                // this.loadContent();
            }
        },
        startCountdown() {
            this.updateCountdown();
            
            if (this.countdown) {
                clearInterval(this.countdown);
            }
            
            this.countdown = setInterval(() => {
                this.updateCountdown();
            }, 1000);
        },
        async loadContent() {
            
            if (!this.heritageId) return;
            
            try {
                // 获取所有公开内容和用户已获得的私密内容
                const response = await request.get('/user/canvas/heritage/NonePrivateHeritage', {
                    params: {
                        heritageId: this.heritageId
                    }
                });
                // alert(JSON.stringify(response.data))
                console.log('获取到的公开内容:', response.data);
                
                this.nonePrivateItems = response.data.data || [];
                
                
            } catch (error) {
                console.error('加载内容失败:', error);
            }
        },
        requestPrivateContent() {
            if (this.isRequesting || !this.heritageId) return;
            
            this.isRequesting = true;
            
            // 修改为使用URL参数方式发送请求
            request({
                method: 'post',
                url: '/user/canvas/heritage/getheritage',
                params: { heritageId: this.heritageId } // 使用params将参数作为URL查询参数发送
            })
            .then(response => {
                console.log("争抢请求响应:", response);
                if (response.data.code === 1 && response.data.data) {
                    // 争抢成功
                    this.receivedPrivateItem = response.data.data;
                    alert('恭喜您获得了有缘内容！');
                } else {
                    // 争抢失败或没有私密内容
                    alert(response.data.msg || '很遗憾，您与这份遗产无缘');
                }
            })
            .catch(error => {
                console.error('请求私密内容失败:', error);
                alert('请求失败，请稍后再试');
            })
            .finally(() => {
                this.isRequesting = false;
            });
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
            if (!this.isEditing) {
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
    },
    mounted() {
        if (this.initialPublicTime || this.initialHeritageItems.length > 0) {
            this.isConfigured = true;
            if (!this.publicTime && this.initialHeritageItems.length > 0) {
                this.publicTime = '1970-01-01T00:00:00';
            }
        }
        
        if (this.publicTime) {
            this.startCountdown();
        }

        if (this.isConfigured && this.heritageItems.length > 0) {
            this.$emit('updateContent', {
                publicTime: this.publicTime,
                items: this.heritageItems
            });
        }

        // 如果在显示模式且已到公开时间，则加载内容
        if (!this.isEditMode && this.isTimeToShow) {
            this.contentLoaded = true;
            this.loadContent();
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
    border: 1px solid #4f8cff;
    border-radius: 50%;
    z-index: 10;
    /* 默认隐藏控制点 */
    opacity: 0;
    transition: opacity 0.2s ease;
}

/* 鼠标悬停时显示控制点 */
.canvas-item.heritage-tool:hover .resize-handle {
    opacity: 1;
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

.received {
    background-color: #f0fff0;
    border: 1px solid #4CAF50;
}

.special {
    background-color: #4CAF50;
    color: white;
}
</style> 