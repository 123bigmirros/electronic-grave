<template>
    <div class="canvas-view">
        <SearchBox />
        <!-- 复用 GravePaint 的大部分模板，但移除工具栏和编辑功能 -->
        <div class="canvas">
            <h3>{{ canvasTitle }}</h3>
            <div class="canvas-actions" v-if="isOwner">
                <button @click="editCanvas" class="edit-button">修改画布</button>
            </div>
            <TextTool
                v-for="(item, index) in canvasItems.texts"
                :key="'text-' + index"
                :initialContent="item.content"
                :initialPosition="item.position"
                :readonly="true"
            />
            <ImgTool
                v-for="(item, index) in canvasItems.images"
                :key="'img-' + index"
                :initialImageUrl="item.imageUrl"
                :initialPosition="item.position"
                :readonly="true"
            />
            <HeritageTool
                v-for="(item, index) in canvasItems.heritages"
                :key="'heritage-' + index"
                :initialPosition="item.position"
                :readonly="true"
                :content="item"
            />
            <MarkdownTool
                v-for="(item, index) in canvasItems.markdowns"
                :key="'md-' + index"
                :initialContent="item.content"
                :initialPosition="item.position"
                :readonly="true"
            />
        </div>
        
        <!-- 添加客服组件 -->
        <CustomerService 
            :canvas-id="$route.params.id"
            :canvas-data="{
                texts: canvasItems.texts,
                images: canvasItems.images,
                heritages: canvasItems.heritages,
                markdowns: canvasItems.markdowns,
                title: canvasTitle
            }"
        />
    </div>
</template>

<script>
import TextTool from './TextTool.vue';
import ImgTool from './ImgTool.vue';
import HeritageTool from './HeritageTool.vue';
import MarkdownTool from './MarkdownTool.vue';
import CustomerService from './CustomerService.vue';
import request from '../utils/request';
import SearchBox from './SearchBox.vue'
export default {
    name: 'CanvasView',
    components: {
        TextTool,
        ImgTool,
        HeritageTool,
        MarkdownTool,
        CustomerService,
        SearchBox
    },
    data() {
        return {
            canvasTitle: '',
            canvasItems: {
                texts: [],
                images: [],
                heritages: [],
                markdowns: []
            },
            canvasUserId: null,
            isOwner: false
        };
    },
    async mounted() {
        await this.loadCanvasData();
    },
    methods: {
        async loadCanvasData() {
            const canvasId = this.$route.params.id;
            try {
                const response = await request({
                    url: `/user/canvas/get/${canvasId}/0`,
                    method: 'get'
                });
                // alert(JSON.stringify(response.data))
                if (response.data.code === 1) {
                    const canvasData = response.data.data;
                    // alert(JSON.stringify(canvasData))
                    this.canvasTitle = canvasData.title;
                    
                    // 处理文本组件
                    const processedTexts = (canvasData.texts || []).map(text => ({
                        content: text.content,
                        name: text.name,
                        position: {
                            left: text.position?.left || text.left || 0,
                            top: text.position?.top || text.top || 0,
                            width: text.position?.width || text.width || 200,
                            height: text.position?.height || text.height || 50,
                            zIndex: text.position?.zIndex || 1
                        }
                    }));
                    
                    // 处理图片组件
                    const processedImages = (canvasData.images || []).map(image => ({
                        imageUrl: image.imageUrl,
                        name: image.name,
                        position: {
                            left: image.position?.left || image.left || 0,
                            top: image.position?.top || image.top || 0,
                            width: image.position?.width || image.width || 150,
                            height: image.position?.height || image.height || 150,
                            zIndex: image.position?.zIndex || 1
                        }
                    }));
                    
                    // 处理遗产组件
                    const processedHeritages = (canvasData.heritages || []).map(heritage => ({
                        publicTime: heritage.publicTime,
                        items: heritage.items || [],
                        name: heritage.name,
                        position: {
                            left: heritage.position?.left || heritage.left || 0,
                            top: heritage.position?.top || heritage.top || 0,
                            width: heritage.position?.width || heritage.width || 300,
                            height: heritage.position?.height || heritage.height || 200,
                            zIndex: heritage.position?.zIndex || 1
                        }
                    }));
                    
                    // 处理Markdown组件
                    const processedMarkdowns = (canvasData.markdowns || []).map(markdown => ({
                        content: markdown.content,
                        name: markdown.name,
                        position: {
                            left: markdown.position?.left || markdown.left || 0,
                            top: markdown.position?.top || markdown.top || 0,
                            width: markdown.position?.width || markdown.width || 400,
                            height: markdown.position?.height || markdown.height || 300,
                            zIndex: markdown.position?.zIndex || 1
                        }
                    }));
                    
                    this.canvasItems = {
                        texts: processedTexts,
                        images: processedImages,
                        heritages: processedHeritages,
                        markdowns: processedMarkdowns
                    };
                    
                    // 保存画布创建者ID并检查当前用户是否为创建者
                    this.canvasUserId = canvasData.userId;
                    const currentUserId = localStorage.getItem('userId');
                    this.isOwner = currentUserId && this.canvasUserId && 
                                  currentUserId.toString() === this.canvasUserId.toString();
                }
            } catch (error) {
                console.error('加载画布数据失败:', error);
            }
        },
        
        editCanvas() {
            // 跳转到编辑页面
            const canvasId = this.$route.params.id;
            this.$router.push(`/gravepaint/${canvasId}`);
        }
    }
};
</script>

<style scoped>
.canvas-view {
    padding: 20px;
    height: 100vh;
    overflow: auto;
}

.canvas {
    background-color: #fafafa;
    padding: 20px;
    border-radius: 8px;
    min-height: 600px;
    position: relative;
}

.canvas-actions {
    position: absolute;
    top: 20px;
    right: 20px;
}

.edit-button {
    padding: 8px 15px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.edit-button:hover {
    background-color: #45a049;
}
</style> 