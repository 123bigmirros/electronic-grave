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
                <div class="tool" @click="saveCanvas">
                    <p>保存画布</p>
                </div>
                
                <!-- 添加对话控制按钮 -->
                <div class="tool chat-tool" @click="toggleChatPanel">
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

        <!-- 添加对话控制面板 -->
        <div v-if="showChatPanel" class="chat-panel">
            <div class="chat-header">
                <h3>对话控制</h3>
                <button @click="toggleChatPanel" class="close-btn">×</button>
            </div>
            <div class="chat-messages" ref="chatMessages">
                <div v-for="(msg, index) in chatHistory" :key="index" 
                    :class="['chat-message', msg.role === 'user' ? 'user-message' : 'assistant-message']">
                    {{ msg.content }}
                </div>
            </div>
            <div class="chat-input">
                <textarea v-model="userMessage" @keydown.enter="sendMessage" placeholder="输入指令控制画布组件..."></textarea>
                <button @click="sendMessage">发送</button>
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
                
                // 添加对话控制相关数据
                showChatPanel: false,
                userMessage: '',
                chatHistory: [],
                isProcessing: false
            };
        },
        methods: {
            // 添加文本框到画布
            addTextTool() {
                const newText = {
                    id: 'text-' + Date.now(),  // 添加唯一ID
                    name: '文本框' + (this.canvasItems.texts.length + 1),  // 添加默认名称
                    content: '这是一个文本框',
                    position: {
                        left: 350,
                        top: 100,
                        width: 200,
                        height: 50,
                        zIndex: ++this.currentZIndex
                    }
                };
                this.canvasItems.texts.push(newText);
            },
            addImgTool() {
                const newImage = {
                    id: 'img-' + Date.now(),  // 添加唯一ID
                    name: '图片' + (this.canvasItems.images.length + 1),  // 添加默认名称
                    imageUrl: 'https://via.placeholder.com/150',
                    position: {
                        left: 350,
                        top: 100,
                        width: 150,
                        height: 150,
                        zIndex: ++this.currentZIndex
                    }
                };
                this.canvasItems.images.push(newImage);
            },
            addHeritageTool() {
                const newHeritage = {
                    id: 'heritage-' + Date.now(),  // 添加唯一ID
                    name: '遗产信息' + (this.canvasItems.heritages.length + 1),  // 添加默认名称
                    position: {
                        left: 350,
                        top: 100,
                        width: 300,
                        height: 200,
                        zIndex: ++this.currentZIndex
                    },
                    publicTime: '',
                    items: []
                };
                this.canvasItems.heritages.push(newHeritage);
            },
            addMarkdownTool() {
                const newMarkdown = {
                    id: 'md-' + Date.now(),  // 添加唯一ID
                    name: 'Markdown' + (this.canvasItems.markdowns.length + 1),  // 添加默认名称
                    content: '# 新建Markdown\n请输入内容',
                    position: {
                        left: 350,
                        top: 100,
                        width: 400,
                        height: 300,
                        zIndex: ++this.currentZIndex
                    }
                };
                this.canvasItems.markdowns.push(newMarkdown);
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
                        // 调用embedding API
                        request_py({
                            method: 'post',
                            url: '/api/canvas/embedding',
                            data: {
                                canvas_id: this.canvasId
                            }
                        });
                        this.showSaveDialog = false;  // 关闭保存画布对话框
                    } else {
                        throw new Error('保存失败：' + response.data.msg);
                    }
                })
                .catch(error => {
                    console.error('操作失败:', error);
                    alert('操作失败，请检查网络连接');
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
            
            // 切换对话面板显示
            toggleChatPanel() {
                this.showChatPanel = !this.showChatPanel;
            },
            
            // 发送用户消息到后端处理
            async sendMessage(event) {
                if (event.key === 'Enter' && !event.shiftKey) {
                    event.preventDefault();
                }
                
                if (!this.userMessage.trim() || this.isProcessing) return;
                
                // 将用户消息添加到聊天历史
                this.chatHistory.push({
                    role: 'user',
                    content: this.userMessage
                });
                
                const message = this.userMessage;
                this.userMessage = '';
                this.isProcessing = true;
                
                try {
                    // 准备画布摘要信息，包含组件编号
                    const canvasSummary = this.prepareCanvasSummary();
                    
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
                    
                    // 处理AI返回的操作指令
                    if (response.data.action) {
                        this.executeAction(response.data.action);
                    }
                    
                    // 滚动到最新消息
                    this.$nextTick(() => {
                        const chatContainer = this.$refs.chatMessages;
                        if (chatContainer) {
                            chatContainer.scrollTop = chatContainer.scrollHeight;
                        }
                    });
                } catch (error) {
                    console.error('处理消息失败:', error);
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
                const { targetType, targetId, targetIndex, params } = action;
                
                // 根据操作类型执行不同的操作
                switch (action.action) {
                    case 'move':
                        // 如果提供了索引，使用索引，否则使用ID
                        if (targetIndex !== undefined) {
                            this.moveComponentByIndex(targetType, targetIndex, params);
                        } else if (targetId) {
                            this.moveComponent(targetType, targetId, params);
                        }
                        break;
                    case 'edit':
                        if (targetIndex !== undefined) {
                            this.editComponentByIndex(targetType, targetIndex, params);
                        } else if (targetId) {
                            this.editComponent(targetType, targetId, params);
                        }
                        break;
                    case 'delete':
                        if (targetIndex !== undefined) {
                            this.deleteComponentByIndex(targetType, targetIndex);
                        } else if (targetId) {
                            this.deleteComponentById(targetType, targetId);
                        }
                        break;
                    case 'add':
                        this.addComponentByType(targetType, params);
                        break;
                    default:
                        console.warn('未知操作类型:', action.action);
                }
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
            
            // 移动组件
            moveComponent(type, id, params) {
                const { left, top, width, height } = params;
                const componentList = this.getComponentList(type);
                const index = this.findComponentIndex(type, id);
                
                if (index !== -1) {
                    const newPosition = { ...componentList[index].position };
                    
                    if (left !== undefined) newPosition.left = left;
                    if (top !== undefined) newPosition.top = top;
                    if (width !== undefined) newPosition.width = width;
                    if (height !== undefined) newPosition.height = height;
                    
                    // 根据组件类型调用相应的更新方法
                    switch (type) {
                        case 'text':
                            this.updateTextPosition(index, newPosition);
                            break;
                        case 'image':
                            this.updateImagePosition(index, newPosition);
                            break;
                        case 'heritage':
                            this.updateHeritagePosition(index, newPosition);
                            break;
                        case 'markdown':
                            this.updateMarkdownPosition(index, newPosition);
                            break;
                    }
                }
            },
            
            // 编辑组件内容
            editComponent(type, id, params) {
                const index = this.findComponentIndex(type, id);
                
                if (index !== -1) {
                    if (params.name) {
                        switch (type) {
                            case 'text':
                                this.updateTextName(index, params.name);
                                break;
                            case 'image':
                                this.updateImageName(index, params.name);
                                break;
                            case 'heritage':
                                this.updateHeritageName(index, params.name);
                                break;
                            case 'markdown':
                                this.updateMarkdownName(index, params.name);
                                break;
                        }
                    }
                    
                    if (params.content && (type === 'text' || type === 'markdown')) {
                        if (type === 'text') {
                            this.canvasItems.texts[index].content = params.content;
                        } else {
                            this.updateMarkdownContent(index, params.content);
                        }
                    }
                    
                    if (params.imageUrl && type === 'image') {
                        this.canvasItems.images[index].imageUrl = params.imageUrl;
                    }
                    
                    if (type === 'heritage' && (params.publicTime || params.items)) {
                        const content = {
                            publicTime: params.publicTime || this.canvasItems.heritages[index].publicTime,
                            items: params.items || this.canvasItems.heritages[index].items
                        };
                        this.updateHeritageContent(index, content);
                    }
                }
            },
            
            // 根据ID删除组件
            deleteComponentById(type, id) {
                const index = this.findComponentIndex(type, id);
                if (index !== -1) {
                    this.deleteComponent(type, index);
                }
            },
            
            // 添加新组件
            addComponentByType(type, params) {
                switch (type) {
                    case 'text':
                        this.addTextTool();
                        if (params.content) {
                            const index = this.canvasItems.texts.length - 1;
                            this.canvasItems.texts[index].content = params.content;
                            if (params.position) {
                                this.updateTextPosition(index, params.position);
                            }
                        }
                        break;
                    case 'image':
                        this.addImgTool();
                        if (params.imageUrl) {
                            const index = this.canvasItems.images.length - 1;
                            this.canvasItems.images[index].imageUrl = params.imageUrl;
                            if (params.position) {
                                this.updateImagePosition(index, params.position);
                            }
                        }
                        break;
                    case 'heritage':
                        this.addHeritageTool();
                        {
                            const heritageIndex = this.canvasItems.heritages.length - 1;
                            if (params.position) {
                                this.updateHeritagePosition(heritageIndex, params.position);
                            }
                            if (params.publicTime || params.items) {
                                const content = {
                                    publicTime: params.publicTime || '',
                                    items: params.items || []
                                };
                                this.updateHeritageContent(heritageIndex, content);
                            }
                        }
                        break;
                    case 'markdown':
                        this.addMarkdownTool();
                        if (params.content) {
                            const index = this.canvasItems.markdowns.length - 1;
                            this.updateMarkdownContent(index, params.content);
                            if (params.position) {
                                this.updateMarkdownPosition(index, params.position);
                            }
                        }
                        break;
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
            }
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

/* 添加聊天面板样式 */
.chat-panel {
    position: fixed;
    right: 20px;
    bottom: 20px;
    width: 350px;
    height: 500px;
    background-color: white;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
    display: flex;
    flex-direction: column;
    z-index: 1001;
}

.chat-header {
    padding: 10px 15px;
    border-bottom: 1px solid #eee;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.chat-header h3 {
    margin: 0;
}

.close-btn {
    background: none;
    border: none;
    font-size: 20px;
    cursor: pointer;
    color: #666;
}

.chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 10px;
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.chat-message {
    padding: 8px 12px;
    border-radius: 6px;
    max-width: 80%;
    word-break: break-word;
}

.user-message {
    align-self: flex-end;
    background-color: #4CAF50;
    color: white;
}

.assistant-message {
    align-self: flex-start;
    background-color: #f1f1f1;
    color: #333;
}

.chat-input {
    padding: 10px;
    border-top: 1px solid #eee;
    display: flex;
    gap: 10px;
}

.chat-input textarea {
    flex: 1;
    resize: none;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 8px;
    height: 60px;
}

.chat-input button {
    padding: 0 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.chat-tool {
    margin-top: 20px;
    background-color: #e3f0ff;
}
</style>
