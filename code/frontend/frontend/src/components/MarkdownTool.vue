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
        @wheel.stop
        tabindex="0"
    >
        <div class="resize-handle top-left" @mousedown.stop="startResize('top-left')"></div>
        <div class="resize-handle top-right" @mousedown.stop="startResize('top-right')"></div>
        <div class="resize-handle bottom-left" @mousedown.stop="startResize('bottom-left')"></div>
        <div class="resize-handle bottom-right" @mousedown.stop="startResize('bottom-right')"></div>

        <div v-if="isEditMode" class="content-container">
            <div class="editor-header">
                <button @click="togglePreview">{{ isPreview ? '编辑' : '预览' }}</button>
            </div>
            <div v-if="!isPreview" class="editor-content">
                <textarea
                    v-model="content"
                    class="markdown-editor"
                    @input="updateContent"
                    @focus="onTextareaFocus"
                    @blur="onTextareaBlur"
                    @keydown.tab.prevent="handleTabKey"
                ></textarea>
            </div>
            <div v-else class="preview-content" v-html="compiledMarkdown"></div>
        </div>
        <div v-else class="preview-content" v-html="compiledMarkdown"></div>
    </div>
</template>

<script>
import { marked } from 'marked';
import katex from 'katex';
import 'katex/dist/katex.min.css';

// 配置marked以支持LaTeX，并立即执行
const katexExtension = {
    name: 'katex',
    level: 'inline',
    start(src) { return src.indexOf('$'); },
    tokenizer(src) {
        const match = src.match(/^\$(.*?)\$/);
        if (match) {
            return {
                type: 'katex',
                raw: match[0],
                text: match[1].trim()
            };
        }
        return false;
    },
    renderer(token) {
        try {
            return katex.renderToString(token.text, {
                throwOnError: false,
                displayMode: false
            });
        } catch (e) {
            return `<span style="color:red">${e.message}</span>`;
        }
    }
};

const katexBlockExtension = {
    name: 'katexBlock',
    level: 'block',
    start(src) { return src.indexOf('$$'); },
    tokenizer(src) {
        const match = src.match(/^\$\$([\s\S]*?)\$\$/);
        if (match) {
            return {
                type: 'katexBlock',
                raw: match[0],
                text: match[1].trim()
            };
        }
        return false;
    },
    renderer(token) {
        try {
            return katex.renderToString(token.text, {
                throwOnError: false,
                displayMode: true
            });
        } catch (e) {
            return `<div style="color:red">${e.message}</div>`;
        }
    }
};

// 立即执行初始化
marked.use({ extensions: [katexExtension, katexBlockExtension] });

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
            isTextareaFocused: false
        };
    },
    computed: {
        compiledMarkdown() {
            // 确保marked已配置
            if (!this.content) return '';
            
            try {
                return marked(this.content);
            } catch (e) {
                console.error('Markdown渲染错误:', e);
                return `<div style="color:red">渲染错误: ${e.message}</div>`;
            }
        }
    },
    created() {
        // 在创建时再次确保初始化已完成
        if (!marked.defaults.extensions) {
            marked.use({ extensions: [katexExtension, katexBlockExtension] });
        }
    },
    mounted() {
        // 不再需要在这里初始化，因为我们已经在导入时完成了初始化
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
            if (!this.isEditMode || !this.isTextareaFocused) {
                this.$emit('delete');
            }
        },
        onTextareaFocus() {
            this.isTextareaFocused = true;
        },
        onTextareaBlur() {
            this.isTextareaFocused = false;
        },
        handleTabKey(event) {
            // 阻止默认Tab行为
            const textarea = event.target;
            const start = textarea.selectionStart;
            const end = textarea.selectionEnd;
            
            // 在光标位置插入缩进（4个空格）
            this.content = this.content.substring(0, start) + '    ' + this.content.substring(end);
            
            // 移动光标到缩进后的位置
            this.$nextTick(() => {
                textarea.selectionStart = textarea.selectionEnd = start + 4;
            });
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
    display: flex;
    flex-direction: column;
}

.content-container {
    display: flex;
    flex-direction: column;
    height: 100%;
    width: 100%;
}

.editor-header {
    padding: 8px;
    border-bottom: 1px solid #ddd;
    background-color: #f5f5f5;
    flex-shrink: 0;
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
    flex: 1;
    display: flex;
    overflow: hidden;
    min-height: 0;
}

.markdown-editor {
    width: 100%;
    height: 100%;
    padding: 10px;
    border: none;
    resize: none;
    outline: none;
    font-family: monospace;
    box-sizing: border-box;
    flex: 1;
}

.preview-content {
    padding: 15px;
    height: 100%;
    overflow-y: auto;
    box-sizing: border-box;
    flex: 1;
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

.preview-content:hover {
    z-index: 100;
}

.resize-handle {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: white;
    border: 1px solid #4f8cff;
    border-radius: 50%;
    z-index: 100;
    /* 默认隐藏控制点 */
    opacity: 0;
    transition: opacity 0.2s ease;
}

/* 鼠标悬停时显示控制点 */
.canvas-item.markdown-tool:hover .resize-handle {
    opacity: 1;
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

/* 添加KaTeX样式支持 */
:deep(.preview-content .katex) {
    font-size: 1.1em;
}
</style> 