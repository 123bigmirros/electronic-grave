<template>
    <div id="app">
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
    </div>
</template>

<script>
    import TextTool from './TextTool.vue';
    import ImgTool from './ImgTool.vue';
    import HeritageTool from './HeritageTool.vue';
    import MarkdownTool from './MarkdownTool.vue';
    import request from '../utils/request';
    export default {
        name: 'GravePaint',
        components: {
            TextTool,
            ImgTool,
            HeritageTool,
            MarkdownTool
        },
        data() {
            return {
                canvasItems:{ 
                    texts:[],
                    images: [],
                    heritages: [],
                    markdowns: []
                }// 用于存储添加到画布的元素
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
                const canvasData = {
                    texts: this.canvasItems.texts,
                    images: this.canvasItems.images,
                    heritages: this.canvasItems.heritages,
                    markdowns: this.canvasItems.markdowns
                };

                request.post('/user/canvas/save', canvasData)
                    .then(() => {
                        alert('画布保存成功!');
                    })
                    .catch(error => {
                        console.error('保存画布数据失败:', error);
                        alert('保存失败!');
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
            }
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
</style>
