from langchain.chat_models import ChatOpenAI
import os
from langchain.schema import (
    SystemMessage,
    HumanMessage,
    AIMessage
)

class CanvasMessageService:
    def __init__(self):
        self.setup_llm()
        
    def setup_llm(self):
        # 设置OpenAI API
        os.environ["OPENAI_API_BASE"] = "https://api.chatanywhere.tech/v1"
        os.environ["OPENAI_API_KEY"] = "sk-CSqSvTCIpuGlKrlCKqySOdr6amRaNFO1TlMPdJKMakL1Iwf4"
        self.llm = ChatOpenAI(temperature=0)
    
    def process_message(self, message, canvas_id=None, history=None):
        """处理用户消息并返回回答"""
        if not history:
            history = []
            
        # 构建历史对话文本
        history_text = self.format_history(history)
        
        # 构建 prompt
        prompt = f"""
        你是一个友好的助手，负责回答用户关于电子墓碑系统的问题。
        请用简洁清晰的中文回答用户的问题。如果你不知道答案，就诚实地说不知道。

        历史对话：
        {history_text}

        用户问题：{message}
        """
        
        # 获取回答
        response = self.llm.predict(prompt)
        
        return {"answer": response}
    
    def call_llm_with_prompt(self, system_prompt, user_message, history=None):
        """使用系统提示和用户消息调用LLM，直接返回文本回答"""
        if not history:
            history = []
            
        # 构建历史对话文本
        history_parts = []
        for msg in history:
            role = msg.get('role', '')
            content = msg.get('content', '')
            if role and content:
                role_name = "用户" if role == "user" else "助手"
                history_parts.append(f"{role_name}: {content}")
        
        history_text = "\n".join(history_parts) if history_parts else "无历史对话"
        
        # 构建完整提示
        prompt = f"""
        {system_prompt}

        历史对话：
        {history_text}

        用户问题：{user_message}
        """
        
        # 调用LLM获取回答
        response = self.llm.predict(prompt)
        
        return response
        
    def format_history(self, history):
        """将历史对话格式化为文本"""
        if not history:
            return "无历史对话"
            
        formatted = []
        for msg in history:
            role = "用户" if msg['type'] == 'user' else "助手"
            formatted.append(f"{role}: {msg['content']}")
        return "\n".join(formatted) 