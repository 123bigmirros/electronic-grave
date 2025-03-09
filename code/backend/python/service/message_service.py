from langchain.chat_models import ChatOpenAI
import os

class MessageService:
    def __init__(self, _):  # 保留参数但不使用
        self.setup_llm()
        
    def setup_llm(self):
        # 设置OpenAI API
        os.environ["OPENAI_API_BASE"] = "https://api.chatanywhere.tech/v1"
        os.environ["OPENAI_API_KEY"] = "sk-CSqSvTCIpuGlKrlCKqySOdr6amRaNFO1TlMPdJKMakL1Iwf4"
        self.llm = ChatOpenAI(temperature=0)
        
    def handle_message(self, data):
        message_type = data.get('type')
        canvas_data = data.get('canvas_data', {})
        history = data.get('history', [])  # 从请求中获取历史记录
        
        if message_type == 'init':
            return {"answer": "画布数据已加载，请问有什么可以帮您？"}
            
        elif message_type == 'message':
            # 处理普通消息
            message = data.get('message')
            
            # 构建画布内容文本
            canvas_content = self.format_canvas_content(canvas_data)
            
            # 构建历史对话文本
            history_text = self.format_history(history)
            
            # 构建 prompt
            prompt = f"""
            基于以下画布内容和历史对话回答用户问题。如果问题与画布内容无关，请告知用户。

            画布内容：
            {canvas_content}

            历史对话：
            {history_text}

            用户问题：{message}
            """
            
            # 获取回答
            response = self.llm.predict(prompt)
            
            return {"answer": response}
    
    def format_history(self, history):
        """将历史对话格式化为文本"""
        if not history:
            return "无历史对话"
            
        formatted = []
        for msg in history:
            role = "用户" if msg['type'] == 'user' else "助手"
            formatted.append(f"{role}: {msg['content']}")
        return "\n".join(formatted)
    
    def format_canvas_content(self, canvas_data):
        """将画布数据格式化为文本"""
        if not canvas_data:
            return "无画布数据"
            
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
        
        return "\n".join(content_parts) if content_parts else "无画布内容"
