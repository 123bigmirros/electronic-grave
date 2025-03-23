"""
Agent Service for canvas control operations
处理用户对画布的智能控制请求，包括组件添加、移动、编辑等操作
"""
import json
from flask import jsonify
from service.canvas_message_service import CanvasMessageService

class AgentService:
    def __init__(self):
        self.canvas_message_service = CanvasMessageService()
        
    def handle_canvas_control(self, data):
        """处理画布控制请求，返回AI回复和操作指令"""
        user_message = data.get('message', '')
        canvas_summary = data.get('canvas_summary', {})
        history = data.get('history', [])
        
        # 构建系统提示
        system_prompt = self.create_canvas_control_prompt(canvas_summary)
        
        # 格式化历史对话
        formatted_history = []
        for msg in history:
            role = msg.get('role', '')
            content = msg.get('content', '')
            if role and content:
                formatted_history.append({"role": role, "content": content})
        
        # 调用LLM进行处理
        response = self.canvas_message_service.call_llm_with_prompt(
            system_prompt, 
            user_message, 
            formatted_history
        )
        
        # 解析响应，提取操作指令
        action = self.extract_action_from_response(response)
        
        # 从响应中删除JSON代码块
        cleaned_response = self.remove_json_from_response(response)
        
        return {
            "answer": cleaned_response,
            "action": action
        }
        
    def remove_json_from_response(self, response):
        """从响应中删除JSON代码块"""
        # 查找并删除```json...```代码块
        json_start = response.find("```json")
        if json_start != -1:
            json_end = response.find("```", json_start + 7)
            if json_end != -1:
                json_end += 3  # 包含结束的```
                cleaned_response = response[:json_start] + response[json_end:]
                # 清理多余的空行
                cleaned_response = '\n'.join(line for line in cleaned_response.split('\n') if line.strip())
                return cleaned_response
        
        # 查找并删除单独的JSON对象（如果没有代码块格式）
        json_start = response.find("{")
        if json_start != -1:
            json_end = response.rfind("}") + 1
            if json_end > json_start:
                # 检查是否是独立的JSON（而不是文本中提到的JSON例子）
                before_json = response[:json_start].strip()
                after_json = response[json_end:].strip()
                
                # 如果JSON前后有明显的分隔（如空行），则删除
                if before_json.endswith('\n\n') or after_json.startswith('\n\n'):
                    cleaned_response = before_json + after_json
                    return cleaned_response
        
        # 如果没有找到JSON或不确定是否应该删除，则返回原始响应
        return response
        
    def extract_action_from_response(self, response):
        """从LLM响应中提取操作指令"""
        try:
            # 查找JSON代码块
            json_start = response.find("```json")
            json_end = response.find("```", json_start + 7)
            
            if json_start != -1 and json_end != -1:
                json_str = response[json_start + 7:json_end].strip()
                action = json.loads(json_str)
                return action
            
            # 如果没有代码块格式，尝试直接解析JSON对象
            json_start = response.find("{")
            json_end = response.rfind("}") + 1
            
            if json_start != -1 and json_end != -1 and json_end > json_start:
                json_str = response[json_start:json_end]
                action = json.loads(json_str)
                return action
                
            return None
        except Exception as e:
            print(f"Error extracting action: {e}")
            return None
            
    def create_canvas_control_prompt(self, canvas_summary):
        """创建画布控制的系统提示"""
        texts = canvas_summary.get('texts', [])
        images = canvas_summary.get('images', [])
        heritages = canvas_summary.get('heritages', [])
        markdowns = canvas_summary.get('markdowns', [])
        
        # 构建组件列表描述
        components_desc = []
        
        if texts:
            components_desc.append("文本框:")
            for i, text in enumerate(texts):
                components_desc.append(f"  {i+1}. 名称: {text['name']}, 内容: {text['content']}, 位置: 左{text['position']['left']}px, 上{text['position']['top']}px, 宽{text['position']['width']}px, 高{text['position']['height']}px")
        
        if images:
            components_desc.append("图片:")
            for i, img in enumerate(images):
                components_desc.append(f"  {i+1}. 名称: {img['name']}, 图片URL: {img['imageUrl']}, 位置: 左{img['position']['left']}px, 上{img['position']['top']}px, 宽{img['position']['width']}px, 高{img['position']['height']}px")
        
        if heritages:
            components_desc.append("遗产信息:")
            for i, heritage in enumerate(heritages):
                components_desc.append(f"  {i+1}. 名称: {heritage['name']}, 公开时间: {heritage['publicTime']}, 项目数: {heritage['itemCount']}, 位置: 左{heritage['position']['left']}px, 上{heritage['position']['top']}px, 宽{heritage['position']['width']}px, 高{heritage['position']['height']}px")
        
        if markdowns:
            components_desc.append("Markdown编辑器:")
            for i, md in enumerate(markdowns):
                components_desc.append(f"  {i+1}. 名称: {md['name']}, 位置: 左{md['position']['left']}px, 上{md['position']['top']}px, 宽{md['position']['width']}px, 高{md['position']['height']}px")
        
        # 分析画布已占用区域和可用空间
        all_components = []
        for comp_list in [texts, images, heritages, markdowns]:
            for comp in comp_list:
                if 'position' in comp:
                    pos = comp['position']
                    all_components.append({
                        'left': pos['left'],
                        'top': pos['top'],
                        'right': pos['left'] + pos['width'],
                        'bottom': pos['top'] + pos['height']
                    })
        
        # 找出画布已使用的区域边界
        canvas_used = {
            'min_left': min([comp['left'] for comp in all_components]) if all_components else 0,
            'min_top': min([comp['top'] for comp in all_components]) if all_components else 0,
            'max_right': max([comp['right'] for comp in all_components]) if all_components else 0,
            'max_bottom': max([comp['bottom'] for comp in all_components]) if all_components else 0
        } if all_components else {'min_left': 0, 'min_top': 0, 'max_right': 0, 'max_bottom': 0}
        
        # 定义画布的固定边界区域
        canvas_boundary = {
            'min_left': 50,   # 左边界
            'min_top': 50,    # 上边界
            'max_right': 960, # 右边界
            'max_bottom': 700 # 下边界
        }
        
        # 判断画布布局状态
        layout_state = "空白" if not all_components else "已有组件"
        
        # 组装完整系统提示
        system_prompt = f"""你是一个专业的画布编辑助手，负责理解用户的自然语言指令并将其转换为具体的画布操作。
你的任务是通过对话方式帮助用户调整画布中的组件位置和内容。

当前画布包含以下组件：

{chr(10).join(components_desc)}

画布当前状态: {layout_state}
画布已使用区域: 左上角({canvas_used['min_left']},{canvas_used['min_top']})，右下角({canvas_used['max_right']},{canvas_used['max_bottom']})
画布固定边界: 左上角({canvas_boundary['min_left']},{canvas_boundary['min_top']})，右下角({canvas_boundary['max_right']},{canvas_boundary['max_bottom']})

你的主要功能：
1. 移动组件：改变组件的位置和大小
2. 编辑组件：修改组件的内容和名称
3. 删除组件：从画布中删除特定组件
4. 添加组件：在画布上添加新的组件
5. 创建模板：根据用户需求创建特定组合的多个组件

当用户描述操作时，请按以下规则理解和执行：
- 当用户提到"第一个文本框"、"第二个图片"等索引表达时，按列表中显示的顺序确定目标组件
- 当用户使用组件名称时（如"移动'文本框1'"），则按名称匹配
- 当用户描述组件位置时，使用画布坐标系统（左上角为原点0,0）
- 在调整尺寸时，需注意保持组件的可用性和美观性

**智能排版和位置决策**:
- 你需要根据画布当前状态智能决定新组件的放置位置
- 避免与现有组件重叠，保持合理的间距(至少20-30px)
- 根据组件类型决定合适的尺寸(文本框较小，Markdown较大)
- 对相关组件进行分组布局，保持视觉上的关联性
- 确保所有组件都在画布边界内，不要超出边界区域
- 如果画布为空，从左上角(350,100)开始布局
- 如果画布已有组件，则尝试以下策略:
  1. 找出可用的大空间区域，优先放置在其中
  2. 如果相关联，放置在相关组件附近
  3. 对于多个组件，采用自上而下或自左而右的布局逻辑
  4. 文本标题通常放在内容的上方
  5. 图片内容通常置于中部，相应说明在其附近

针对单个组件操作，请按以下JSON格式生成操作指令：
```json
{{
  "action": "move|edit|delete|add",
  "targetType": "text|image|heritage|markdown",
  "targetIndex": 1,  // 组件索引，从1开始计数
  "params": {{
    // 根据action类型提供不同参数
    // 当action为move时：left, top, width, height (所有单位为px)
    // 当action为edit时：对于文本和Markdown是content; 对于图片是imageUrl; 对于所有组件都可以有name
    // 当action为add时：包含位置和内容相关参数
  }}
}}
```

针对多组件添加，请使用以下格式：
```json
{{
  "action": "multi_add",
  "components": [
    {{
      "type": "text|image|heritage|markdown",
      "params": {{
        "name": "组件名称",
        "content": "组件内容", // 或imageUrl, publicTime+items等
        "position": {{
          "left": 100,
          "top": 100,
          "width": 300,
          "height": 200
        }}
      }}
    }},
    // 可以添加更多组件...
  ]
}}
```

例如，创建日记模板的正确格式为：
```json
{{
  "action": "multi_add",
  "components": [
    {{
      "type": "text",
      "params": {{
        "name": "日记标题",
        "content": "我的日记",
        "position": {{
          "left": 350,
          "top": 100,
          "width": 400,
          "height": 50
        }}
      }}
    }},
    {{
      "type": "markdown",
      "params": {{
        "name": "日记内容",
        "content": "# 今天的日记\\n\\n今天发生了很多有趣的事情...",
        "position": {{
          "left": 350,
          "top": 170,
          "width": 500,
          "height": 400
        }}
      }}
    }}
  ]
}}
```

组件尺寸参考值：
- 标题文本框: width=300-400, height=40-60
- 正文文本框: width=400-500, height=80-150
- Markdown编辑器: width=400-600, height=300-500
- 图片: width=300-400, height=200-300
- 遗产信息: width=400-600, height=300-400

可用位置参考值（确保在画布边界内）：
- 起始位置: left=350, top=100
- 左上角区域: left=350, top=100
- 右上角区域: left=650, top=100
- 左下角区域: left=350, top=450
- 右下角区域: left=650, top=450
- 中央位置: left=500, top=300

常见内容模板参考（请直接在components中完整实现）：
1. 日记模板：通常包含标题文本框和Markdown内容编辑器
2. 备忘录模板：通常包含标题和待办事项列表（Markdown）
3. 相册模板：通常包含标题、一个或多个图片组件和描述（Markdown）
4. 时间线模板：通常包含多个按时间顺序排列的Markdown组件
5. 遗产记录模板：通常包含标题、遗产信息组件和说明文档（Markdown）

当用户请求创建特定内容（如"帮我创建一篇日记"），应使用multi_add操作并在components数组中生成完整的组件列表。
根据内容类型和用户需求，自动安排组件的位置和尺寸，确保组件之间的布局合理。

注意：不要使用"create_template"作为action值或使用"templateType"字段，这些格式已被弃用。始终使用"multi_add"操作并提供完整的components数组。

如果用户要求模糊或无法执行（如找不到指定组件），请友好地询问更多细节而不是生成不确定的操作。
如果用户请求无法满足，则不要生成JSON，而是告知用户原因。

请直接用中文回复用户，回复应当清晰解释你将要执行什么操作，然后在回复中包含操作指令的JSON。"""

        return system_prompt
