<template>
  <div id="app">
    <!-- 这里可以放一些全局布局元素，比如导航栏等 -->
    <router-view></router-view>
  </div>
</template>

<script>
export default {
  name: 'App'
};
</script>

<style>
/* 确保 App 组件占据整个页面 */
#app {
  display: flex;
  flex-direction: column; /* 垂直排列内容 */
  height: 100vh; /* 让 App 占据整个视口高度 */
  margin: 0; /* 清除默认的边距 */
  padding: 0; /* 清除默认的内边距 */
}

/* 使 router-view 内容也充满页面 */
router-view {
  flex-grow: 1; /* 占据剩余空间 */
  width: 100%;  /* 确保宽度为 100% */
}
</style>
