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
      gradientHue: 0,
      heartbeatTime: 0,
      lastBeatTime: 0
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
        // 创建更多样化的粒子颜色，使用HSL色彩空间以获得更美丽的渐变
        const hue = Math.random() * 20 + 330 // 330-350范围的色相，粉红到紫红
        const saturation = Math.random() * 30 + 70 // 70%-100%饱和度
        const lightness = Math.random() * 20 + 70 // 70%-90%亮度
        
        this.particles.push({
          x: point.x + this.canvasWidth / 2,
          y: point.y + this.canvasHeight / 2,
          baseX: point.x + this.canvasWidth / 2,
          baseY: point.y + this.canvasHeight / 2,
          size: Math.random() * 3.5 + 1.5, // 稍微增大粒子尺寸
          color: `hsl(${hue}, ${saturation}%, ${lightness}%)`,
          speed: Math.random() * 2 + 1,
          angle: Math.random() * Math.PI * 2,
          amplitude: Math.random() * 15 + 5, // 调整振幅范围，使运动更加统一
          glow: Math.random() * 10 + 10 // 添加不同的发光强度
        })
      })
    },
    generateHeartShape() {
      const points = []
      const scale = Math.min(this.canvasWidth, this.canvasHeight) * 0.22 // 稍微放大爱心
      
      for (let angle = 0; angle < Math.PI * 2; angle += 0.015) { // 增加点密度
        const x = 16 * Math.pow(Math.sin(angle), 3)
        const y = -(13 * Math.cos(angle) - 5 * Math.cos(2 * angle) - 2 * Math.cos(3 * angle) - Math.cos(4 * angle))
        
        // 创建主轮廓粒子（少量随机偏移）
        points.push({
          x: x * scale / 16 + (Math.random() * 6 - 3), // 较小的随机偏移，使心形轮廓更清晰
          y: y * scale / 16 + (Math.random() * 6 - 3)
        })
        
        // 在心形内部添加一些随机粒子
        if (Math.random() < 0.3) {
          const innerScale = Math.random() * 0.6 + 0.2 // 20%-80%的内部缩放
          points.push({
            x: x * scale / 16 * innerScale,
            y: y * scale / 16 * innerScale
          })
        }
      }
      return points
    },
    drawBackground(ctx) {
      // 渐变背景
      this.gradientHue = (this.gradientHue + 0.05) % 360
      const baseHue = this.gradientHue
      
      // 创建动态径向渐变 - 使用更柔和的色彩
      const gradient = ctx.createRadialGradient(
        this.canvasWidth / 2, this.canvasHeight / 2, 0,
        this.canvasWidth / 2, this.canvasHeight / 2, Math.max(this.canvasWidth, this.canvasHeight) / 1.2
      )
      
      // 改进背景渐变色，使用更柔和的色调
      gradient.addColorStop(0, `hsla(${baseHue + 280}, 70%, 15%, 0.2)`) // 更柔和的紫色
      gradient.addColorStop(0.5, `hsla(${baseHue + 300}, 80%, 8%, 0.2)`) // 深蓝紫色
      gradient.addColorStop(1, `hsla(${baseHue + 260}, 70%, 5%, 0.2)`) // 深蓝色
      
      ctx.fillStyle = gradient
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight)
      
      // 绘制背景星星 - 增加星星的亮度和变化
      this.backgroundStars.forEach(star => {
        star.opacity = Math.sin(Date.now() * star.twinkleSpeed) * 0.5 + 0.5
        
        // 星星的脉动大小效果
        const pulseSize = star.size * (1 + Math.sin(Date.now() * 0.001) * 0.2)
        
        ctx.beginPath()
        ctx.arc(star.x, star.y, pulseSize, 0, Math.PI * 2)
        ctx.fillStyle = `rgba(255, 255, 255, ${star.opacity * 0.7})`
        ctx.fill()
        
        // 偶尔添加星芒效果
        if (star.size > 1.5 && Math.random() < 0.3) {
          ctx.save()
          ctx.translate(star.x, star.y)
          ctx.rotate(Date.now() * 0.0005)
          
          const starGlow = ctx.createRadialGradient(0, 0, 0, 0, 0, star.size * 4)
          starGlow.addColorStop(0, `rgba(255, 255, 255, ${star.opacity * 0.8})`)
          starGlow.addColorStop(1, 'rgba(255, 255, 255, 0)')
          
          ctx.beginPath()
          for (let i = 0; i < 4; i++) {
            ctx.moveTo(0, 0)
            ctx.lineTo(0, star.size * 4)
            ctx.rotate(Math.PI / 2)
          }
          ctx.strokeStyle = starGlow
          ctx.lineWidth = 0.5
          ctx.stroke()
          ctx.restore()
        }
      })
      
      // 更新和绘制漂浮光点 - 调整为更丰富的色彩
      this.floatingLights.forEach(light => {
        // 更新位置 - 更加柔和的移动
        light.x += light.vx * 0.7
        light.y += light.vy * 0.7
        
        // 边界检查
        if (light.x < 0 || light.x > this.canvasWidth) light.vx *= -1
        if (light.y < 0 || light.y > this.canvasHeight) light.vy *= -1
        
        // 绘制光点 - 更富有变化的颜色
        ctx.beginPath()
        const pulseFactor = 1 + Math.sin(Date.now() * 0.001) * 0.3
        const gradient = ctx.createRadialGradient(
          light.x, light.y, 0,
          light.x, light.y, light.size * 2 * pulseFactor
        )
        
        // 使用基于时间变化的色相
        const hue = (light.hue + baseHue * 0.2) % 360
        gradient.addColorStop(0, `hsla(${hue}, 100%, 80%, ${light.opacity * 1.2})`)
        gradient.addColorStop(0.5, `hsla(${hue - 20}, 100%, 70%, ${light.opacity * 0.7})`)
        gradient.addColorStop(1, `hsla(${hue - 40}, 100%, 60%, 0)`)
        
        ctx.fillStyle = gradient
        ctx.arc(light.x, light.y, light.size * 2 * pulseFactor, 0, Math.PI * 2)
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
      
      // 创建呼吸和旋转效果
      const breathEffect = Math.sin(Date.now() * 0.001) * 0.2 + 0.8
      const rotationAngle = Date.now() * 0.0005
      
      // 计算星星大小 - 调整为更合适的大小，与爱心协调
      const starSize = Math.min(this.canvasWidth, this.canvasHeight) * 0.04
      
      // 设置发光效果 - 使用与爱心协调的色调
      ctx.shadowBlur = 25
      ctx.shadowColor = `hsla(${this.gradientHue + 340}, 100%, 75%, ${breathEffect})`
      
      // 创建星星渐变 - 与爱心粒子色彩协调
      const starGradient = ctx.createRadialGradient(
        starX, starY, 0,
        starX, starY, starSize
      )
      starGradient.addColorStop(0, `hsla(${this.gradientHue + 340}, 100%, 95%, ${breathEffect})`); // 更亮的粉色中心
      starGradient.addColorStop(0.5, `hsla(${this.gradientHue + 335}, 100%, 85%, ${breathEffect})`); // 粉色
      starGradient.addColorStop(1, `hsla(${this.gradientHue + 330}, 100%, 75%, ${breathEffect * 0.8})`); // 深粉色边缘
      
      ctx.fillStyle = starGradient
      
      // 添加旋转效果
      ctx.translate(starX, starY)
      ctx.rotate(rotationAngle)
      ctx.translate(-starX, -starY)
      
      // 绘制五角星 - 更加精致
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
      
      // 添加星星发光效果 - 更加明亮
      ctx.globalCompositeOperation = 'lighter'
      ctx.shadowBlur = 35
      ctx.fillStyle = `hsla(${this.gradientHue + 340}, 100%, 90%, ${breathEffect * 0.7})`
      
      // 绘制光芒效果
      const rayLength = starSize * 2
      ctx.beginPath()
      for (let i = 0; i < 8; i++) {
        const angle = i * Math.PI / 4 + rotationAngle * 0.5 // 添加旋转效果
        ctx.moveTo(starX, starY)
        ctx.lineTo(
          starX + Math.cos(angle) * rayLength,
          starY + Math.sin(angle) * rayLength
        )
      }
      ctx.strokeStyle = `hsla(${this.gradientHue + 340}, 100%, 95%, ${breathEffect * 0.5})`
      ctx.lineWidth = 1.5
      ctx.stroke()
      
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
      
      // 添加小光点装饰
      for (let i = 0; i < 12; i++) {
        const angle = i * Math.PI / 6
        const distance = starSize * 0.9
        const x = starX + Math.cos(angle) * distance
        const y = starY + Math.sin(angle) * distance
        
        ctx.beginPath()
        ctx.arc(x, y, starSize * 0.1 * breathEffect, 0, Math.PI * 2)
        ctx.fillStyle = `hsla(${this.gradientHue + 340}, 100%, 95%, ${breathEffect * 0.8})`
        ctx.fill()
      }
      
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
      
      // 更新心跳时间
      const currentTime = Date.now() * 0.001
      
      // 模拟心跳的两个阶段：快速收缩和较慢舒张
      // 每1.2秒一个完整心跳周期
      const heartbeatCycle = 1.2
      const beatPhase = ((currentTime % heartbeatCycle) / heartbeatCycle)
      
      // 计算心跳强度：模拟心脏的"砰-砰"双跳
      let heartbeatIntensity = 0
      if (beatPhase < 0.1) { // 第一次收缩 (砰)
        heartbeatIntensity = Math.sin(beatPhase * Math.PI / 0.1)
      } else if (beatPhase < 0.2) { // 第一次舒张
        heartbeatIntensity = Math.sin((0.2 - beatPhase) * Math.PI / 0.1) * 0.3
      } else if (beatPhase < 0.3) { // 第二次收缩 (砰)
        heartbeatIntensity = Math.sin((beatPhase - 0.2) * Math.PI / 0.1) * 0.8
      } else if (beatPhase < 0.5) { // 第二次舒张
        heartbeatIntensity = Math.sin((0.5 - beatPhase) * Math.PI / 0.2) * 0.3
      }
      // 0.5-1.0是休息期，heartbeatIntensity保持为0
      
      // 心跳时发出亮光
      if (beatPhase < 0.1 && this.heartbeatTime < currentTime - 0.05) {
        this.heartbeatTime = currentTime
        this.addHeartbeatGlow(ctx)
      }
      
      // 清除画布，使用半透明黑色创造轨迹效果
      ctx.fillStyle = 'rgba(0, 0, 0, 0.1)'
      ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight)
      
      // 绘制背景
      this.drawBackground(ctx)
      
      // 设置全局合成操作
      ctx.globalCompositeOperation = 'lighter'
      
      // 绘制爱心脉动外环
      this.drawHeartPulse(ctx, heartbeatIntensity)
      
      // 绘制爱心粒子
      this.particles.forEach(particle => {
        // 粒子运动 - 添加心跳影响
        particle.angle += 0.02
        
        // 基本位置
        let x = particle.baseX + Math.cos(particle.angle) * particle.amplitude
        let y = particle.baseY + Math.sin(particle.angle) * particle.amplitude
        
        // 心跳时的额外位移 - 从中心向外扩散
        const dx = x - this.canvasWidth / 2
        const dy = y - this.canvasHeight / 2
        const distance = Math.sqrt(dx * dx + dy * dy)
        
        if (distance > 0) {
          const normalizedDx = dx / distance
          const normalizedDy = dy / distance
          
          // 在心跳时向外扩张，然后快速回缩
          const heartbeatDisplacement = heartbeatIntensity * 5 * Math.min(distance, 30) / 30
          
          x += normalizedDx * heartbeatDisplacement
          y += normalizedDy * heartbeatDisplacement
        }
        
        // 呼吸效果 + 心跳影响
        const baseBreathEffect = Math.sin(Date.now() * 0.001 + particle.angle) * 0.3 + 0.7
        const sizeEffect = baseBreathEffect * (1 + heartbeatIntensity * 0.3)
        const glowEffect = (1 + heartbeatIntensity * 0.5)
        
        // 绘制粒子
        ctx.beginPath()
        ctx.arc(x, y, particle.size * sizeEffect, 0, Math.PI * 2)
        ctx.fillStyle = this.adjustColorForHeartbeat(particle.color, heartbeatIntensity)
        ctx.shadowBlur = particle.glow * baseBreathEffect * glowEffect
        ctx.shadowColor = this.adjustColorForHeartbeat(particle.color, heartbeatIntensity)
        ctx.fill()
        
        // 存储实际位置，用于连接线
        particle.x = x
        particle.y = y
        
        // 为一部分粒子添加连接线，创造网状效果
        if (Math.random() < 0.03) {
          this.connectNearbyParticles(ctx, particle, heartbeatIntensity)
        }
      })
      
      // 重置全局合成操作
      ctx.globalCompositeOperation = 'source-over'
      
      this.animationId = requestAnimationFrame(this.animate)
    },
    // 心跳时颜色调整
    adjustColorForHeartbeat(color, intensity) {
      if (intensity <= 0) return color
      
      // 对HSL颜色进行调整
      if (color.startsWith('hsl')) {
        // 提取HSL值
        const hslMatch = color.match(/hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)/)
        if (hslMatch) {
          const h = parseInt(hslMatch[1])
          const s = parseInt(hslMatch[2])
          const l = parseInt(hslMatch[3])
          
          // 心跳时增加亮度，稍微减少饱和度
          const newL = Math.min(100, l + intensity * 20)
          const newS = Math.max(60, s - intensity * 10)
          
          return `hsl(${h}, ${newS}%, ${newL}%)`
        }
      }
      
      return color
    },
    // 添加心跳发光效果
    addHeartbeatGlow(ctx) {
      const centerX = this.canvasWidth / 2
      const centerY = this.canvasHeight / 2
      const radius = Math.min(this.canvasWidth, this.canvasHeight) * 0.3
      
      ctx.save()
      ctx.globalCompositeOperation = 'lighter'
      
      const gradient = ctx.createRadialGradient(
        centerX, centerY, 0,
        centerX, centerY, radius
      )
      
      gradient.addColorStop(0, `hsla(${this.gradientHue + 340}, 100%, 80%, 0.3)`)
      gradient.addColorStop(1, 'hsla(0, 0%, 100%, 0)')
      
      ctx.fillStyle = gradient
      ctx.beginPath()
      ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
      ctx.fill()
      
      ctx.restore()
    },
    // 修改脉动环方法，添加心跳参数
    drawHeartPulse(ctx, heartbeatIntensity) {
      const time = Date.now() * 0.001
      const heartScale = Math.min(this.canvasWidth, this.canvasHeight) * 0.22
      const centerX = this.canvasWidth / 2
      const centerY = this.canvasHeight / 2
      
      // 创建多个脉动环
      for (let i = 0; i < 2; i++) {
        // 同步脉动环与心跳
        const pulse = (time + i * 1.5) % 3
        
        if (pulse < 2) { // 只在特定时间范围内显示
          // 心跳强度影响脉动环的大小和不透明度
          const beatEffect = 1 + heartbeatIntensity * 0.3
          const pulseSize = heartScale * (1 + pulse * 0.5 * beatEffect) // 从心形大小扩展
          const opacity = (0.3 + heartbeatIntensity * 0.2) * (1 - pulse / 2) // 随着扩大逐渐变透明
          
          ctx.save()
          ctx.translate(centerX, centerY)
          ctx.beginPath()
          
          // 绘制心形轮廓
          for (let angle = 0; angle < Math.PI * 2; angle += 0.03) {
            const x = 16 * Math.pow(Math.sin(angle), 3)
            const y = -(13 * Math.cos(angle) - 5 * Math.cos(2 * angle) - 2 * Math.cos(3 * angle) - Math.cos(4 * angle))
            
            const px = x * pulseSize / 16
            const py = y * pulseSize / 16
            
            if (angle === 0) {
              ctx.moveTo(px, py)
            } else {
              ctx.lineTo(px, py)
            }
          }
          
          ctx.closePath()
          // 心跳时改变脉动环颜色
          const hue = this.gradientHue + 340 + heartbeatIntensity * 20
          ctx.strokeStyle = `hsla(${hue}, 100%, ${80 + heartbeatIntensity * 15}%, ${opacity})`
          ctx.lineWidth = 2 + heartbeatIntensity * 1.5
          ctx.stroke()
          ctx.restore()
        }
      }
    },
    // 修改连接线方法，添加心跳参数
    connectNearbyParticles(ctx, particle, heartbeatIntensity) {
      const maxDistance = 50 * (1 + heartbeatIntensity * 0.3) // 心跳时连接距离增加
      const centerX = this.canvasWidth / 2
      const centerY = this.canvasHeight / 2
      
      // 只连接爱心中心区域的粒子
      if (Math.abs(particle.x - centerX) > 100 || Math.abs(particle.y - centerY) > 100) {
        return
      }
      
      // 心跳时增加连接的数量
      const connectionCount = Math.floor(3 + heartbeatIntensity * 2)
      
      // 寻找附近的粒子并连接
      for (let i = 0; i < connectionCount; i++) {
        const otherParticle = this.particles[Math.floor(Math.random() * this.particles.length)]
        const dx = otherParticle.x - particle.x
        const dy = otherParticle.y - particle.y
        const distance = Math.sqrt(dx * dx + dy * dy)
        
        if (distance < maxDistance) {
          // 心跳时增加线的不透明度
          const opacity = (1 - distance / maxDistance) * (0.2 + heartbeatIntensity * 0.2)
          ctx.beginPath()
          ctx.moveTo(particle.x, particle.y)
          ctx.lineTo(otherParticle.x, otherParticle.y)
          
          // 使用粒子自身的颜色创建渐变连接线
          const gradient = ctx.createLinearGradient(
            particle.x, particle.y, otherParticle.x, otherParticle.y
          )
          
          // 心跳时调整颜色
          const color1 = this.adjustColorForHeartbeat(particle.color, heartbeatIntensity)
            .replace(')', `, ${opacity})`)
            .replace('hsl', 'hsla')
          
          const color2 = this.adjustColorForHeartbeat(otherParticle.color, heartbeatIntensity)
            .replace(')', `, ${opacity})`)
            .replace('hsl', 'hsla')
          
          gradient.addColorStop(0, color1)
          gradient.addColorStop(1, color2)
          
          ctx.strokeStyle = gradient
          ctx.lineWidth = 0.5 + heartbeatIntensity * 0.5
          ctx.stroke()
        }
      }
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