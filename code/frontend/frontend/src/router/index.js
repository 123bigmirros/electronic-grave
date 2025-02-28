// src/router/index.js

import { createRouter, createWebHistory } from 'vue-router';  // Vue 3 中的方式导入
import GravePaint from '../components/GravePaint.vue';  // 导入你的 GravePaint 组件
import HomePage from '../components/HomePage.vue'
import LoginRegister from '../components/LoginRegister.vue'
import PersonalPage from '../components/PersonalPage.vue'
import TinyStar from '../components/TinyStar.vue'  // 导入新的星星组件
import CustomerService from '../components/CustomerService.vue'  // 添加导入

const routes = [
    { path: '/gravepaint', component: GravePaint },  // 新建画布路由
    { path: '/gravepaint/:id', component: GravePaint },  // 添加编辑画布路由，带ID参数
    { path: '/',component:HomePage},
    { path: '/Login',component:LoginRegister},
    { path: '/personal', component: PersonalPage },  // 添加个人主页路由
    { path: '/tinyStar', component: TinyStar },  // 添加星星页面的路由
    { path: '/customer-service', component: CustomerService },  // 添加客服路由
    {
        path: '/canvas/view/:id',
        name: 'CanvasView',
        component: () => import('../components/CanvasView.vue')
    }
];

const router = createRouter({
    history: createWebHistory(),  // 使用 HTML5 History 模式
    routes,  // 路由配置
});

export default router;
