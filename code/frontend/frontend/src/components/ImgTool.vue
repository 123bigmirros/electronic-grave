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
  >
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
      offsetY: 0  // 拖动时的 Y 偏移量
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
</style>
