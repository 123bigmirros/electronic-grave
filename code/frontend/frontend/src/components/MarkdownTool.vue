<template>
    <div
        class="canvas-item markdown-tool"
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
        <div class="resize-handle top-left" @mousedown.stop="startResize('top-left')"></div>
        <div class="resize-handle top-right" @mousedown.stop="startResize('top-right')"></div>
        <div class="resize-handle bottom-left" @mousedown.stop="startResize('bottom-left')"></div>
        <div class="resize-handle bottom-right" @mousedown.stop="startResize('bottom-right')"></div>

        <div v-if="isEditMode">
            <div class="editor-header">
                <button @click="togglePreview">{{ isPreview ? '编辑' : '预览' }}</button>
            </div>
            <div v-if="!isPreview" class="editor-content">
                <textarea
                    v-model="content"
                    class="markdown-editor"
                    @input="updateContent"
                ></textarea>
            </div>
            <div v-else class="preview-content" v-html="compiledMarkdown"></div>
        </div>
        <div v-else class="preview-content" v-html="compiledMarkdown"></div>
    </div>
</template>

<script>
import { marked } from 'marked';

export default {
    name: 'MarkdownTool',
    props: {
        initialContent: {
            type: String,
            default: '# 标题\n请输入Markdown内容'
        },
        initialPosition: {
            type: Object,
            default: () => ({
                left: 100,
                top: 100,
                width: 400,
                height: 300
            })
        },
        isEditMode: {
            type: Boolean,
            default: true
        }
    },
    data() {
        return {
            content: this.initialContent,
            position: { ...this.initialPosition },
            isPreview: false,
            dragging: false,
            offsetX: 0,
            offsetY: 0,
            resizing: false,
            resizeHandle: null,
            initialWidth: 0,
            initialHeight: 0,
            initialLeft: 0,
            initialTop: 0,
        };
    },
    computed: {
        compiledMarkdown() {
            return marked(this.content);
        }
    },
    methods: {
        startDrag(event) {
            if (!this.isEditMode) return;
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
        togglePreview() {
            this.isPreview = !this.isPreview;
        },
        updateContent() {
            this.$emit('updateContent', this.content);
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
            if (!this.isEditMode || this.isPreview) {
                this.$emit('delete');
            }
        }
    }
};
</script>

<style scoped>
.markdown-tool {
    position: absolute;
    background-color: white;
    border: 1px solid #ddd;
    border-radius: 4px;
    overflow: hidden;
}

.editor-header {
    padding: 8px;
    border-bottom: 1px solid #ddd;
    background-color: #f5f5f5;
}

.editor-header button {
    padding: 4px 8px;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}

.editor-content {
    height: calc(100% - 40px);
}

.markdown-editor {
    width: 100%;
    height: 100%;
    padding: 10px;
    border: none;
    resize: none;
    outline: none;
    font-family: monospace;
}

.preview-content {
    padding: 15px;
    height: 100%;
    overflow-y: auto;
}

:deep(.preview-content) {
    h1, h2, h3 {
        margin-top: 1em;
        margin-bottom: 0.5em;
    }
    
    p {
        margin: 0.5em 0;
    }
    
    code {
        background-color: #f5f5f5;
        padding: 2px 4px;
        border-radius: 3px;
    }
    
    pre {
        background-color: #f5f5f5;
        padding: 10px;
        border-radius: 4px;
        overflow-x: auto;
    }
}

.resize-handle {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: white;
    border: 1px solid #666;
    border-radius: 50%;
    z-index: 100;
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
</style> 