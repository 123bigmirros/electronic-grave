<template>
  <div class="login-container">
    <div class="form-box">
      <div class="toggle-buttons">
        <button 
          :class="{ active: isLogin }" 
          @click="isLogin = true"
        >登录</button>
        <button 
          :class="{ active: !isLogin }" 
          @click="isLogin = false"
        >注册</button>
      </div>

      <form @submit.prevent="handleSubmit">
        <div class="form-group">
          <input
            type="text"
            v-model="formData.username"
            placeholder="用户名"
            required
          />
        </div>
        
        <div class="form-group">
          <input
            type="password"
            v-model="formData.password"
            placeholder="密码"
            required
          />
        </div>

        <div class="form-group" v-if="!isLogin">
          <input
            type="password"
            v-model="formData.confirmPassword"
            placeholder="确认密码"
            required
          />
        </div>

        <button type="submit" class="submit-btn">
          {{ isLogin ? '登录' : '注册' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'LoginRegister',
  data() {
    return {
      isLogin: true,
      formData: {
        username: '',
        password: '',
        confirmPassword: ''
      }
    }
  },
  methods: {
    async handleSubmit() {
      try {
        if (!this.isLogin && this.formData.password !== this.formData.confirmPassword) {
          alert('两次输入的密码不一致')
          return
        }

        const url = this.isLogin 
          ? 'http://localhost:8090/user/info/login' 
          : 'http://localhost:8090/user/info/register'

        const response = await axios.post(url, {
          username: this.formData.username,
          password: this.formData.password
        })

        if (response.data.code === 1) {  // 假设后端成功状态码为1
          // 从response.data.data中获取用户信息
          const userData = response.data.data;
          if (userData.id !== -1) {
            // 存储用户ID
            localStorage.setItem('userId', userData.id);
            this.$router.push('/')
          } else {
            this.$router.push('/login')
          }
        } else {
          alert(response.data.msg || '登录失败')
        }
      } catch (error) {
        alert(error.response?.data?.message || '操作失败，请稍后重试')
      }
    }
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #f5f5f5;
}

.form-box {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 0 10px rgba(0,0,0,0.1);
  width: 100%;
  max-width: 400px;
}

.toggle-buttons {
  display: flex;
  margin-bottom: 20px;
}

.toggle-buttons button {
  flex: 1;
  padding: 10px;
  border: none;
  background: none;
  cursor: pointer;
}

.toggle-buttons button.active {
  border-bottom: 2px solid #4CAF50;
  color: #4CAF50;
}

.form-group {
  margin-bottom: 15px;
}

input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
}

.submit-btn {
  width: 100%;
  padding: 12px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
}

.submit-btn:hover {
  background-color: #45a049;
}
</style> 