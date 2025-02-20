<template>
  <div
    class="canvas-item img-tool"
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

    <img
      v-if="!isEditing"
      :src="imageUrl"
      alt="Image"
      class="img-content"
      @click="editImage"
    />
    <input
      v-if="isEditing"
      type="text"
      v-model="imageUrl"
      class="img-input"
      @blur="onBlur"
    />
  </div>
</template>

<script>
export default {
  props: {
    // 传入的初始图片 URL 和位置、大小等信息
    initialImageUrl: {
      type: String,
      default: 'https://via.placeholder.com/150'
    },
    initialPosition: {
      type: Object,
      default: () => ({
        left: 100,
        top: 100,
        width: 150,
        height: 150
      })
    }
  },
  data() {
    return {
      imageUrl: this.initialImageUrl,  // 图片 URL
      position: { ...this.initialPosition },  // 图片框的位置和尺寸
      isEditing: false, // 是否处于编辑状态
      dragging: false,  // 是否正在拖动
      offsetX: 0, // 拖动时的 X 偏移量
      offsetY: 0,  // 拖动时的 Y 偏移量
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

    // 进入编辑图片 URL 状态
    editImage() {
      this.isEditing = true;
      this.$nextTick(() => {
        const inputElement = this.$el.querySelector('input');
        if (inputElement) {
          inputElement.focus();
        }
      });
    },

    // 图片编辑框失去焦点时
    onBlur() {
      this.isEditing = false;
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
.canvas-item.img-tool {
  position: absolute;
  padding: 5px;
  background-color: lightgreen;
  border: 1px solid #ddd;
  cursor: move;
  border-radius: 5px;
}

.img-content {
  width: 100%;
  height: 100%;
  object-fit: contain;
  border-radius: 5px;
  cursor: pointer;
}

.img-input {
  width: 100%;
  padding: 5px;
  font-size: 14px;
  border: 1px solid #ddd;
  border-radius: 5px;
  outline: none;
}

.img-input:focus {
  border-color: #4f8cff;
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
