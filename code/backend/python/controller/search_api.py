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
    try:
        data = request.json
        canvas_id = data['canvas_id']
        
        if not canvas_id:
            return jsonify({"error": "Missing canvas_id"}), 400
            
        success = processor.process_canvas(canvas_id)
        
        if success:
            return jsonify({"message": "Canvas processed successfully"})
        else:
            return jsonify({"error": "Canvas not found"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/search', methods=['POST'])
def search():
    try:
        data = request.json
        query = data.get('query', '')
        user_id = data.get('user_id')
        chat_history = data.get('chat_history', [])
        
        # 根据用户ID选择搜索范围
        if user_id and user_id in processor.user_indices:
            vectorstore = processor.user_indices[user_id]
        else:
            vectorstore = processor.global_index
            
        if not vectorstore:
            return jsonify({"error": "No search index available"}), 404
            
        qa_chain = ConversationalRetrievalChain.from_llm(
            ChatOpenAI(temperature=0),
            vectorstore.as_retriever(),
            return_source_documents=True
        )
        
        result = qa_chain({
            "question": query,
            "chat_history": chat_history
        })
        
        response = {
            "answer": result["answer"],
            "sources": [
                {
                    "canvas_id": doc.metadata["canvas_id"],
                    "title": doc.metadata["title"],
                    "created_at": doc.metadata["created_at"]
                }
                for doc in result["source_documents"]
            ]
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 