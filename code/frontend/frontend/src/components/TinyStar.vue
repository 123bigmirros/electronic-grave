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
      // 创建200颗星星
      this.stars = Array(200).fill().map(() => ({
        x: Math.random() * this.canvasWidth,
        y: Math.random() * this.canvasHeight,
        size: Math.random() * 2 + 1,
        opacity: Math.random(),
        speed: Math.random() * 0.05 + 0.02
      }))
    },
    createMeteor() {
      // 随机创建流星
      if (Math.random() < 0.03) {
        const meteor = {
          x: Math.random() * this.canvasWidth,
          y: 0,
          length: Math.random() * 80 + 100,
          speed: Math.random() * 15 + 10,
          angle: Math.PI / 4
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
      gradient.addColorStop(0, `rgba(255, 255, 255, ${star.opacity})`)
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
      gradient.addColorStop(0, 'rgba(255, 255, 255, 0.7)')
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