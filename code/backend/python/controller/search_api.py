from flask import Flask, request, jsonify
from flask_cors import CORS
from service.canvas_processor import CanvasProcessor
from service.message_service import MessageService
from service.canvas_message_service import CanvasMessageService
from service.agent_service import AgentService
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
agent_service = AgentService()  # 创建AgentService实例

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
        # 处理画布控制指令，使用AgentService
        result = agent_service.handle_canvas_control(data)
        return jsonify(result)
    else:
        response = message_service.handle_message(data)
        return jsonify(response)
            
    # except Exception as e:
    #     print(f"Error in handle_message: {e}")
    #     return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=False, port=5002, host='0.0.0.0')