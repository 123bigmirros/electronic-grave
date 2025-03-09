const { defineConfig } = require('@vue/cli-service')
module.exports = defineConfig({
  transpileDependencies: true,
  devServer: {
    proxy: {
      '/api': {
        target: 'http://101.132.43.211:8090',
        changeOrigin: true,
      }
    }
  },
  devServer: {
    port: 80,
  },
})


