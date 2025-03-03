<template>
  <div class="heart-container">
    <canvas ref="heartCanvas" :width="canvasWidth" :height="canvasHeight"></canvas>
  </div>
</template>

<script>
export default {
  name: 'TinyStar',
  data() {
    return {
      canvasWidth: window.innerWidth,
      canvasHeight: window.innerHeight,
      particles: [],
      backgroundStars: [],
      floatingLights: [],
      animationId: null,
      mousePosition: { x: 0, y: 0 },
      isAnimating: true,
      gradientHue: 0
    }
  },
  mounted() {
    this.initParticles()
    this.initBackground()
    this.animate()
    window.addEventListener('resize', this.handleResize)
    
    // 设置心形在屏幕中央
    this.mousePosition = {
      x: this.canvasWidth / 2,
      y: this.canvasHeight / 2
    }
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.handleResize)
    cancelAnimationFrame(this.animationId)
  },
  methods: {
    handleResize() {
      this.canvasWidth = window.innerWidth
      this.canvasHeight = window.innerHeight
      this.mousePosition = {
        x: this.canvasWidth / 2,
        y: this.canvasHeight / 2
      }
      this.initParticles()
      this.initBackground()
    },
    initBackground() {
      // 初始化背景星星
      this.backgroundStars = []
      const numStars = 150
      
      for (let i = 0; i < numStars; i++) {
        this.backgroundStars.push({
          x: Math.random() * this.canvasWidth,
          y: Math.random() * this.canvasHeight,
          size: Math.random() * 2,
          opacity: Math.random(),
          twinkleSpeed: Math.random() * 0.02 + 0.01
        })
      }
      
      // 初始化漂浮光点
      this.floatingLights = []
      const numLights = 30
      
      for (let i = 0; i < numLights; i++) {
        this.floatingLights.push({
          x: Math.random() * this.canvasWidth,
          y: Math.random() * this.canvasHeight,
          size: Math.random() * 5 + 2,
          vx: Math.random() * 1 - 0.5,
          vy: Math.random() * 1 - 0.5,
          hue: Math.random() * 60 + 300, // 紫色到粉色范围
          opacity: Math.random() * 0.5 + 0.2
        })
      }
    },
    initParticles() {
      this.particles = []
      const heartPoints = this.generateHeartShape()
      
      heartPoints.forEach(point => {
        this.particles.push({
          x: point.x + this.canvasWidth / 2,
          y: point.y + this.canvasHeight / 2,
          baseX: point.x + this.canvasWidth / 2,
          baseY: point.y + this.canvasHeight / 2,
          size: Math.random() * 3 + 1,
          color: `rgb(${Math.random() * 55 + 200}, ${Math.random() * 50 + 50}, ${Math.random() * 50 + 100})`,
          speed: Math.random() * 2 + 1,
          angle: Math.random() * Math.PI * 2,
          amplitude: Math.random() * 20 + 10
        })
      })
    },
    generateHeartShape() {
      const points = []
      const scale = Math.min(this.canvasWidth, this.canvasHeight) * 0.2
      
      for (let angle = 0; angle < Math.PI * 2; angle += 0.02) {
        const x = 16 * Math.pow(Math.sin(angle), 3)
        const y = -(13 * Math.cos(angle) - 5 * Math.cos(2 * angle) - 2 * Math.cos(3 * angle) - Math.cos(4 * angle))
        
        // 为心形轮廓添加随机偏移，创造粒子云效果
        for (let i = 0; i < 3; i++) {
          const randomOffset = Math.random() * 20 - 10
          points.push({
            x: x * scale / 16 + randomOffset,
            y: y * scale / 16 + randomOffset
          })
        }
      }
      return points
    },
    drawBackground(ctx) {
      // 渐变背景
      this.gradientHue = (this.gradientHue + 0.1) % 360
      const baseHue = this.gradientHue
      
      // 创建动态径向渐变
      const gradient = ctx.createRadialGradient(
        this.canvasWidth / 2, this.canvasHeight / 2, 0,
        this.canvasWidth / 2, this.canvasHeight / 2, Math.max(this.canvasWidth, this.canvasHeight) / 1.5
      )
      
      gradient.addColorStop(0, `hsla(${baseHue + 240}, 70%, 10%, 0.2)`)
      gradient.addColorStop(0.5, `hsla(${baseHue + 280}, 90%, 5%, 0.2)`)
      gradient.addColorStop(1, `hsla(${baseHue + 320}, 80%, 2%, 0.2)`)
      
      ctx.fillStyle = gradient
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight)
      
      // 绘制背景星星
      this.backgroundStars.forEach(star => {
        star.opacity = Math.sin(Date.now() * star.twinkleSpeed) * 0.5 + 0.5
        ctx.beginPath()
        ctx.arc(star.x, star.y, star.size, 0, Math.PI * 2)
        ctx.fillStyle = `rgba(255, 255, 255, ${star.opacity * 0.5})`
        ctx.fill()
      })
      
      // 更新和绘制漂浮光点
      this.floatingLights.forEach(light => {
        // 更新位置
        light.x += light.vx
        light.y += light.vy
        
        // 边界检查
        if (light.x < 0 || light.x > this.canvasWidth) light.vx *= -1
        if (light.y < 0 || light.y > this.canvasHeight) light.vy *= -1
        
        // 绘制光点
        ctx.beginPath()
        const gradient = ctx.createRadialGradient(
          light.x, light.y, 0,
          light.x, light.y, light.size * 2
        )
        gradient.addColorStop(0, `hsla(${light.hue}, 100%, 70%, ${light.opacity})`)
        gradient.addColorStop(1, `hsla(${light.hue}, 100%, 50%, 0)`)
        
        ctx.fillStyle = gradient
        ctx.arc(light.x, light.y, light.size * 2, 0, Math.PI * 2)
        ctx.fill()
      })
      
      // 绘制小星星
      this.drawCenterStar(ctx)
      
      // 偶尔添加流星效果
      if (Math.random() < 0.01) {
        this.createMeteor(ctx)
      }
    },
    drawCenterStar(ctx) {
      ctx.save()
      
      // 计算星星位置 - 在爱心中间
      const starX = this.canvasWidth / 2
      const starY = this.canvasHeight / 2
      
      // 创建呼吸效果
      const breathEffect = Math.sin(Date.now() * 0.001) * 0.2 + 0.8
      
      // 计算星星大小 - 随屏幕大小调整
      const starSize = Math.min(this.canvasWidth, this.canvasHeight) * 0.04
      
      // 设置发光效果
      ctx.shadowBlur = 15
      ctx.shadowColor = `hsla(${this.gradientHue + 50}, 100%, 75%, ${breathEffect * 0.8})`
      
      // 创建星星渐变
      const starGradient = ctx.createRadialGradient(
        starX, starY, 0,
        starX, starY, starSize
      )
      starGradient.addColorStop(0, `hsla(${this.gradientHue + 50}, 100%, 90%, ${breathEffect})`); // 亮黄色中心
      starGradient.addColorStop(0.5, `hsla(${this.gradientHue + 40}, 100%, 80%, ${breathEffect})`); // 黄色
      starGradient.addColorStop(1, `hsla(${this.gradientHue + 30}, 100%, 70%, ${breathEffect * 0.7})`); // 橙黄色边缘
      
      ctx.fillStyle = starGradient
      
      // 绘制五角星
      ctx.beginPath()
      for (let i = 0; i < 5; i++) {
        // 外角点
        const outerX = starX + starSize * Math.cos((i * 2 * Math.PI / 5) - Math.PI / 2)
        const outerY = starY + starSize * Math.sin((i * 2 * Math.PI / 5) - Math.PI / 2)
        
        // 内角点
        const innerX = starX + starSize * 0.4 * Math.cos(((i * 2 + 1) * Math.PI / 5) - Math.PI / 2)
        const innerY = starY + starSize * 0.4 * Math.sin(((i * 2 + 1) * Math.PI / 5) - Math.PI / 2)
        
        // 第一个点需要moveTo，其余的是lineTo
        if (i === 0) {
          ctx.moveTo(outerX, outerY)
        } else {
          ctx.lineTo(outerX, outerY)
        }
        
        // 连接到内角点
        ctx.lineTo(innerX, innerY)
      }
      ctx.closePath()
      ctx.fill()
      
      // 添加星星发光效果
      ctx.globalCompositeOperation = 'lighter'
      ctx.shadowBlur = 25
      ctx.fillStyle = `hsla(${this.gradientHue + 50}, 100%, 85%, ${breathEffect * 0.4})`
      
      // 再次绘制以增强发光效果
      ctx.beginPath()
      for (let i = 0; i < 5; i++) {
        const outerX = starX + starSize * 0.9 * Math.cos((i * 2 * Math.PI / 5) - Math.PI / 2)
        const outerY = starY + starSize * 0.9 * Math.sin((i * 2 * Math.PI / 5) - Math.PI / 2)
        const innerX = starX + starSize * 0.3 * Math.cos(((i * 2 + 1) * Math.PI / 5) - Math.PI / 2)
        const innerY = starY + starSize * 0.3 * Math.sin(((i * 2 + 1) * Math.PI / 5) - Math.PI / 2)
        
        if (i === 0) {
          ctx.moveTo(outerX, outerY)
        } else {
          ctx.lineTo(outerX, outerY)
        }
        
        ctx.lineTo(innerX, innerY)
      }
      ctx.closePath()
      ctx.fill()
      
      ctx.restore()
    },
    createMeteor(ctx) {
      const meteor = {
        x: Math.random() * this.canvasWidth,
        y: 0,
        length: Math.random() * 150 + 100,
        speed: Math.random() * 10 + 15,
        angle: Math.PI / 4 + (Math.random() * 0.2 - 0.1)
      }
      
      // 绘制流星
      ctx.save()
      ctx.beginPath()
      const gradient = ctx.createLinearGradient(
        meteor.x, meteor.y,
        meteor.x + Math.cos(meteor.angle) * meteor.length,
        meteor.y + Math.sin(meteor.angle) * meteor.length
      )
      gradient.addColorStop(0, 'rgba(255, 255, 255, 0.8)')
      gradient.addColorStop(1, 'rgba(255, 255, 255, 0)')
      
      ctx.strokeStyle = gradient
      ctx.lineWidth = 2
      ctx.moveTo(meteor.x, meteor.y)
      ctx.lineTo(
        meteor.x + Math.cos(meteor.angle) * meteor.length,
        meteor.y + Math.sin(meteor.angle) * meteor.length
      )
      ctx.stroke()
      ctx.restore()
    },
    animate() {
      const canvas = this.$refs.heartCanvas
      const ctx = canvas.getContext('2d')
      
      // 清除画布，使用半透明黑色创造轨迹效果
      ctx.fillStyle = 'rgba(0, 0, 0, 0.1)'
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight)
      
      // 绘制背景
      this.drawBackground(ctx)
      
      // 设置全局合成操作
      ctx.globalCompositeOperation = 'lighter'
      
      this.particles.forEach(particle => {
        // 粒子运动
        particle.angle += 0.02
        particle.x = particle.baseX + Math.cos(particle.angle) * particle.amplitude
        particle.y = particle.baseY + Math.sin(particle.angle) * particle.amplitude
        
        // 绘制粒子
        ctx.beginPath()
        ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2)
        ctx.fillStyle = particle.color
        ctx.shadowBlur = 15
        ctx.shadowColor = particle.color
        ctx.fill()
      })
      
      // 重置全局合成操作
      ctx.globalCompositeOperation = 'source-over'
      
      this.animationId = requestAnimationFrame(this.animate)
    }
  }
}
</script>

<style scoped>
.heart-container {
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