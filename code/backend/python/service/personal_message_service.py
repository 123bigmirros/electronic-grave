from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationalRetrievalChain
from langchain.chains.qa_with_sources import load_qa_with_sources_chain
from langchain.chains.conversational_retrieval.prompts import CONDENSE_QUESTION_PROMPT
from langchain.llms import OpenAI
import os

class PersonalMessageService:
    def __init__(self, canvas_processor):
        self.setup_llm()
        self.canvas_processor = canvas_processor
        
    def setup_llm(self):
        # 设置OpenAI API
        self.llm = ChatOpenAI(temperature=0)
        
    def handle_message(self, data):
        message_type = data.get('type')
        user_id = data.get('user_id')
        history = data.get('history', [])  # 从请求中获取历史记录
        
        if message_type == 'init':
            return {"answer": "您好！我是您的个人助手，可以帮您检索和回答关于您所有创作内容的问题。请问有什么可以帮您？"}
            
        elif message_type == 'message':
            # 处理普通消息
            message = data.get('message')
            
            # 构建历史对话文本
            history_text = self.format_history(history)
            
            # 使用RAG检索相关文档
            docs_with_scores = self.canvas_processor.similarity_search_with_score(
                message,
                k=5,  # 最多返回5个结果
                user_id=user_id  # 传入user_id用于权限控制
            )
            
            # 构建检索到的文档内容
            retrieved_content = self.format_retrieved_content(docs_with_scores)
            
            # 构建 prompt
            prompt = f"""
            基于以下检索到的用户创作内容和历史对话回答用户问题。如果问题与检索内容无关，请告知用户。

            检索到的内容：
            {retrieved_content}

            历史对话：
            {history_text}

            用户问题：{message}
            """
            
            # 获取回答
            response = self.llm.predict(prompt)
            
            # 构建返回的源文档信息
            sources = []
            for doc, score in docs_with_scores:
                source = {
                    "canvas_id": doc.metadata.get("canvas_id"),
                    "title": doc.metadata.get("title", "无标题"),
                    "similarity_score": float(score)
                }
                sources.append(source)
            
            return {
                "answer": response,
                "sources": sources
            }
    
    def format_history(self, history):
        """将历史对话格式化为文本"""
        if not history:
            return "无历史对话"
            
        formatted = []
        for msg in history:
            role = "用户" if msg['type'] == 'user' else "助手"
            formatted.append(f"{role}: {msg['content']}")
        return "\n".join(formatted)
    
    def format_retrieved_content(self, docs_with_scores):
        """将检索到的文档格式化为文本"""
        if not docs_with_scores:
            return "未找到相关内容"
            
        formatted = []
        for i, (doc, score) in enumerate(docs_with_scores):
            title = doc.metadata.get("title", "无标题")
            formatted.append(f"文档 {i+1} (相似度: {score:.2f}):")
            formatted.append(f"标题: {title}")
            formatted.append("---")
            
        return "\n".join(formatted) 