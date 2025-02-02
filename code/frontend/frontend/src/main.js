import { createApp } from 'vue';  // Vue 3 的方式
import App from './App.vue';
import router from './router';  // 导入 router 配置

createApp(App).use(router).mount('#app');  // 使用 router 并挂载应用
