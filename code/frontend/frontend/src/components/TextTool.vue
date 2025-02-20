<template>
    <div
            class="canvas-item text-tool"
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

            <div
                    v-if="isEditing"
                    contenteditable="true"
                    class="text-content"
                    :style="{
                            fontSize: fontSize + 'px',
                            color: textColor,
                            fontFamily: fontFamily,
                            textAlign: textAlign
                            }"
                    @blur="onBlur"
                    @input="onInput"
                    >
                    {{ content }}
            </div>
                <div v-else @click="editText" class="text-display">
                    {{ content || '点击编辑' }}
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
                resizing: false,
                resizeHandle: null,
                initialWidth: 0,
                initialHeight: 0,
                initialLeft: 0,
                initialTop: 0,
            };
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
                    const editableDiv = this.$el.querySelector('[contenteditable]');
                    if (editableDiv) {
                        editableDiv.focus();
                    }
                });
            },
            // 失去焦点时停止编辑
            onBlur() {
                this.isEditing = false;
            },
            // 文本输入时更新内容
            onInput(event) {
                this.content = event.target.innerText;
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
            }
        }
    };
</script>

<style scoped>
.canvas-item.text-tool {
    position: absolute;
    padding: 10px;
    text-align: center;
    background-color: lightblue;
    cursor: move;
    border-radius: 5px;
}

.text-display {
    padding: 5px;
    font-size: 16px;
    color: black;
}

.text-content {
    outline: none;
    padding: 5px;
    font-size: 16px;
    color: black;
    border: 1px solid #ddd;
    min-width: 100px;
    min-height: 30px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.resize-handle {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: white;
    border: 1px solid #666;
    border-radius: 50%;
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
