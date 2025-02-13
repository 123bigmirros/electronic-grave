import axios from 'axios';

// 创建 axios 实例
const request = axios.create({
    baseURL: 'http://localhost:8090',
    timeout: 5000
});

// 请求拦截器
request.interceptors.request.use(
    config => {
        // 从 localStorage 获取用户 ID
        const userId = localStorage.getItem('userId');
        if (userId) {
            config.headers['userId'] = userId;
        }
        return config;
    },
    error => {
        return Promise.reject(error);
    }
);

export default request; 