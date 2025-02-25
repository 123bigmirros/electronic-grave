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
            </div>

            <!-- 分界线 -->
            <div class="divider"></div>

            <!-- 右侧画布 -->
            <div class="canvas">
                <h3>画布</h3>
                <!-- 显示添加的文本框 -->
                <TextTool
                        v-for="(item, index) in canvasItems.texts"
                        :key="'text-' + index"
                        :initialContent="item.content"
                        :initialPosition="item.position"
                        @updatePosition="updateTextPosition(index, $event)"
                        @delete="deleteComponent('text', index)"
                />
                <ImgTool
                        v-for="(item, index) in canvasItems.images"
                        :key="'img-' + index"
                        :initialImageUrl="item.imageUrl"
                        :initialPosition="item.position"
                        @updatePosition="updateImagePosition(index, $event)"
                        @delete="deleteComponent('image', index)"
                />
                <HeritageTool
                    v-for="(item, index) in canvasItems.heritages"
                    :key="'heritage-' + index"
                    :initialPosition="item.position"
                    @updatePosition="updateHeritagePosition(index, $event)"
                    @configureHeritage="configureHeritage(index, $event)"
                    @updateContent="updateHeritageContent(index, $event)"
                    @delete="deleteComponent('heritage', index)"
                />
                <MarkdownTool
                    v-for="(item, index) in canvasItems.markdowns"
                    :key="'md-' + index"
                    :initialContent="item.content"
                    :initialPosition="item.position"
                    :isEditMode="true"
                    @updatePosition="updateMarkdownPosition(index, $event)"
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
                canvasId: null  // 新增：存储画布ID
            };
        },
        methods: {
            // 添加文本框到画布
            addTextTool() {
                const newText = {
                    content: '这是一个文本框',
                    position: {
                        left: 100,
                        top: 100,
                        width: 200,
                        height: 50
                    }
                };
                this.canvasItems.texts.push(newText);
            },
            addImgTool() {
                const newImage = {
                    imageUrl: 'https://via.placeholder.com/150',
                    position: {
                        left: 100,
                        top: 100,
                        width: 150,
                        height: 150
                    }
                };
                this.canvasItems.images.push(newImage);
            },
            addHeritageTool() {
                const newHeritage = {
                    position: {
                        left: 100,
                        top: 100,
                        width: 300,
                        height: 200
                    },
                    publicTime: null,
                    items: []
                };
                this.canvasItems.heritages.push(newHeritage);
            },
            addMarkdownTool() {
                const newMarkdown = {
                    content: '# 新建Markdown\n请输入内容',
                    position: {
                        left: 100,
                        top: 100,
                        width: 400,
                        height: 300
                    }
                };
                this.canvasItems.markdowns.push(newMarkdown);
            },
            updateTextPosition(index, newPosition) {
                this.canvasItems.texts[index].position = newPosition;
            },
            updateImagePosition(index, newPosition) {
                this.canvasItems.images[index].position = newPosition;
            },
            updateHeritagePosition(index, newPosition) {
                this.canvasItems.heritages[index].position = newPosition;
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
                alert(this.isPublic)
                const canvasData = {
                    id: this.canvasId,
                    title: this.canvasTitle,
                    isPublic: this.isPublic?1:0,
                    texts: this.canvasItems.texts,
                    images: this.canvasItems.images,
                    heritages: this.canvasItems.heritages,
                    markdowns: this.canvasItems.markdowns
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
                        url: `/user/canvas/get/${canvasId}`,
                        method: 'get',
                        headers: {
                            "userId": localStorage.getItem('userId')
                        }
                    });

                    if (response.data.code === 1) {
                        const canvasData = response.data.data;
                        // 更新画布标题和公开状态
                        this.canvasTitle = canvasData.title;
                        this.isPublic = canvasData.isPublic;
                        
                        // 确保每个数组都有默认值，防止后端返回null
                        this.canvasItems = {
                            texts: canvasData.texts?.map(text => ({
                                content: text.content,
                                position: {
                                    left: text.left,
                                    top: text.top,
                                    width: text.width,
                                    height: text.height
                                }
                            })) || [],
                            
                            images: canvasData.images?.map(image => ({
                                imageUrl: image.imageUrl,
                                position: {
                                    left: image.left,
                                    top: image.top,
                                    width: image.width,
                                    height: image.height
                                }
                            })) || [],
                            
                            heritages: canvasData.heritages?.map(heritage => ({
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
</style>
