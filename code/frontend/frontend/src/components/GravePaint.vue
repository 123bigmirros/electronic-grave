
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
                        :key="index"
                        :initialContent="item.content"
                        :initialPosition="item.position"
                        />
                <ImgTool
                        v-for="(item, index) in canvasItems.images"
                        :key="'img-' + index"
                        :initialImageUrl="item.imageUrl"
                        :initialPosition="item.position"
                        />
            </div>
        </div>
    </div>
</template>

<script>
    import TextTool from './TextTool.vue';
    import ImgTool from './ImgTool.vue';
    import axios from 'axios';
    export default {
        name: 'GravePaint',
        components: {
            TextTool,
            ImgTool
        },
        data() {
            return {
                canvasItems:{ 
                    texts:[],
                    images:[]
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
            saveCanvas() {
                const canvasData = {
                    texts: this.canvasItems.texts,
                    images: this.canvasItems.images
                };

                // 发送 POST 请求到后端 API
                axios.post('http://localhost:8090/user/canvas/save', canvasData)
                    .then(()=> {
                        alert('画布保存成功!');
                    })
                    .catch(error => {
                        console.error('保存画布数据失败:', error);
                        alert('保存失败!');
                    });
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
