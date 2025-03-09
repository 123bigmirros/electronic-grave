from flask import Flask, request, jsonify
from flask_cors import CORS
from service.canvas_processor import CanvasProcessor
from service.message_service import MessageService
from service.canvas_message_service import CanvasMessageService
import json
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

app = Flask(__name__)
CORS(app)
processor = CanvasProcessor()
message_service = MessageService(None) 
canvas_message_service = CanvasMessageService()

@app.route('/api/canvas/embedding', methods=['POST'])
def save_embeddings():
    # try:
    data = request.json
    canvas_id = data['canvas_id']
    if not canvas_id:
        return jsonify({"error": "Missing canvas_id"}), 400
        
    success = processor.process_canvas(canvas_id)
    
    if success:
        return jsonify({"message": "Canvas processed successfully"})
    else:
        return jsonify({"error": "Canvas not found"}), 404
            
    # except Exception as e:
    #     print(e)
    return jsonify({"error": str(e)}), 500

@app.route('/api/search', methods=['POST'])
def search():
    # try:
    data = request.json
    query = data.get('query', '')
    user_id = data.get('user_id')  # 从请求中获取user_id
    chat_history = data.get('chat_history', [])
    
    if not processor.global_index:
        return jsonify({"error": "No search index available"}), 404
    
    # 使用向量存储的相似度搜索直接获取相关文档
    docs_with_scores = processor.similarity_search_with_score(
        query,
        k=10,  # 最多返回10个结果
        user_id=user_id  # 传入user_id用于权限控制
    )
    # 过滤掉相似度低于阈值的结果
    SIMILARITY_THRESHOLD = 0  # 相似度阈值
    filtered_docs = [
        (doc, score) for doc, score in docs_with_scores 
        if score >= SIMILARITY_THRESHOLD
    ]
    # 构建响应
    response = {
        "sources": [
            {
                "canvas_id": doc.metadata["canvas_id"],
                "userId": doc.metadata["userId"],
                "title": doc.metadata["title"],
                "similarity_score": float(score),
                "content_preview": doc.page_content[:200] + "..."
            }
            for doc, score in filtered_docs
        ]
    }
    
   
    return jsonify(response)
        


@app.route('/api/canvas/delete-embedding/<int:canvas_id>', methods=['POST'])
def delete_canvas_embedding(canvas_id):
    # try:
    if not canvas_id:
        return jsonify({"error": "Missing canvas_id"}), 400
        
    success = processor.delete_canvas_embedding(canvas_id)
    
    if success:
        return jsonify({"message": "Canvas embedding deleted successfully"})
    else:
        return jsonify({"error": "Canvas embedding not found"}), 404
            
    # except Exception as e:
    #     print(e)
    #     return jsonify({"error": str(e)}), 500




@app.route('/api/chat', methods=['POST'])
def handle_message():
    # try:
    data = request.json
    message_type = data.get('type', 'message')
    
    if message_type == 'canvas_control':
        # 处理画布控制指令
        return handle_canvas_control(data)
    else:
        
        response = message_service.handle_message(data)
        return jsonify(response)
            
    # except Exception as e:
    #     print(f"Error in handle_message: {e}")
    #     return jsonify({"error": str(e)}), 500

def handle_canvas_control(data):
    """处理画布控制请求"""
    user_message = data.get('message', '')
    canvas_summary = data.get('canvas_summary', {})
    history = data.get('history', [])
    
    # 构建系统提示
    system_prompt = create_canvas_control_prompt(canvas_summary)
    
    # 获取历史对话
    formatted_history = []
    for msg in history:
        role = msg.get('role', '')
        content = msg.get('content', '')
        if role and content:
            formatted_history.append({"role": role, "content": content})
    
    # 调用LLM进行处理
    response = canvas_message_service.call_llm_with_prompt(
        system_prompt, 
        user_message, 
        formatted_history
    )
    
    # 解析响应，提取操作指令
    action = extract_action_from_response(response)
    print(action)
    # 从响应中删除JSON代码块
    cleaned_response = remove_json_from_response(response)
    
    return jsonify({
        "answer": cleaned_response,
        "action": action
    })

def remove_json_from_response(response):
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

def create_canvas_control_prompt(canvas_summary):
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
    
    # 组装完整系统提示
    system_prompt = f"""你是一个专业的画布编辑助手，负责理解用户的自然语言指令并将其转换为具体的画布操作。
你的任务是通过对话方式帮助用户调整画布中的组件位置和内容。

当前画布包含以下组件：

{chr(10).join(components_desc)}

你的主要功能：
1. 移动组件：改变组件的位置和大小
2. 编辑组件：修改组件的内容和名称
3. 删除组件：从画布中删除特定组件
4. 添加组件：在画布上添加新的组件

当用户描述操作时，请按以下规则理解和执行：
- 当用户提到"第一个文本框"、"第二个图片"等索引表达时，按列表中显示的顺序确定目标组件
- 当用户使用组件名称时（如"移动'文本框1'"），则按名称匹配
- 当用户描述组件位置时，使用画布坐标系统（左上角为原点0,0）
- 在调整尺寸时，需注意保持组件的可用性和美观性

请按以下JSON格式生成操作指令：
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

常用位置参考值：
- 左上角: left=0, top=0
- 右上角: left=1000, top=0
- 左下角: left=0, top=800
- 右下角: left=1000, top=800
- 中央位置: left=500, top=400

如果用户要求模糊或无法执行（如找不到指定组件），请友好地询问更多细节而不是生成不确定的操作。
如果用户请求无法满足，则不要生成JSON，而是告知用户原因。

请直接用中文回复用户，回复应当清晰解释你将要执行什么操作，然后在回复中包含操作指令的JSON。"""

    return system_prompt

def extract_action_from_response(response):
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

if __name__ == '__main__':
    app.run(debug=True, port=5002, host='0.0.0.0')