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
            >
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
                textAlign: 'left'  // 对齐方式
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
</style>
