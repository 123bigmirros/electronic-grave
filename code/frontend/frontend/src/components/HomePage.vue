<template>
    <div class="home-page" 
         @mouseenter="stopAutoPlay" 
         @mouseleave="startAutoPlay"
         @wheel="handleWheel"
         @keydown="handleKeydown"
         @click="checkUserAuth"
         tabindex="0">
        <!-- 添加顶部导航栏 -->
        <div class="top-nav">
            <SearchBox />
            <div class="nav-buttons">
                <button @click="goToPersonal">个人主页</button>
                <button @click="goToCreate">创作</button>
            </div>
        </div>

        <!-- 轮播图 -->
        <div class="carousel">
            <div
                v-for="(item, index) in canvasItems"
                :key="index"
                class="carousel-item"
                :style="{ 
                    transition: `transform ${transitionDuration}s`, 
                    transform: `translateY(-${currentIndex * 100}%)` 
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

                    <!-- 渲染遗产组件 -->
                    <HeritageTool
                        v-for="(heritage, heritageIndex) in item.heritages"
                        :key="'heritage-' + heritageIndex"
                        :initialPosition="heritage.position"
                    />

                    <!-- 添加 MarkdownTool -->
                    <MarkdownTool
                        v-for="(markdown, markdownIndex) in item.markdowns"
                        :key="'md-' + markdownIndex"
                        :initialContent="markdown.content"
                        :initialPosition="markdown.position"
                        :isEditMode="false"
                    />
                </div>
            </div>
        </div>
    </div>
</template>

<script>
    import TextTool from './TextTool';
    import ImgTool from './ImgTool';
    import HeritageTool from './HeritageTool';
    import MarkdownTool from './MarkdownTool';
    import axios from 'axios';
    import SearchBox from './SearchBox.vue';


    export default {
        components: {
            TextTool,
            ImgTool,
            HeritageTool,
            MarkdownTool,
            SearchBox
        },
        data() {
            return {
                canvasItems: [], // 存储画布内容
                currentIndex: 0, // 当前展示的轮播图页面索引
                autoPlayTimer: null, // 添加定时器变量
                isScrolling: false, // 是否正在滚动
                transitionDuration: 0.6, // 过渡动画持续时间（秒）
                scrollThreshold: 50 // 滚动阈值
            };
        },
        mounted() {
            this.getCanvas();
            this.startAutoPlay(); // 组件挂载时启动自动播放
            this.$el.focus();
        },
        beforeUnmount() {
            this.stopAutoPlay(); // 组件销毁前清除定时器
        },
        methods: {
            // 模拟从后端获取画布数据
            getCanvas() {
                axios.get('http://localhost:8090/user/canvas/load')
                    .then(response => {
                        const canvasData = response.data.data;
                        if (canvasData) {
                            // 处理每种类型的组件
                            this.canvasItems = canvasData.map(item => ({
                                texts: item.texts?.map(this.convertToPosition) || [],
                                images: item.images?.map(this.convertToPosition) || [],
                                heritages: item.heritages?.map(this.convertToPosition) || [],
                                markdowns: item.markdowns?.map(this.convertToPosition) || []
                            }));
                        }
                    })
                    .catch(error => {
                        console.error('获取画布数据失败:', error);
                        alert('加载画布数据失败!');
                    });
            },

            // 将组件的位置属性转换为position对象
            convertToPosition(item) {
                const { left, top, width, height, ...rest } = item;
                return {
                    ...rest,
                    position: {
                        left: left || 100,
                        top: top || 100,
                        width: width || 150,
                        height: height || 150
                    }
                };
            },

            // 开始自动播放
            startAutoPlay() {
                if (!this.autoPlayTimer) {
                    this.autoPlayTimer = setInterval(() => {
                        // 直接在这里处理下一张切换的逻辑，而不是调用 nextSlide
                        if (this.currentIndex < this.canvasItems.length - 1) {
                            this.currentIndex += 1;
                        } else {
                            this.currentIndex = 0;
                        }
                    }, 5000); // 每5秒切换一次
                }
            },

            // 停止自动播放
            stopAutoPlay() {
                if (this.autoPlayTimer) {
                    clearInterval(this.autoPlayTimer);
                    this.autoPlayTimer = null;
                }
            },

            handleWheel(event) {
                event.preventDefault(); // 阻止默认滚动行为
                
                if (this.isScrolling) return; // 如果正在滚动，则忽略新的滚动事件

                const deltaY = event.deltaY;
                
                if (Math.abs(deltaY) < this.scrollThreshold) return; // 滚动距离太小则忽略

                this.isScrolling = true;
                
                if (deltaY > 0) {
                    // 向下滚动
                    if (this.currentIndex < this.canvasItems.length - 1) {
                        this.currentIndex += 1;
                    } else {
                        this.currentIndex = 0;
                    }
                } else {
                    // 向上滚动
                    if (this.currentIndex > 0) {
                        this.currentIndex -= 1;
                    } else {
                        this.currentIndex = this.canvasItems.length - 1;
                    }
                }

                // 动画结束后重置滚动状态
                setTimeout(() => {
                    this.isScrolling = false;
                }, this.transitionDuration * 1000);
            },

            // 添加键盘控制方法
            handleKeydown(event) {
                if (this.isScrolling) return;

                if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
                    event.preventDefault();
                    this.isScrolling = true;
                    
                    if (event.key === 'ArrowDown') {
                        if (this.currentIndex < this.canvasItems.length - 1) {
                            this.currentIndex += 1;
                        } else {
                            this.currentIndex = 0;
                        }
                    } else {
                        if (this.currentIndex > 0) {
                            this.currentIndex -= 1;
                        } else {
                            this.currentIndex = this.canvasItems.length - 1;
                        }
                    }

                    setTimeout(() => {
                        this.isScrolling = false;
                    }, this.transitionDuration * 1000);
                }
            },

            // 添加用户验证检查方法
            checkUserAuth() {
                const userId = localStorage.getItem('userId');
                if (!userId) {
                    this.$router.push('/login');
                }
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
                console.log('尝试跳转到 gravepaint 页面');
                this.$router.push('/gravepaint');
            }
        },
    };
</script>

<style scoped>
/* 使整个页面的高度和宽度都为100% */
.home-page {
    height: 100%;
    width: 100%;
    overflow: hidden; /* 防止页面出现滚动条 */
    outline: none; /* 添加这行去除焦点时的轮廓 */
}

.carousel {
    display: flex;
    flex-direction: column; /* 改为纵向排列 */
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

.top-nav {
    position: fixed;
    top: 0;
    right: 0;
    padding: 20px;
    display: flex;
    align-items: center;
    gap: 20px;
    z-index: 1000;
}

.nav-buttons {
    display: flex;
    gap: 10px;
}

.nav-buttons button {
    padding: 8px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.nav-buttons button:hover {
    background-color: #45a049;
}
</style>
