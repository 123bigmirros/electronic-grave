<template>
    <div class="home-page">
        <!-- 轮播图 -->
        <div class="carousel">
            <div
                    v-for="(item, index) in canvasItems"
                    :key="index"
                    class="carousel-item"
                    :style="{ 
                            transition: 'transform 1s', 
                            transform: `translateX(-${currentIndex * 100}%)` 
                            }"
                    >
                    <div class="canvas-content">
                        <!-- 渲染文本框 -->
                <TextTool
                        v-for="(text, textIndex) in item.texts"
                        :key="'text-' + textIndex"
                        :initialContent="text.content"
                        :initialPosition="text.position"
                        />

                <!-- 渲染图片 -->
                <ImgTool
                        v-for="(image, imageIndex) in item.images"
                        :key="'img-' + imageIndex"
                        :initialImageUrl="image.imageUrl"
                        :initialPosition="image.position"
                        />
                    </div>
            </div>
        </div>

        <!-- 控制按钮 -->
        <div class="controls">
            <button @click="prevSlide">上一页</button>
            <button @click="nextSlide">下一页</button>
        </div>
    </div>
</template>

<script>
    import TextTool from './TextTool';
    import ImgTool from './ImgTool';
    import axios from 'axios';


    export default {
        components: {
            TextTool,
            ImgTool
        },
        data() {
            return {
                canvasItems: [], // 存储画布内容
                currentIndex: 0, // 当前展示的轮播图页面索引
            };
        },
        mounted() {
            // 在这里模拟或者从后端获取数据
            this.fetchCanvasItems();
        },
        methods: {
            // 模拟从后端获取画布数据
            getCanvas() {
                // 发送 GET 请求到后端 API 获取画布数据
                axios.get('http://localhost:8090/user/canvas/load')
                    .then(response => {
                        // 假设返回的数据格式是这样的：
                        // response.data = { texts: [], images: [] }
                        const canvasData = response.data;

                        // 将获取到的画布数据赋值给组件中的 canvasItems
                        this.canvasItems.texts = canvasData.texts || [];
                        this.canvasItems.images = canvasData.images || [];

                        // 你可以在这里进行其他的处理，例如初始化轮播图的页数等
                        alert('画布数据加载成功!');
                    })
                    .catch(error => {
                        console.error('获取画布数据失败:', error);
                        alert('加载画布数据失败!');
                    });
            },
            fetchCanvasItems() {
                this.canvasItems = [
                    {
                        texts: [
                            { content: '第一页文本框', position: { left: 50, top: 50, width: 200, height: 40 } },
                            { content: '更多文本内容', position: { left: 50, top: 120, width: 250, height: 40 } },
                        ],
                        images: [
                            { imageUrl: 'https://via.placeholder.com/150', position: { left: 100, top: 200, width: 150, height: 150 } },
                            { imageUrl: 'https://via.placeholder.com/150', position: { left: 300, top: 200, width: 150, height: 150 } },
                        ],
                    },
                    {
                        texts: [
                            { content: '第二页文本框', position: { left: 50, top: 50, width: 200, height: 40 } },
                        ],
                        images: [
                            { imageUrl: 'https://via.placeholder.com/150', position: { left: 100, top: 200, width: 150, height: 150 } },
                        ],
                    },
                ];
            },
            // 显示上一页
            prevSlide() {
                if (this.currentIndex > 0) {
                    this.currentIndex -= 1;
                } else {
                    this.currentIndex = this.canvasItems.length - 1;
                }
            },
            // 显示下一页
            nextSlide() {
                if (this.currentIndex < this.canvasItems.length - 1) {
                    this.currentIndex += 1;
                } else {
                    this.currentIndex = 0;
                }
            },
        },
    };
</script>

<style scoped>
/* 使整个页面的高度和宽度都为100% */
.home-page {
    height: 100%;
    width: 100%;
}

.carousel {
    display: flex;
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    overflow: hidden;
}

.carousel-item {
    flex-shrink: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
}

.canvas-content {
    position: relative;
    width: 100%;
    height: 100%;
}

.controls {
    position: absolute;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 10;
}

button {
    padding: 10px 20px;
    font-size: 16px;
    margin: 0 10px;
    cursor: pointer;
}
</style>
