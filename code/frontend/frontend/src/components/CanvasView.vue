<template>
    <div class="canvas-view">
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

export default {
    name: 'CanvasView',
    components: {
        TextTool,
        ImgTool,
        HeritageTool,
        MarkdownTool,
        CustomerService
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

                if (response.data.code === 1) {
                    const canvasData = response.data.data;
                    this.canvasTitle = canvasData.title;
                    this.canvasItems = {
                        texts: canvasData.texts || [],
                        images: canvasData.images || [],
                        heritages: canvasData.heritages || [],
                        markdowns: canvasData.markdowns || []
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