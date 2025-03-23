<template>
    <div id="app">
        <SearchBox />
        <div class="container">
            <!-- 左侧工具栏 -->
            <div class="toolbar">
                <h3>工具栏</h3>
                <!-- 文本框工具 -->
                <div class="tool" @click="addTextTool">
                    <p>文本框</p>
                </div>
                <div class="tool" @click="addImgTool">
                    <p>图片框</p>
                </div>
                <div class="tool" @click="addHeritageTool">
                    <p>遗产信息</p>
                </div>
                <div class="tool" @click="addMarkdownTool">
                    <p>Markdown编辑器</p>
                </div>
                <!-- 添加上传图片按钮 -->
                
                <div class="tool" @click="saveCanvas">
                    <p>保存画布</p>
                </div>
                <div class="tool upload-tool" @click="openImageUploader">
                    <p>上传图片</p>
                </div>
                <!-- 对话控制按钮 -->
                <div class="tool chat-tool" @click="toggleChatInput">
                    <p>对话控制</p>
                </div>
            </div>

            <!-- 分界线 -->
            <div class="divider"></div>

            <!-- 右侧画布 -->
            <div class="canvas">
                <h3>画布</h3>
                <!-- 为每个组件添加序号标识 -->
                <div 
                    v-for="(item, index) in canvasItems.texts" 
                    :key="item.id" 
                    class="component-number"
                    :style="{
                        left: (item.position.left - 10) + 'px',
                        top: (item.position.top - 20) + 'px'
                    }">
                    文本[{{ index + 1 }}]
                </div>
                
                <div 
                    v-for="(item, index) in canvasItems.images" 
                    :key="item.id" 
                    class="component-number"
                    :style="{
                        left: (item.position.left - 10) + 'px',
                        top: (item.position.top - 20) + 'px'
                    }">
                    图片[{{ index + 1 }}]
                </div>
                
                <div 
                    v-for="(item, index) in canvasItems.heritages" 
                    :key="item.id" 
                    class="component-number"
                    :style="{
                        left: (item.position.left - 10) + 'px',
                        top: (item.position.top - 20) + 'px'
                    }">
                    遗产[{{ index + 1 }}]
                </div>
                
                <div 
                    v-for="(item, index) in canvasItems.markdowns" 
                    :key="item.id" 
                    class="component-number"
                    :style="{
                        left: (item.position.left - 10) + 'px',
                        top: (item.position.top - 20) + 'px'
                    }">
                    MD[{{ index + 1 }}]
                </div>
                
                <!-- 显示添加的文本框 -->
                <TextTool
                        v-for="(item, index) in canvasItems.texts"
                        :key="item.id + '-' + JSON.stringify(item.position)"
                        :id="item.id"
                        :name="item.name"
                        :initialContent="item.content"
                        :initialPosition="item.position"
                        @updatePosition="updateTextPosition(index, $event)"
                        @updateName="updateTextName(index, $event)"
                        @delete="deleteComponent('text', index)"
                />
                <ImgTool
                        v-for="(item, index) in canvasItems.images"
                        :key="item.id + '-' + JSON.stringify(item.position)"
                        :id="item.id"
                        :name="item.name"
                        :initialImageUrl="item.imageUrl"
                        :initialPosition="item.position"
                        @updatePosition="updateImagePosition(index, $event)"
                        @updateName="updateImageName(index, $event)"
                        @delete="deleteComponent('image', index)"
                />
                <HeritageTool
                    v-for="(item, index) in canvasItems.heritages"
                    :key="item.id + '-' + JSON.stringify(item.position)"
                    :id="item.id"
                    :name="item.name"
                    :initialPosition="item.position"
                    :initialPublicTime="item.publicTime"
                    :initialHeritageItems="item.items || []"
                    :heritageId="item.id"
                    @updatePosition="updateHeritagePosition(index, $event)"
                    @updateName="updateHeritageName(index, $event)"
                    @configureHeritage="configureHeritage(index, $event)"
                    @updateContent="updateHeritageContent(index, $event)"
                    @delete="deleteComponent('heritage', index)"
                />
                <MarkdownTool
                    v-for="(item, index) in canvasItems.markdowns"
                    :key="item.id + '-' + JSON.stringify(item.position)"
                    :id="item.id"
                    :name="item.name"
                    :initialContent="item.content"
                    :initialPosition="item.position"
                    :isEditMode="true"
                    @updatePosition="updateMarkdownPosition(index, $event)"
                    @updateName="updateMarkdownName(index, $event)"
                    @updateContent="updateMarkdownContent(index, $event)"
                    @delete="deleteComponent('markdown', index)"
                />
            </div>
        </div>

        <!-- 添加保存画布对话框 -->
        <div v-if="showSaveDialog" class="save-dialog-overlay">
            <div class="save-dialog">
                <h3>保存画布</h3>
                <div class="form-group">
                    <label>画布标题：</label>
                    <input type="text" v-model="canvasTitle" placeholder="请输入画布标题" />
                </div>
                <div class="form-group">
                    <label>
                        <input type="checkbox" v-model="isPublic">
                        是否公开画布
                    </label>
                </div>
                <div class="dialog-buttons">
                    <button @click="confirmSave" class="save-btn">保存</button>
                    <button @click="cancelSave" class="cancel-btn">取消</button>
                </div>
            </div>
        </div>

        <!-- 图片上传输入 -->
        <input
            type="file"
            ref="uploadFileInput"
            accept="image/*"
            @change="handleFileSelect"
            style="display: none;"
        />

        <!-- 简化的消息提示 -->
        <div v-if="showNotification" class="notification" :class="{ 'fade-out': isNotificationFading }">
            {{ notificationMessage }}
        </div>
        
        <!-- 浮动聊天输入框 -->
        <div v-if="showChatInput" class="chat-input-floating">
            <div class="chat-input-container">
                <textarea 
                    v-model="userMessage" 
                    @keydown.enter.prevent="sendMessage" 
                    placeholder="输入指令控制画布组件..."
                    ref="chatTextarea"
                    autofocus
                ></textarea>
                <div class="send-arrow" @click="sendMessage">
                    <i class="arrow-icon">&#10148;</i>
                </div>
            </div>
        </div>

        <!-- 添加透明遮罩用于捕获点击事件 -->
        <div v-if="showChatInput" class="chat-overlay" @click="hideChatInput"></div>
    </div>
</template>

<script>
    import TextTool from './TextTool.vue';
    import ImgTool from './ImgTool.vue';
    import HeritageTool from './HeritageTool.vue';
    import MarkdownTool from './MarkdownTool.vue';
    import request from '../utils/request';
    import request_py from '../utils/requests_py';
    import SearchBox from './SearchBox.vue';
    export default {
        name: 'GravePaint',
        components: {
            TextTool,
            ImgTool,
            HeritageTool,
            MarkdownTool,
            SearchBox
        },
        data() {
            return {
                canvasItems:{ 
                    texts:[],
                    images: [],
                    heritages: [],
                    markdowns: []
                },// 用于存储添加到画布的元素
                showSaveDialog: false,
                canvasTitle: '',
                isPublic: true,
                canvasId: null,  // 新增：存储画布ID
                currentZIndex: 1,  // 添加一个跟踪当前z-index的计数器
                
                // 修改对话相关数据
                showChatInput: false,
                userMessage: '',
                chatHistory: [],
                isProcessing: false,
                
                // 替换旧的图片上传相关数据
                isUploading: false,
                uploadedImageUrl: '',
                showNotification: false,
                notificationMessage: '',
                isNotificationFading: false
            };
        },
        methods: {
            // 添加文本框到画布
            addTextTool() {
                this.addComponentByType('text');
            },
            addImgTool() {
                this.addComponentByType('image');
            },
            addHeritageTool() {
                this.addComponentByType('heritage');
            },
            addMarkdownTool() {
                this.addComponentByType('markdown');
            },
            updateTextPosition(index, newPosition) {
                this.canvasItems.texts[index].position = newPosition;
            },
            updateTextName(index, newName) {
                this.canvasItems.texts[index].name = newName;
            },
            updateImagePosition(index, newPosition) {
                this.canvasItems.images[index].position = newPosition;
            },
            updateImageName(index, newName) {
                this.canvasItems.images[index].name = newName;
            },
            updateHeritagePosition(index, newPosition) {
                this.canvasItems.heritages[index].position = newPosition;
            },
            updateHeritageName(index, newName) {
                this.canvasItems.heritages[index].name = newName;
            },
            configureHeritage(index, config) {
                this.canvasItems.heritages[index].publicTime = config.publicTime;
            },
            updateHeritageContent(index, content) {
                this.canvasItems.heritages[index].publicTime = content.publicTime;
                this.canvasItems.heritages[index].items = content.items;
            },
            updateMarkdownPosition(index, newPosition) {
                this.canvasItems.markdowns[index].position = newPosition;
            },
            updateMarkdownName(index, newName) {
                this.canvasItems.markdowns[index].name = newName;
            },
            updateMarkdownContent(index, content) {
                this.canvasItems.markdowns[index].content = content;
            },
            saveCanvas() {
                this.showSaveDialog = true;
            },
            cancelSave() {
                this.showSaveDialog = false;
                this.canvasTitle = '';
            },
            confirmSave() {
                if (!this.canvasTitle.trim()) {
                    alert('请输入画布标题！');
                    return;
                }
                
                // 关闭保存对话框
                this.showSaveDialog = false;
                
                // 显示"保存中..."通知
                this.showNotificationMessage('保存中...');
                
                // 处理画布数据，移除前端生成的ID
                const processedTexts = this.canvasItems.texts.map(item => {
                    // 如果ID是前端生成的（以'text-'开头），则不传递ID字段
                    const newItem = {...item};
                    if (typeof newItem.id === 'string' && newItem.id.startsWith('text-')) {
                        delete newItem.id;
                    }
                    return newItem;
                });
                
                const processedImages = this.canvasItems.images.map(item => {
                    const newItem = {...item};
                    if (typeof newItem.id === 'string' && newItem.id.startsWith('img-')) {
                        delete newItem.id;
                    }
                    return newItem;
                });
                
                const processedHeritages = this.canvasItems.heritages.map(item => {
                    const newItem = {...item};
                    if (typeof newItem.id === 'string' && newItem.id.startsWith('heritage-')) {
                        delete newItem.id;
                    }
                    return newItem;
                });
                
                const processedMarkdowns = this.canvasItems.markdowns.map(item => {
                    const newItem = {...item};
                    if (typeof newItem.id === 'string' && newItem.id.startsWith('md-')) {
                        delete newItem.id;
                    }
                    return newItem;
                });
                
                const canvasData = {
                    id: this.canvasId,
                    title: this.canvasTitle,
                    isPublic: this.isPublic?1:0,
                    texts: processedTexts,
                    images: processedImages,
                    heritages: processedHeritages,
                    markdowns: processedMarkdowns
                };

                request({
                    method: 'post',
                    url: '/user/canvas/save',
                    data: canvasData,
                    headers: {
                        "userId": localStorage.getItem('userId'),
                    }
                })
                .then(response => {
                    if (response.data.code === 1) {
                        this.canvasId = response.data.data;
                        
                        // 显示"保存成功"通知
                        this.showNotificationMessage('画布保存成功！');
                        
                        // 调用embedding API
                        request_py({
                            method: 'post',
                            url: '/api/canvas/embedding',
                            data: {
                                canvas_id: this.canvasId
                            }
                        });
                    } else {
                        // 显示保存失败通知
                        this.showNotificationMessage('保存失败：' + response.data.msg);
                        throw new Error('保存失败：' + response.data.msg);
                    }
                })
                .catch(error => {
                    console.error('操作失败:', error);
                    // 显示错误通知
                    this.showNotificationMessage('操作失败，请检查网络连接');
                });
            },
            deleteComponent(type, index) {
                switch(type) {
                    case 'text':
                        this.canvasItems.texts.splice(index, 1);
                        break;
                    case 'image':
                        this.canvasItems.images.splice(index, 1);
                        break;
                    case 'heritage':
                        this.canvasItems.heritages.splice(index, 1);
                        break;
                    case 'markdown':
                        this.canvasItems.markdowns.splice(index, 1);
                        break;
                }
            },
            // 新增：加载现有画布数据
            async loadCanvasData() {
                const canvasId = this.$route.params.id;

                if (!canvasId||canvasId==="undefined") {
                    this.canvasId = -1;
                    return;
                }
                
                this.canvasId = canvasId;
                try {
                    const response = await request({
                        url: `/user/canvas/get/${canvasId}/1`,
                        method: 'get',
                        headers: {
                            "userId": localStorage.getItem('userId')
                        }
                    });

                    if (response.data.code === 1) {
                        const canvasData = response.data.data;
                        // 更新画布标题和公开状态
                        this.canvasTitle = canvasData.title;
                        // alert(canvasData.isPublic);
                        this.isPublic = canvasData.isPublic==1?true:false;
                        
                        // 确保每个数组都有默认值，防止后端返回null
                        this.canvasItems = {
                            texts: canvasData.texts?.map(text => ({
                                id: text.id || 'text-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                                name: text.name || '文本框',
                                content: text.content,
                                position: {
                                    left: text.left,
                                    top: text.top,
                                    width: text.width,
                                    height: text.height
                                }
                            })) || [],
                            
                            images: canvasData.images?.map(image => ({
                                id: image.id || 'img-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                                name: image.name || '图片',
                                imageUrl: image.imageUrl,
                                position: {
                                    left: image.left,
                                    top: image.top,
                                    width: image.width,
                                    height: image.height
                                }
                            })) || [],
                            
                            heritages: canvasData.heritages?.map(heritage => ({
                                id: heritage.id || 'heritage-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                                name: heritage.name || '遗产信息',
                                position: {
                                    left: heritage.left,
                                    top: heritage.top,
                                    width: heritage.width,
                                    height: heritage.height
                                },
                                publicTime: heritage.publicTime,
                                items: heritage.items || []
                            })) || [],
                            
                            markdowns: canvasData.markdowns?.map(markdown => ({
                                id: markdown.id || 'md-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
                                name: markdown.name || 'Markdown',
                                content: markdown.content,
                                position: {
                                    left: markdown.left,
                                    top: markdown.top,
                                    width: markdown.width,
                                    height: markdown.height
                                }
                            })) || []
                        };
                    } else {
                        alert('加载画布失败：' + response.data.msg);
                    }
                } catch (error) {
                    console.error('加载画布数据失败:', error);
                    alert('加载画布失败，请稍后重试');
                }
            },
            
            // 切换对话输入框显示
            toggleChatInput() {
                this.showChatInput = !this.showChatInput;
                if (this.showChatInput) {
                    // 当对话框显示时，设置焦点到输入框
                    this.$nextTick(() => {
                        if (this.$refs.chatTextarea) {
                            this.$refs.chatTextarea.focus();
                        }
                    });
                }
            },
            
            // 隐藏对话输入框但保留内容
            hideChatInput() {
                this.showChatInput = false;
                // 不清空userMessage，以便下次打开时恢复
            },
            
            // 发送用户消息到后端处理
            async sendMessage() {
                if (!this.userMessage.trim() || this.isProcessing) return;
                
                // 保存用户消息
                const message = this.userMessage;
                this.isProcessing = true;
                
                // 显示"正在处理..."的通知
                this.showNotificationMessage('正在处理您的请求...');
                
                try {
                    // 准备画布摘要信息，包含组件编号
                    const canvasSummary = this.prepareCanvasSummary();
                    
                    // 将用户消息添加到聊天历史
                    this.chatHistory.push({
                        role: 'user',
                        content: message
                    });
                    
                    // 发送请求到后端
                    const response = await request_py({
                        method: 'post',
                        url: '/api/chat',
                        data: {
                            type: 'canvas_control',
                            message: message,
                            history: this.chatHistory,
                            canvas_summary: canvasSummary
                        }
                    });
                    
                    // 添加AI回复到聊天历史
                    this.chatHistory.push({
                        role: 'assistant',
                        content: response.data.answer
                    });
                    
                    // 显示AI回复作为通知
                    this.showNotificationMessage(response.data.answer);
                    
                    // 处理AI返回的操作指令
                    this.executeAction(response.data.action);
                    
                    // 关闭对话输入框并清空内容
                    this.showChatInput = false;
                    this.userMessage = '';
                    
                } catch (error) {
                    console.error('处理消息失败:', error);
                    this.showNotificationMessage('很抱歉，处理您的请求时出现错误。请稍后重试。');
                    
                    // 添加错误信息到聊天历史
                    this.chatHistory.push({
                        role: 'assistant',
                        content: '很抱歉，处理您的请求时出现错误。请稍后重试。'
                    });
                } finally {
                    this.isProcessing = false;
                }
            },
            
            // 准备发送给后端的画布组件摘要
            prepareCanvasSummary() {
                const textsSummary = this.canvasItems.texts.map((item, index) => ({
                    id: item.id,
                    index: index + 1,  // 组件编号从1开始
                    name: item.name,
                    content: item.content,
                    position: item.position
                }));
                
                const imagesSummary = this.canvasItems.images.map((item, index) => ({
                    id: item.id,
                    index: index + 1,
                    name: item.name,
                    imageUrl: item.imageUrl,
                    position: item.position
                }));
                
                const heritagesSummary = this.canvasItems.heritages.map((item, index) => ({
                    id: item.id,
                    index: index + 1,
                    name: item.name,
                    publicTime: item.publicTime,
                    itemCount: (item.items || []).length,
                    position: item.position
                }));
                
                const markdownsSummary = this.canvasItems.markdowns.map((item, index) => ({
                    id: item.id,
                    index: index + 1,
                    name: item.name,
                    content: item.content,
                    position: item.position
                }));
                
                return {
                    texts: textsSummary,
                    images: imagesSummary,
                    heritages: heritagesSummary,
                    markdowns: markdownsSummary
                };
            },
            
            // 执行AI返回的操作指令
            executeAction(action) {
                const { targetType, targetIndex, params } = action;
                // 根据操作类型执行不同的操作
                switch (action.action) {
                    case 'move':
                        // 如果提供了索引，使用索引，否则使用ID
                        if (targetIndex !== undefined) {
                            this.moveComponentByIndex(targetType, targetIndex, params);
                        } 
                        break;
                    case 'edit':
                        if (targetIndex !== undefined) {
                            this.editComponentByIndex(targetType, targetIndex, params);
                        } 
                        break;
                    case 'delete':
                        if (targetIndex !== undefined) {
                            this.deleteComponentByIndex(targetType, targetIndex);
                        } 
                        break;
                    case 'add':
                        this.addComponentByType(targetType, params);
                        break;
                    case 'multi_add':
                        // 处理多组件添加操作 - 始终使用components数组
                        this.addMultipleComponents(action.components || []);
                        break;
                    case 'create_template':
                        // 为了兼容后端可能返回的旧格式，转换为multi_add
                        console.warn('已废弃的操作类型: create_template，请使用multi_add');
                        if (action.components) {
                            this.addMultipleComponents(action.components);
                        } else {
                            console.error('无效的模板指令: 缺少components字段');
                        }
                        break;
                    default:
                        console.warn('未知操作类型:', action.action);
                }
            },
            
            // 添加新的多组件添加方法
            addMultipleComponents(components) {
                if (!components || !Array.isArray(components)) {
                    console.warn('无效的组件列表');
                    return;
                }
                
                // 遍历组件数组，按顺序添加每个组件
                components.forEach(component => {
                    const { type, params } = component;
                    if (type && params) {
                        this.addComponentByType(type, params);
                    }
                });
            },
            
            // 添加新的智能位置计算功能
            calculateOptimalPosition(componentType, componentSize = null) {
                // 默认尺寸参考值
                const defaultSizes = {
                    'text': { width: 300, height: 50 },
                    'markdown': { width: 500, height: 300 },
                    'image': { width: 300, height: 200 },
                    'heritage': { width: 500, height: 300 },
                    'template': { width: 500, height: 450 }, // 用于模板的默认尺寸
                };
                
                // 使用提供的尺寸或默认尺寸
                const size = componentSize || defaultSizes[componentType] || defaultSizes['text'];
                
                // 如果画布为空，使用标准起始位置
                if (this.isCanvasEmpty()) {
                    return { left: 350, top: 100 };
                }
                
                // 获取所有已有组件的位置信息
                const occupiedAreas = this.getOccupiedAreas();
                
                // 尝试找出可用的空间区域
                let availableSpace = this.findAvailableSpace(occupiedAreas, size);
                
                if (availableSpace) {
                    return availableSpace;
                }
                
                // 如果没有合适的空间，则放置在已有内容的下方
                const maxBottom = Math.max(...occupiedAreas.map(area => area.bottom));
                return { left: 350, top: maxBottom + 30 }; // 30px的间距
            },
            
            // 判断画布是否为空
            isCanvasEmpty() {
                return (
                    this.canvasItems.texts.length === 0 &&
                    this.canvasItems.images.length === 0 &&
                    this.canvasItems.heritages.length === 0 &&
                    this.canvasItems.markdowns.length === 0
                );
            },
            
            // 获取所有已占用区域
            getOccupiedAreas() {
                // 收集所有组件的位置信息
                const collectAreas = (items) => {
                    return items.map(item => {
                        const pos = item.position;
                        return {
                            left: pos.left,
                            top: pos.top,
                            right: pos.left + pos.width,
                            bottom: pos.top + pos.height
                        };
                    });
                };
                
                // 合并所有类型组件的区域
                return [
                    ...collectAreas(this.canvasItems.texts),
                    ...collectAreas(this.canvasItems.images),
                    ...collectAreas(this.canvasItems.heritages),
                    ...collectAreas(this.canvasItems.markdowns)
                ];
            },
            
            // 查找可用空间
            findAvailableSpace(occupiedAreas, newSize) {
                if (occupiedAreas.length === 0) {
                    return { left: 350, top: 100 };
                }
                
                // 画布宽度和高度参考值
                const canvasWidth = 1200;
                const canvasHeight = 800;
                
                // 计算已占用区域的边界
                const minLeft = Math.min(...occupiedAreas.map(area => area.left));
                const maxRight = Math.max(...occupiedAreas.map(area => area.right));
                const minTop = Math.min(...occupiedAreas.map(area => area.top));
                const maxBottom = Math.max(...occupiedAreas.map(area => area.bottom));
                
                // 尝试的位置策略
                const positions = [
                    // 右侧空间
                    { left: maxRight + 30, top: minTop },
                    // 底部空间
                    { left: minLeft, top: maxBottom + 30 },
                    // 左侧空间（如果有足够空间）
                    { left: Math.max(50, minLeft - newSize.width - 30), top: minTop },
                    // 顶部空间（如果有足够空间）
                    { left: minLeft, top: Math.max(50, minTop - newSize.height - 30) },
                    // 中间位置（如果现有内容集中在边缘）
                    { left: (minLeft + maxRight) / 2 - newSize.width / 2, top: (minTop + maxBottom) / 2 - newSize.height / 2 },
                    // 右下角
                    { left: maxRight + 30, top: maxBottom + 30 },
                    // 如果都不行，使用固定位置
                    { left: 350, top: maxBottom + 30 }
                ];
                
                // 检查位置是否可用
                for (const pos of positions) {
                    // 确保不超出画布边界
                    if (pos.left < 0 || pos.top < 0 || 
                        pos.left + newSize.width > canvasWidth || 
                        pos.top + newSize.height > canvasHeight) {
                        continue;
                    }
                    
                    // 检查是否与现有组件重叠
                    const newArea = {
                        left: pos.left,
                        top: pos.top,
                        right: pos.left + newSize.width,
                        bottom: pos.top + newSize.height
                    };
                    
                    if (!this.isOverlapping(newArea, occupiedAreas)) {
                        return pos;
                    }
                }
                
                // 如果所有位置都不合适，返回画布下方
                return { left: 350, top: maxBottom + 30 };
            },
            
            // 检查区域是否重叠
            isOverlapping(newArea, occupiedAreas) {
                // 添加一些间距来避免组件挤在一起
                const SPACING = 20;
                const expandedNew = {
                    left: newArea.left - SPACING,
                    top: newArea.top - SPACING,
                    right: newArea.right + SPACING,
                    bottom: newArea.bottom + SPACING
                };
                
                for (const area of occupiedAreas) {
                    if (!(expandedNew.right < area.left || 
                          expandedNew.left > area.right || 
                          expandedNew.bottom < area.top || 
                          expandedNew.top > area.bottom)) {
                        return true; // 有重叠
                    }
                }
                
                return false;
            },
            
            // 根据索引移动组件
            moveComponentByIndex(type, index, params) {
                const { left, top, width, height } = params;
                // 索引从1开始，需要转换为从0开始
                const arrayIndex = index - 1;
                if (arrayIndex >= 0) {
                    const componentList = this.getComponentList(type);
                    if (arrayIndex < componentList.length) {
                        // 获取原有position对象的完整副本
                        const oldPosition = componentList[arrayIndex].position;
                        
                        // 创建全新的position对象，保留所有原始属性
                        const newPosition = {
                            left: left !== undefined ? left : oldPosition.left,
                            top: top !== undefined ? top : oldPosition.top,
                            width: width !== undefined ? width : oldPosition.width,
                            height: height !== undefined ? height : oldPosition.height,
                            zIndex: oldPosition.zIndex || this.currentZIndex
                        };
                        
                        console.log(`移动${type}组件`, arrayIndex, newPosition);
                        
                        // 根据组件类型调用相应的更新方法
                        switch (type) {
                            case 'text':
                                this.updateTextPosition(arrayIndex, newPosition);
                                break;
                            case 'image':
                                this.updateImagePosition(arrayIndex, newPosition);
                                break;
                            case 'heritage':
                                this.updateHeritagePosition(arrayIndex, newPosition);
                                break;
                            case 'markdown':
                                this.updateMarkdownPosition(arrayIndex, newPosition);
                                break;
                        }
                    }
                }
            },
            
            // 根据索引编辑组件内容
            editComponentByIndex(type, index, params) {
                // 索引从1开始，需要转换为从0开始
                const arrayIndex = index - 1;
                
                if (arrayIndex >= 0) {
                    const componentList = this.getComponentList(type);
                    if (arrayIndex < componentList.length) {
                        if (params.name) {
                            switch (type) {
                                case 'text':
                                    this.updateTextName(arrayIndex, params.name);
                                    break;
                                case 'image':
                                    this.updateImageName(arrayIndex, params.name);
                                    break;
                                case 'heritage':
                                    this.updateHeritageName(arrayIndex, params.name);
                                    break;
                                case 'markdown':
                                    this.updateMarkdownName(arrayIndex, params.name);
                                    break;
                            }
                        }
                        
                        if (params.content && (type === 'text' || type === 'markdown')) {
                            if (type === 'text') {
                                this.canvasItems.texts[arrayIndex].content = params.content;
                            } else {
                                this.updateMarkdownContent(arrayIndex, params.content);
                            }
                        }
                        
                        if (params.imageUrl && type === 'image') {
                            this.canvasItems.images[arrayIndex].imageUrl = params.imageUrl;
                        }
                        
                        if (type === 'heritage' && (params.publicTime || params.items)) {
                            const content = {
                                publicTime: params.publicTime || this.canvasItems.heritages[arrayIndex].publicTime,
                                items: params.items || this.canvasItems.heritages[arrayIndex].items
                            };
                            this.updateHeritageContent(arrayIndex, content);
                        }
                    }
                }
            },
            
            // 根据索引删除组件
            deleteComponentByIndex(type, index) {
                // 索引从1开始，需要转换为从0开始
                const arrayIndex = index - 1;
                if (arrayIndex >= 0) {
                    const componentList = this.getComponentList(type);
                    if (arrayIndex < componentList.length) {
                        this.deleteComponent(type, arrayIndex);
                    }
                }
            },
             
         
            
            // 添加新组件
            addComponentByType(type, params) {
                // 根据组件类型和已有组件计算最佳位置
                let position;
                
                // 如果没有提供位置或位置不完整，计算最优位置
                if (!params || !params.position || 
                    (params.position && Object.keys(params.position).length < 4)) {
                    
                    // 根据组件类型确定合适的尺寸
                    const componentSize = {
                        width: params?.position?.width || this.getDefaultSize(type).width,
                        height: params?.position?.height || this.getDefaultSize(type).height
                    };
                    
                    // 计算最佳位置
                    const optimalPos = this.calculateOptimalPosition(type, componentSize);
                    
                    // 构建完整的position对象
                    position = {
                        left: params?.position?.left || optimalPos.left,
                        top: params?.position?.top || optimalPos.top,
                        width: componentSize.width,
                        height: componentSize.height,
                        zIndex: ++this.currentZIndex
                    };
                } else {
                    // 使用提供的位置，但确保有zIndex
                    position = {
                        ...params.position,
                        zIndex: params.position.zIndex || ++this.currentZIndex
                    };
                }
                
                switch (type) {
                    case 'text': {
                        // 创建新的文本对象
                        const newText = {
                            id: 'text-' + Date.now(),
                            name: params?.name || '文本框' + (this.canvasItems.texts.length + 1),
                            content: params?.content || '这是一个文本框',
                            position: position
                        };
                        
                        // 添加到画布
                        this.canvasItems.texts.push(newText);
                        
                        // 返回索引
                        return this.canvasItems.texts.length - 1;
                    }
                    case 'image': {
                        // 创建新的图片对象
                        const newImage = {
                            id: 'img-' + Date.now(),
                            name: params?.name || '图片' + (this.canvasItems.images.length + 1),
                            imageUrl: params?.imageUrl || 'https://via.placeholder.com/300',
                            position: position
                        };
                        
                        // 添加到画布
                        this.canvasItems.images.push(newImage);
                        
                        // 返回索引
                        return this.canvasItems.images.length - 1;
                    }
                    case 'heritage': {
                        // 创建新的遗产对象
                        const newHeritage = {
                            id: 'heritage-' + Date.now(),
                            name: params?.name || '遗产信息' + (this.canvasItems.heritages.length + 1),
                            position: position,
                            publicTime: params?.publicTime || '',
                            items: params?.items || []
                        };
                        
                        // 添加到画布
                        this.canvasItems.heritages.push(newHeritage);
                        
                        // 返回索引
                        return this.canvasItems.heritages.length - 1;
                    }
                    case 'markdown': {
                        // 创建新的Markdown对象
                        const newMarkdown = {
                            id: 'md-' + Date.now(),
                            name: params?.name || 'Markdown' + (this.canvasItems.markdowns.length + 1),
                            content: params?.content || '# 新建Markdown\n请输入内容',
                            position: position
                        };
                        
                        // 添加到画布
                        this.canvasItems.markdowns.push(newMarkdown);
                        
                        // 返回索引
                        return this.canvasItems.markdowns.length - 1;
                    }
                }
                
                return -1; // 如果添加失败
            },
            
            // 获取不同组件类型的默认尺寸
            getDefaultSize(type) {
                switch(type) {
                    case 'text':
                        return { width: 300, height: 50 };
                    case 'image':
                        return { width: 300, height: 200 };
                    case 'heritage':
                        return { width: 500, height: 300 };
                    case 'markdown':
                        return { width: 500, height: 300 };
                    default:
                        return { width: 300, height: 200 };
                }
            },
            
            // 辅助方法：根据类型获取对应的组件列表
            getComponentList(type) {
                switch (type) {
                    case 'text': return this.canvasItems.texts;
                    case 'image': return this.canvasItems.images;
                    case 'heritage': return this.canvasItems.heritages;
                    case 'markdown': return this.canvasItems.markdowns;
                    default: return [];
                }
            },
            
            // 辅助方法：根据ID查找组件索引
            findComponentIndex(type, id) {
                const componentList = this.getComponentList(type);
                return componentList.findIndex(item => item.id === id);
            },
            
            // 打开图片上传选择器
            openImageUploader() {
                this.$refs.uploadFileInput.click();
            },
            
            // 处理文件选择
            handleFileSelect(event) {
                const file = event.target.files[0];
                if (file && file.type.startsWith('image/')) {
                    this.uploadImage(file);
                }
            },
            
            // 上传图片到服务器
            async uploadImage(file) {
                try {
                    const formData = new FormData();
                    formData.append('file', file);
                    
                    this.isUploading = true;
                    this.showNotificationMessage('正在上传图片...');
                    
                    const response = await request({
                        url: '/api/upload/image',
                        method: 'POST',
                        data: formData,
                        headers: {
                            'Content-Type': 'multipart/form-data',
                            'Accept': 'application/json'
                        }
                    });
                    
                    const data = response.data;
                    
                    // 获取图片URL
                    const imageUrl = data.data.path;
                    this.uploadedImageUrl = '101.132.43.211' + imageUrl;
                    
                    // 尝试复制链接到剪贴板
                    await this.copyToClipboard(this.uploadedImageUrl);
                    
                    // 重置文件输入以便下次上传
                    this.$refs.uploadFileInput.value = '';
                    
                } catch (error) {
                    console.error('图片上传错误:', error);
                    this.showNotificationMessage('图片上传失败: ' + error.message);
                } finally {
                    this.isUploading = false;
                }
            },
            
            // 复制内容到剪贴板
            async copyToClipboard(text) {
                try {
                    // 尝试使用现代的Clipboard API
                    if (navigator.clipboard && navigator.clipboard.writeText) {
                        await navigator.clipboard.writeText(text);
                        this.showNotificationMessage('图片链接已复制到剪贴板');
                        return true;
                    }
                    
                    // 回退到传统方法
                    const textarea = document.createElement('textarea');
                    textarea.value = text;
                    textarea.style.position = 'fixed';
                    textarea.style.left = '0';
                    textarea.style.top = '0';
                    textarea.style.opacity = '0';
                    document.body.appendChild(textarea);
                    textarea.focus();
                    textarea.select();
                    
                    const successful = document.execCommand('copy');
                    document.body.removeChild(textarea);
                    
                    if (successful) {
                        this.showNotificationMessage('图片链接已复制到剪贴板');
                        return true;
                    } else {
                        this.showNotificationMessage('无法自动复制，请手动复制链接: ' + text);
                        return false;
                    }
                } catch (err) {
                    console.error('复制到剪贴板失败:', err);
                    this.showNotificationMessage('无法自动复制，请手动复制链接: ' + text);
                    return false;
                }
            },
            
            // 显示通知消息
            showNotificationMessage(message) {
                this.notificationMessage = message;
                this.showNotification = true;
                this.isNotificationFading = false;
                
                // 设置3秒后开始淡出
                setTimeout(() => {
                    this.isNotificationFading = true;
                    
                    // 淡出后完全隐藏
                    setTimeout(() => {
                        this.showNotification = false;
                    }, 1000);
                }, 2000);
            },
            
            // 处理键盘快捷键
            handleKeyDown(e) {
                // 检测Cmd+S (Mac) 或 Ctrl+S (Windows/Linux)
                if ((e.metaKey || e.ctrlKey) && e.key === 's') {
                    // 阻止浏览器默认的保存行为
                    e.preventDefault();
                    
                    // 执行保存逻辑
                    this.quickSave();
                }
            },
            
            // 快速保存函数
            quickSave() {
                // 如果已有标题，直接保存
                if (this.canvasTitle.trim()) {
                    this.confirmSave();
                } else {
                    // 否则显示保存对话框
                    this.showSaveDialog = true;
                }
            },
        },
        mounted() {
            // 检查用户是否登录
            const userId = localStorage.getItem('userId');
            if (!userId || userId === 'undefined') {
                this.$router.push('/login');
                return;
            }

            // 加载画布数据
            this.loadCanvasData();
            
            // 添加全局键盘事件监听
            document.addEventListener('keydown', this.handleKeyDown);
        },
        
        beforeUnmount() {
            // 组件销毁前移除事件监听，避免内存泄漏
            document.removeEventListener('keydown', this.handleKeyDown);
        }
    };
</script>

<style scoped>
/* 整体容器，使用 Flexbox 布局 */
.container {
    display: flex;
    height: 100vh;
    overflow: hidden;
}

/* 左侧工具栏 */
.toolbar {
    width: 250px; /* 工具栏宽度 */
    background-color: #f4f4f4; /* 背景色 */
    padding: 20px;
    box-sizing: border-box;
    border-right: 2px solid #ddd; /* 分界线 */
    display: flex;
    flex-direction: column;
    gap: 15px;
}

/* 工具栏中的每个工具 */
.tool {
    padding: 10px;
    cursor: pointer;
    background-color: #e0e0e0;
    text-align: center;
    border-radius: 5px;
    user-select: none;
}

/* 鼠标悬浮时的样式 */
.tool:hover {
    background-color: #ccc;
}

/* 分界线样式 */
.divider {
    width: 2px;
    background-color: #ddd;
    height: 100%; /* 让分界线占满整个高度 */
}

/* 右侧画布 */
.canvas {
    flex: 1; /* 自动填充剩余空间 */
    background-color: #fafafa;
    padding: 20px;
    box-sizing: border-box;
    overflow: hidden;
}

.save-dialog-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
}

.save-dialog {
    background-color: white;
    padding: 20px;
    border-radius: 8px;
    width: 400px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.form-group {
    margin: 15px 0;
}

.form-group label {
    display: block;
    margin-bottom: 5px;
}

.form-group input[type="text"] {
    width: 100%;
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
}

.form-group input[type="checkbox"] {
    margin-right: 8px;
}

.dialog-buttons {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 20px;
}

.save-btn, .cancel-btn {
    padding: 8px 20px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.save-btn {
    background-color: #4CAF50;
    color: white;
}

.cancel-btn {
    background-color: #f44336;
    color: white;
}

.save-btn:hover {
    background-color: #45a049;
}

.cancel-btn:hover {
    background-color: #da190b;
}

/* 添加组件编号样式 */
.component-number {
    position: absolute;
    background-color: rgba(0, 0, 0, 0.6);
    color: white;
    padding: 2px 6px;
    border-radius: 10px;
    font-size: 12px;
    z-index: 1000;
    pointer-events: none;
}

/* 浮动聊天输入框样式 */
.chat-input-floating {
    position: fixed;
    bottom: 60px;
    left: 50%;
    transform: translateX(-50%);
    width: 50%;
    max-width: 600px;
    z-index: 1001;
    animation: slide-up 0.3s ease;
}

.chat-input-container {
    background-color: white;
    border-radius: 18px;
    padding: 12px 15px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
    display: flex;
    align-items: center;
    border: 1px solid #eaeaea;
}

.chat-input-floating textarea {
    width: 100%;
    border: none;
    padding: 8px 5px;
    resize: none;
    height: 40px;
    font-size: 15px;
    outline: none;
    font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
}

.send-arrow {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 36px;
    height: 36px;
    background-color: #4CAF50;
    border-radius: 50%;
    cursor: pointer;
    margin-left: 10px;
    transition: all 0.2s ease;
    flex-shrink: 0;
}

.send-arrow:hover {
    background-color: #45a049;
    transform: scale(1.05);
}

.arrow-icon {
    color: white;
    font-size: 16px;
    font-style: normal;
}

/* 通知样式增强 */
.notification {
    position: fixed;
    bottom: 60px;
    left: 50%;
    transform: translateX(-50%);
    background-color: rgba(0, 0, 0, 0.8);
    color: white;
    padding: 15px 25px;
    border-radius: 8px;
    z-index: 2000;
    transition: opacity 1s;
    opacity: 1;
    max-width: 80%;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
    font-size: 15px;
}

.notification.fade-out {
    opacity: 0;
}

/* 入场动画 */
@keyframes slide-up {
    from {
        transform: translate(-50%, 20px);
        opacity: 0;
    }
    to {
        transform: translate(-50%, 0);
        opacity: 1;
    }
}

/* 修改聊天工具按钮样式 */
.chat-tool {
    margin-top: 5px;
    background-color: #e3f0ff;
}

/* 添加透明遮罩用于捕获点击事件 */
.chat-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 1000;
    background-color: transparent;
}
</style>
