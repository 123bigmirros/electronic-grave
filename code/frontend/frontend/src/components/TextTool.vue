<template>
    <div
            class="canvas-item text-tool"
            :style="{
                    left: position.left + 'px',
                    top: position.top + 'px',
                    width: position.width + 'px',
                    height: position.height + 'px',
                    zIndex: position.zIndex || 'auto'  // 应用z-index
                    }"
            @mousedown="startDrag"
            @keydown.backspace="deleteComponent"
            tabindex="0"
            >
            <div class="resize-handle top-left" @mousedown.stop="startResize('top-left')"></div>
            <div class="resize-handle top-right" @mousedown.stop="startResize('top-right')"></div>
            <div class="resize-handle bottom-left" @mousedown.stop="startResize('bottom-left')"></div>
            <div class="resize-handle bottom-right" @mousedown.stop="startResize('bottom-right')"></div>

            <div
                    v-if="isEditing"
                    contenteditable="true"
                    class="text-content heading-mode"
                    :style="{
                            fontSize: fontSize + 'px',
                            color: textColor,
                            fontFamily: fontFamily,
                            textAlign: textAlign,
                            fontWeight: isBold ? 'bold' : 'normal'
                            }"
                    @blur="onBlur"
                    @input="onInput"
                    @keydown="handleKeydown"
                    ref="editableContent"
                    >
            </div>
            <div 
                v-else 
                @click="editText" 
                class="text-display"
                v-html="formattedContent">
            </div>
            
            <div v-if="isEditing" class="text-toolbar">
                <button @click="toggleBold" :class="{ 'active': isBold }">B</button>
            </div>
    </div>
</template>

<script>
    export default {
        props: {
            // 传入的初始内容、位置、大小等信息
            initialContent: {
                type: String,
                default: '文本框'
            },
            initialPosition: {
                type: Object,
                default: () => ({
                    left: 100,
                    top: 100,
                    width: 150,
                    height: 50
                })
            }
        },
        data() {
            return {
                content: this.initialContent,  // 文本框内容
                position: { ...this.initialPosition },  // 文本框的位置和尺寸
                isEditing: false, // 是否处于编辑状态
                fontSize: 16,  // 字体大小
                textColor: '#000000',  // 字体颜色
                fontFamily: 'Arial',  // 字体
                textAlign: 'left',  // 对齐方式
                isBold: false,  // 是否粗体
                resizing: false,
                resizeHandle: null,
                initialWidth: 0,
                initialHeight: 0,
                initialLeft: 0,
                initialTop: 0,
            };
        },
        computed: {
            // 格式化内容，将换行符转换为<br>标签，并使用h3标签
            formattedContent() {
                if (!this.content) return '点击编辑';
                
                // 处理换行符
                const processedContent = this.content.replace(/\n/g, '<br>');
                
                // 始终使用h3标签
                return `<h3 style="margin: 0; padding: 0;">${processedContent}</h3>`;
            }
        },
        methods: {
            // 开始拖拽
            startDrag(event) {
                this.dragging = true;
                this.offsetX = event.clientX - this.position.left;
                this.offsetY = event.clientY - this.position.top;
                window.addEventListener('mousemove', this.onDrag);
                window.addEventListener('mouseup', this.stopDrag);
            },
            // 拖拽过程中
            onDrag(event) {
                if (this.dragging) {
                    this.position.left = event.clientX - this.offsetX;
                    this.position.top = event.clientY - this.offsetY;
                    this.$emit('updatePosition', this.position);
                }
            },
            // 停止拖拽
            stopDrag() {
                this.dragging = false;
                window.removeEventListener('mousemove', this.onDrag);
                window.removeEventListener('mouseup', this.stopDrag);
            },

            // 进入编辑状态
            editText() {
                this.isEditing = true;
                this.$nextTick(() => {
                    const editableDiv = this.$refs.editableContent;
                    if (editableDiv) {
                        // 直接设置原始内容
                        editableDiv.innerHTML = this.content.replace(/\n/g, '<br>') || '&nbsp;';
                        editableDiv.focus();
                        
                        // 将光标放到内容末尾
                        this.setCaretToEnd(editableDiv);
                    }
                });
            },
            
            // 设置光标到元素末尾的辅助方法
            setCaretToEnd(element) {
                const range = document.createRange();
                const selection = window.getSelection();
                
                // 处理空元素的情况
                if (element.childNodes.length === 0) {
                    const textNode = document.createTextNode('\u200B'); // 零宽空格
                    element.appendChild(textNode);
                }
                
                range.selectNodeContents(element);
                range.collapse(false); // false表示折叠到末尾
                selection.removeAllRanges();
                selection.addRange(range);
            },
            
            // 失去焦点时停止编辑
            onBlur() {
                // 保存内容
                if (this.$refs.editableContent) {
                    let html = this.$refs.editableContent.innerHTML;
                    this.content = html.replace(/<br\s*\/?>/gi, '\n')
                                     .replace(/&nbsp;/g, ' ')
                                     .replace(/&lt;/g, '<')
                                     .replace(/&gt;/g, '>')
                                     .replace(/&amp;/g, '&')
                                     .replace(/\u200B/g, ''); // 去除零宽空格
                }
                
                this.isEditing = false;
                this.adjustSize(); // 在完成编辑时再次调整大小
            },
            
            // 文本输入时更新内容
            onInput(event) {
                // 将HTML格式（包含<br>）转换为包含\n的纯文本
                let html = event.target.innerHTML;
                this.content = html.replace(/<br\s*\/?>/gi, '\n')
                                 .replace(/&nbsp;/g, ' ')
                                 .replace(/&lt;/g, '<')
                                 .replace(/&gt;/g, '>')
                                 .replace(/&amp;/g, '&')
                                 .replace(/\u200B/g, ''); // 去除零宽空格
                
                // 避免频繁调整大小导致闪烁，使用防抖
                this.debouncedAdjustSize();
            },
            
            // 防抖处理调整大小
            debouncedAdjustSize() {
                if (this.adjustSizeTimeout) {
                    clearTimeout(this.adjustSizeTimeout);
                }
                this.adjustSizeTimeout = setTimeout(() => {
                    this.adjustSize();
                }, 300); // 300ms延迟
            },
            
            // 粗体切换
            toggleBold() {
                this.isBold = !this.isBold;
                if (this.$refs.editableContent) {
                    this.$refs.editableContent.style.fontWeight = this.isBold ? 'bold' : 'normal';
                }
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
                if (!this.isEditing) {  // 只在非编辑状态下允许删除
                    this.$emit('delete');
                }
            },
            // 动态调整大小
            adjustSize() {
                // 创建一个临时元素即使我们没有editableContent引用
                // 设置一个临时元素以测量文本尺寸
                const tempElement = document.createElement('div');
                tempElement.style.position = 'absolute';
                tempElement.style.visibility = 'hidden';
                tempElement.style.width = 'auto';
                tempElement.style.whiteSpace = 'pre-wrap';
                
                // 直接使用格式化后的内容，包括h3标签
                tempElement.innerHTML = this.formattedContent;
                
                tempElement.style.fontSize = this.fontSize + 'px';
                tempElement.style.fontFamily = this.fontFamily;
                if (this.isBold) {
                    tempElement.style.fontWeight = 'bold';
                }
                tempElement.style.padding = '5px';  // 减少测量元素的内边距
                
                document.body.appendChild(tempElement);
                
                // 减少额外边距
                const extraPadding = 10;  // 从20减少到10
                const newWidth = Math.max(150, tempElement.clientWidth + extraPadding);
                const newHeight = Math.max(50, tempElement.clientHeight + extraPadding);
                
                document.body.removeChild(tempElement);
                
                // 更新尺寸
                this.position.width = newWidth;
                this.position.height = newHeight;
                this.$emit('updatePosition', this.position);
            },
            // 处理键盘按下事件
            handleKeydown(event) {
                // 处理回车键
                if (event.key === 'Enter') {
                    event.preventDefault();
                    
                    // 在光标位置插入<br>标签
                    const selection = window.getSelection();
                    const range = selection.getRangeAt(0);
                    const br = document.createElement('br');
                    range.deleteContents();
                    range.insertNode(br);
                    
                    // 创建并插入一个零宽空格，以便将光标定位到<br>后面
                    const textNode = document.createTextNode('\u200B'); // 零宽空格
                    range.setStartAfter(br);
                    range.insertNode(textNode);
                    range.setStartAfter(textNode);
                    range.collapse(true);
                    
                    // 更新选择范围
                    selection.removeAllRanges();
                    selection.addRange(range);
                    
                    // 触发输入事件以更新内容
                    this.onInput({
                        target: this.$refs.editableContent
                    });
                }
            },
        }
    };
</script>

<style scoped>
.canvas-item.text-tool {
    position: absolute;
    padding: 10px;
    text-align: center;
    background-color: transparent;
    cursor: move;
    border-radius: 5px;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.text-display {
    padding: 5px;
    font-size: 16px;
    color: black;
    white-space: pre-wrap;
    text-align: left;
    width: 100%;
}

.text-display h3 {
    margin: 0;
    padding: 0;
}

.text-content {
    outline: none;
    padding: 5px;
    font-size: 16px;
    color: black;
    border: 1px solid #ddd;
    min-width: 100px;
    min-height: 30px;
    white-space: pre-wrap;
    word-wrap: break-word;
    text-align: left;
    width: 100%;
    background-color: transparent;
}

.heading-mode {
    font-size: 1.17em !important;
    font-weight: bold !important;
    margin-block-start: 0 !important;
    margin-block-end: 0 !important;
}

.text-toolbar {
    position: absolute;
    top: -30px;
    left: 0;
    background-color: #f5f5f5;
    border: 1px solid #ddd;
    border-radius: 3px;
    padding: 2px 5px;
    display: flex;
    z-index: 100;
}

.text-toolbar button {
    background: none;
    border: none;
    cursor: pointer;
    font-weight: bold;
    padding: 2px 5px;
    margin: 0 2px;
    border-radius: 2px;
}

.text-toolbar button.active {
    background-color: #e0e0e0;
}

.resize-handle {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: transparent;
    border: 1px solid #4f8cff; /* 添加边框使控制点更明显 */
    border-radius: 50%;
    z-index: 10;
    /* 默认隐藏控制点 */
    opacity: 0;
    transition: opacity 0.2s ease;
}

/* 鼠标悬停时显示控制点 */
.canvas-item.text-tool:hover .resize-handle {
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
</style>
