from flask_socketio import SocketIO, emit
from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationalRetrievalChain
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain.vectorstores import FAISS
from langchain.schema import Document
import json
import os

class MessageService:
    def __init__(self, socketio):
        self.socketio = socketio
        self.chat_histories = {}  # 存储每个用户的聊天历史
        self.canvas_data = {}     # 存储每个会话的画布数据
        self.setup_llm()
        
    def setup_llm(self):
        # 设置OpenAI API
        os.environ["OPENAI_API_BASE"] = "https://api.chatanywhere.tech/v1"
        os.environ["OPENAI_API_KEY"] = "sk-X6qmvKSqTxaeFIrmq9v2KlAN6QJEKwxi6eGX5ads7wYERbx0"
        
        # 初始化embeddings和模型
        self.embeddings = OpenAIEmbeddings()
        self.llm = ChatOpenAI(temperature=0)
        
    def load_canvas_data(self, canvas_id):
        # 这里需要实现从数据库加载画布数据并创建向量存储
        # 示例代码，需要根据实际情况修改
        docs = []  # 从数据库加载的文档
        return FAISS.from_documents(docs, self.embeddings)
        
    def handle_message(self, data):
        message_type = data.get('type')
        session_id = data.get('session_id')
        
        if message_type == 'init':
            # 处理初始化消息，存储画布数据
            self.canvas_data[session_id] = {
                'canvas_id': data.get('canvas_id'),
                'canvas_data': data.get('canvas_data')
            }
            return {"answer": "画布数据已加载，请问有什么可以帮您？"}
            
        elif message_type == 'message':
            # 处理普通消息
            message = data.get('message')
            canvas_info = self.canvas_data.get(session_id, {})
            
            if not session_id in self.chat_histories:
                self.chat_histories[session_id] = []
                
            # 使用画布数据创建向量存储
            vectorstore = self.create_vectorstore_from_canvas(canvas_info.get('canvas_data', {}))
            
            # 创建对话链
            qa_chain = ConversationalRetrievalChain.from_llm(
                self.llm,
                vectorstore.as_retriever(),
                return_source_documents=True
            )
            
            # 获取回答
            result = qa_chain({
                "question": message,
                "chat_history": self.chat_histories[session_id]
            })
            
            # 更新聊天历史
            self.chat_histories[session_id].append((message, result["answer"]))
            
            return {
                "answer": result["answer"],
                "sources": [doc.metadata.get("source") for doc in result["source_documents"]]
            }
            
    def create_vectorstore_from_canvas(self, canvas_data):
        # 将画布数据转换为文档格式
        docs = []
        
        if canvas_data.get('title'):
            docs.append(Document(
                page_content=f"Title: {canvas_data['title']}",
                metadata={"type": "title"}
            ))
            
        for text in canvas_data.get('texts', []):
            docs.append(Document(
                page_content=text.get('content', ''),
                metadata={"type": "text"}
            ))
            
        for markdown in canvas_data.get('markdowns', []):
            docs.append(Document(
                page_content=markdown.get('content', ''),
                metadata={"type": "markdown"}
            ))
            
        for heritage in canvas_data.get('heritages', []):
            if heritage.get('items'):
                for item in heritage['items']:
                    docs.append(Document(
                        page_content=item.get('content', ''),
                        metadata={"type": "heritage"}
                    ))
        
        return FAISS.from_documents(docs, self.embeddings)
