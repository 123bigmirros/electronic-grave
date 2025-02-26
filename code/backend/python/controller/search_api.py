from flask import Flask, request, jsonify
from flask_cors import CORS
from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationalRetrievalChain
from service.canvas_processor import CanvasProcessor
import os

app = Flask(__name__)
CORS(app)

processor = CanvasProcessor()

@app.route('/api/canvas/embedding', methods=['POST'])
def save_embeddings():
    # try:
    data = request.json
    canvas_id = data['canvas_id']
    print(canvas_id)
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
    print(docs_with_scores)
    # 过滤掉相似度低于阈值的结果
    SIMILARITY_THRESHOLD = 0.5  # 相似度阈值
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
    
    # # 如果需要AI回答，使用ConversationalRetrievalChain
    # if data.get('need_ai_response', False):
    #     qa_chain = ConversationalRetrievalChain.from_llm(
    #         ChatOpenAI(temperature=0),
    #         processor.global_index.as_retriever(
    #             search_kwargs={"user_id": user_id}  # 传入user_id用于权限控制
    #         ),
    #         return_source_documents=True
    #     )
        
    #     result = qa_chain({
    #         "question": query,
    #         "chat_history": chat_history
    #     })
        
    #     response["answer"] = result["answer"]
    return jsonify(response)
        
    # except Exception as e:
    #     print(e)
    #     return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 