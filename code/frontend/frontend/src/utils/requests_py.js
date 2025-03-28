import axios from 'axios';

const request_py = axios.create({
    baseURL: 'http://localhost:5002',
    timeout: 5000,
    headers: {
        'Content-Type': 'application/json'
    }
});

request_py.interceptors.request.use(
    config => {
         // 从 localStorage 获取用户 ID
         const userId = localStorage.getItem('userId');
         if (userId) {
             config.headers["userId"] = userId;
         }
         return config;
    },
    error => {
        return Promise.reject(error);
    }
);

request_py.interceptors.response.use(
    response => {
        return response;
    },
    error => {
        return Promise.reject(error);
    }
);

export default request_py;