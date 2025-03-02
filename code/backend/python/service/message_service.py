from flask_socketio import SocketIO, emit
from langchain.chat_models import ChatOpenAI
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
        self.llm = ChatOpenAI(temperature=0)
        
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
            
            # 构建画布内容文本
            canvas_content = self.format_canvas_content(canvas_info.get('canvas_data', {}))
            
            # 构建 prompt
            prompt = f"""
            基于以下画布内容回答用户问题。如果问题与画布内容无关，请告知用户。

            画布内容：
            {canvas_content}

            用户问题：{message}
            """
            
            # 获取回答
            response = self.llm.predict(prompt)
            
            # 更新聊天历史
            self.chat_histories[session_id].append((message, response))
            
            return {"answer": response}
    
    def format_canvas_content(self, canvas_data):
        """将画布数据格式化为文本"""
        content_parts = []
        
        if canvas_data.get('title'):
            content_parts.append(f"标题：{canvas_data['title']}\n")
        
        if canvas_data.get('texts'):
            content_parts.append("文本内容：")
            for text in canvas_data['texts']:
                content_parts.append(text.get('content', ''))
        
        if canvas_data.get('markdowns'):
            content_parts.append("\nMarkdown内容：")
            for markdown in canvas_data['markdowns']:
                content_parts.append(markdown.get('content', ''))
        
        if canvas_data.get('heritages'):
            content_parts.append("\n传承内容：")
            for heritage in canvas_data['heritages']:
                if heritage.get('items'):
                    for item in heritage['items']:
                        content_parts.append(item.get('content', ''))
        
        return "\n".join(content_parts)
