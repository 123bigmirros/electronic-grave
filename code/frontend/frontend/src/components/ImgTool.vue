<template>
  <div
    class="canvas-item img-tool"
    :style="{
      left: position.left + 'px',
      top: position.top + 'px',
      width: position.width + 'px',
      height: position.height + 'px',
      zIndex: position.zIndex || 'auto'
    }"
    @mousedown="startDrag"
    @keydown.backspace="deleteComponent"
    @dragover.prevent="handleDragOver"
    @drop.prevent="handleDrop"
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
      @click="openImageSelector"
    />
    <input
      v-if="isEditing"
      type="text"
      v-model="imageUrl"
      class="img-input"
      @blur="onBlur"
    />
    <input
      type="file"
      ref="fileInput"
      accept="image/*"
      @change="handleFileSelect"
      style="display: none;"
    />
  </div>
</template>

<script>
import request from '@/utils/request';

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
      isUploading: false,
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

    // 打开图片选择器
    openImageSelector() {
      // 如果点击图片，打开文件选择器
      this.$refs.fileInput.click();
    },
    
    // 处理文件选择
    handleFileSelect(event) {
      const file = event.target.files[0];
      if (file && file.type.startsWith('image/')) {
        this.uploadImage(file);
      }
    },
    
    // 处理拖拽
    handleDragOver(event) {
      event.preventDefault();
      this.$el.classList.add('drag-over');
    },
    
    // 处理文件放置
    handleDrop(event) {
      event.preventDefault();
      this.$el.classList.remove('drag-over');
      const file = event.dataTransfer.files[0];
      if (file && file.type.startsWith('image/')) {
        this.uploadImage(file);
      }
    },
    
    // 上传图片到服务器
    async uploadImage(file) {
      try {
        const formData = new FormData();
        formData.append('file', file);
        
        this.isUploading = true;
        
        const response = await request({
          url: '/api/upload/image',
          method: 'POST',
          data: formData,
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json'
          }
        });
        
        const data = response.data;
        
        
        // 这里直接使用data.data，因为后端返回的是字符串而不是对象
        const imageUrl = data.data.path;
        this.imageUrl = 'http://101.132.43.211:8090' + imageUrl;
       
        
        
        
        this.$emit('updateImage', this.imageUrl);
        
      } catch (error) {
        console.error('图片上传错误:', error);
        alert('图片上传失败: ' + error.message);
      } finally {
        this.isUploading = false;
        this.$refs.fileInput.value = '';
      }
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
  background-color: transparent;
  border: 1px solid #ddd;
  cursor: move;
  border-radius: 5px;
}

.img-content {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 5px;
  cursor: pointer;
  z-index: 1;
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
  width: 14px;
  height: 14px;
  background-color: transparent;
  border: 1px solid #4f8cff;
  border-radius: 50%;
  z-index: 10;
  /* 默认隐藏控制点 */
  opacity: 0;
  transition: opacity 0.2s ease;
}

/* 鼠标悬停时显示控制点 */
.canvas-item.img-tool:hover .resize-handle {
  opacity: 1;
}

.top-left {
  top: -7px;
  left: -7px;
  cursor: nw-resize;
}

.top-right {
  top: -7px;
  right: -7px;
  cursor: ne-resize;
}

.bottom-left {
  bottom: -7px;
  left: -7px;
  cursor: sw-resize;
}

.bottom-right {
  bottom: -7px;
  right: -7px;
  cursor: se-resize;
}

.canvas-item {
  outline: none;
}

.drag-over {
  border: 2px dashed #4f8cff;
  background-color: rgba(79, 140, 255, 0.1);
}
</style>
