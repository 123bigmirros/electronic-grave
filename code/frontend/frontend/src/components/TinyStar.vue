<template>
  <div class="star-container">
    <canvas ref="starCanvas" :width="canvasWidth" :height="canvasHeight"></canvas>
  </div>
</template>

<script>
export default {
  name: 'TinyStar',
  data() {
    return {
      canvasWidth: window.innerWidth,
      canvasHeight: window.innerHeight,
      stars: [],
      meteors: [],
      animationId: null
    }
  },
  mounted() {
    this.initStars()
    this.animate()
    window.addEventListener('resize', this.handleResize)
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.handleResize)
    cancelAnimationFrame(this.animationId)
  },
  methods: {
    handleResize() {
      this.canvasWidth = window.innerWidth
      this.canvasHeight = window.innerHeight
      this.initStars()
    },
    initStars() {
      // 创建300颗星星，增加数量使星空更加密集
      this.stars = Array(300).fill().map(() => ({
        x: Math.random() * this.canvasWidth,
        y: Math.random() * this.canvasHeight,
        size: Math.random() * 3 + 0.5, // 更多样的星星大小
        opacity: Math.random(),
        speed: Math.random() * 0.05 + 0.02,
        color: Math.random() > 0.5 ? // 添加一些彩色星星
          `rgba(255, 255, 255, ` :
          `rgba(${Math.random() * 50 + 200}, ${Math.random() * 150 + 100}, ${Math.random() * 50 + 200}, `
      }))
    },
    createMeteor() {
      // 增加流星出现频率和多样性
      if (Math.random() < 0.05) {
        const meteor = {
          x: Math.random() * this.canvasWidth,
          y: 0,
          length: Math.random() * 150 + 100, // 更长的流星尾巴
          speed: Math.random() * 20 + 15, // 更快的速度
          angle: Math.PI / 4,
          color: Math.random() > 0.7 ? // 添加一些彩色流星
            'rgba(255, 255, 255, ' :
            `rgba(${Math.random() * 50 + 200}, ${Math.random() * 150 + 100}, ${Math.random() * 50 + 200}, `
        }
        this.meteors.push(meteor)
      }
    },
    drawStar(ctx, star) {
      ctx.beginPath()
      const gradient = ctx.createRadialGradient(
        star.x, star.y, 0,
        star.x, star.y, star.size
      )
      gradient.addColorStop(0, star.color + `${star.opacity})`) // 使用星星的颜色
      gradient.addColorStop(1, 'rgba(255, 255, 255, 0)')
      ctx.fillStyle = gradient
      ctx.arc(star.x, star.y, star.size, 0, Math.PI * 2)
      ctx.fill()
    },
    drawMeteor(ctx, meteor) {
      ctx.beginPath()
      const gradient = ctx.createLinearGradient(
        meteor.x, meteor.y,
        meteor.x + Math.cos(meteor.angle) * meteor.length,
        meteor.y + Math.sin(meteor.angle) * meteor.length
      )
      gradient.addColorStop(0, meteor.color + '0.7)') // 使用流星的颜色
      gradient.addColorStop(1, 'rgba(255, 255, 255, 0)')
      ctx.strokeStyle = gradient
      ctx.lineWidth = 2
      ctx.moveTo(meteor.x, meteor.y)
      ctx.lineTo(
        meteor.x + Math.cos(meteor.angle) * meteor.length,
        meteor.y + Math.sin(meteor.angle) * meteor.length
      )
      ctx.stroke()
    },
    updateStars() {
      this.stars.forEach(star => {
        star.opacity = Math.sin(Date.now() * star.speed) * 0.5 + 0.5
      })
    },
    updateMeteors() {
      this.meteors = this.meteors.filter(meteor => {
        meteor.x += meteor.speed * Math.cos(meteor.angle)
        meteor.y += meteor.speed * Math.sin(meteor.angle)
        return meteor.x < this.canvasWidth && meteor.y < this.canvasHeight
      })
    },
    animate() {
      const canvas = this.$refs.starCanvas
      const ctx = canvas.getContext('2d')
      
      // 清空画布
      ctx.fillStyle = 'rgba(0, 0, 0, 0.1)'
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight)
      
      // 更新和绘制星星
      this.updateStars()
      this.stars.forEach(star => this.drawStar(ctx, star))
      
      // 创建和更新流星
      this.createMeteor()
      this.updateMeteors()
      this.meteors.forEach(meteor => this.drawMeteor(ctx, meteor))
      
      this.animationId = requestAnimationFrame(this.animate)
    }
  }
}
</script>

<style scoped>
.star-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: #000;
  overflow: hidden;
}

canvas {
  display: block;
}
</style> 