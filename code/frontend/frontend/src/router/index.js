// src/router/index.js

import { createRouter, createWebHistory } from 'vue-router';  // Vue 3 中的方式导入
import GravePaint from '../components/GravePaint.vue';  // 导入你的 GravePaint 组件
import HomePage from '../components/HomePage.vue'
import LoginRegister from '../components/LoginRegister.vue'
const routes = [
    { path: '/GravePaint', component: GravePaint },  // 设置路由
    { path: '/',component:HomePage},
    { path: '/Login',component:LoginRegister}
];

const router = createRouter({
    history: createWebHistory(),  // 使用 HTML5 History 模式
    routes,  // 路由配置
});

export default router;
