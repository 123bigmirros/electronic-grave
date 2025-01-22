<template>
    <div id="app">
        <div class="container">
            <!-- 左侧工具栏 -->
            <div class="toolbar">
                <h3>工具栏</h3>
                <!-- 这里可以放置工具栏内容 -->
            </div>

            <!-- 分界线 -->
            <div class="divider"></div>

            <!-- 右侧画布 -->
            <div class="canvas">
                <h3>画布</h3>
                <!-- 画布区域可以用于放置组件 -->
            </div>
        </div>
    </div>
</template>

<script>
    export default {
        name: 'App',
    };
</script>

<style scoped>
/* 整体容器，使用 Flexbox 布局 */
.container {
    display: flex;
    height: 100vh; /* 设置容器高度为 100% */
    overflow: hidden; /* 防止超出内容溢出 */
}

/* 左侧工具栏 */
.toolbar {
    width: 250px; /* 工具栏宽度 */
    background-color: #f4f4f4; /* 背景色 */
    padding: 20px;
    box-sizing: border-box;
    border-right: 2px solid #ddd; /* 分界线 */
}

/* 分界线样式 */
.divider {
    width: 2px;
    background-color: #ddd;
}

/* 右侧画布 */
.canvas {
    flex: 1; /* 自动填充剩余空间 */
    background-color: #fafafa;
    padding: 20px;
    box-sizing: border-box;
    overflow: hidden; /* 防止内容溢出 */
}
</style>
