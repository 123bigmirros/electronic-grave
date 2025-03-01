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
      // 创建200颗爱心星星
      this.stars = Array(200).fill().map(() => ({
        x: Math.random() * this.canvasWidth,
        y: Math.random() * this.canvasHeight,
        size: Math.random() * 2 + 1, // 爱心大小
        opacity: Math.random(),
        speed: Math.random() * 0.05 + 0.02,
        color: Math.random() > 0.5 ? 
          `rgba(255, 182, 193, ` : // 粉色爱心
          `rgba(255, 105, 180, ` // 深粉色爱心
      }))
    },
    createMeteor() {
      // 增加爱心流星出现频率
      if (Math.random() < 0.03) {
        const meteor = {
          x: Math.random() * this.canvasWidth,
          y: 0,
          length: Math.random() * 100 + 50,
          speed: Math.random() * 15 + 10,
          angle: Math.PI / 4,
          size: Math.random() * 3 + 2,
          color: Math.random() > 0.5 ?
            'rgba(255, 182, 193, ' : // 粉色流星
            'rgba(255, 105, 180, ' // 深粉色流星
        }
        this.meteors.push(meteor)
      }
    },
    drawStar(ctx, star) {
      ctx.beginPath()
      ctx.save()
      ctx.translate(star.x, star.y)
      ctx.scale(star.size, star.size)
      
      // 绘制爱心
      ctx.moveTo(0, 0)
      ctx.bezierCurveTo(-2, -2, -4, 2, 0, 4)
      ctx.bezierCurveTo(4, 2, 2, -2, 0, 0)
      
      const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, 4)
      gradient.addColorStop(0, star.color + `${star.opacity})`)
      gradient.addColorStop(1, 'rgba(255, 192, 203, 0)')
      
      ctx.fillStyle = gradient
      ctx.fill()
      ctx.restore()
    },
    drawMeteor(ctx, meteor) {
      ctx.save()
      // 绘制流星轨迹
      ctx.beginPath()
      const gradient = ctx.createLinearGradient(
        meteor.x, meteor.y,
        meteor.x + Math.cos(meteor.angle) * meteor.length,
        meteor.y + Math.sin(meteor.angle) * meteor.length
      )
      gradient.addColorStop(0, meteor.color + '0.8)')
      gradient.addColorStop(1, 'rgba(255, 192, 203, 0)')
      ctx.strokeStyle = gradient
      ctx.lineWidth = 1
      ctx.moveTo(meteor.x, meteor.y)
      ctx.lineTo(
        meteor.x + Math.cos(meteor.angle) * meteor.length,
        meteor.y + Math.sin(meteor.angle) * meteor.length
      )
      ctx.stroke()

      // 在流星头部绘制爱心
      ctx.translate(meteor.x, meteor.y)
      ctx.scale(meteor.size, meteor.size)
      ctx.beginPath()
      ctx.moveTo(0, 0)
      ctx.bezierCurveTo(-2, -2, -4, 2, 0, 4)
      ctx.bezierCurveTo(4, 2, 2, -2, 0, 0)
      ctx.fillStyle = meteor.color + '1)'
      ctx.fill()
      ctx.restore()
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
      
      // 使用深色背景，让爱心更突出
      ctx.fillStyle = 'rgba(25, 25, 50, 0.1)'
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight)
      
      // 更新和绘制爱心星星
      this.updateStars()
      this.stars.forEach(star => this.drawStar(ctx, star))
      
      // 创建和更新爱心流星
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