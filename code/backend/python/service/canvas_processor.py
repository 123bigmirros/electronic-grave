from langchain.text_splitter import CharacterTextSplitter
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain.vectorstores import FAISS
from langchain.schema import Document
import os
import json
import pickle
from mapper.canvas_repository import CanvasRepository


class CanvasProcessor:
    def __init__(self):
        self.db_config = {
            'host': 'localhost',
            'user': 'root',
            'password': 'root',
            'database': 'grave'
        }
        self.canvas_repository = CanvasRepository(self.db_config)
        self.embeddings = OpenAIEmbeddings()
        self.canvas_doc_mapping = {}  # 存储 canvas_id 到 doc_ids 的映射
        
        # 初始化或加载FAISS索引
        self.load_or_init_indices()

    def load_or_init_indices(self):
        try:
            self.global_index = FAISS.load_local("faiss_indices/global_index", self.embeddings)
            # 加载映射关系
            if os.path.exists("faiss_indices/canvas_mapping.pkl"):
                with open("faiss_indices/canvas_mapping.pkl", "rb") as f:
                    self.canvas_doc_mapping = pickle.load(f)
        except:
            self.global_index = None

    def process_canvas(self, canvas_id: int) -> bool:
        # 获取画布内容并创建embedding文档
        document = self.canvas_repository.get_canvas_content_for_embedding(canvas_id)
        if not document:
            return False
            
        # 更新索引
        self._update_indices(canvas_id, document)
        return True

    def _update_indices(self, canvas_id: int, doc: Document):
        # 如果索引不存在，创建新索引
        if self.global_index is None:
            self.global_index = FAISS.from_documents([doc], self.embeddings)
            # 保存文档ID映射
            doc_ids = [list(self.global_index.docstore._dict.keys())[0]]
            self.canvas_doc_mapping[canvas_id] = doc_ids
            self._save_indices()
            return

        # 删除旧的文档
        if canvas_id in self.canvas_doc_mapping:
            old_doc_ids = self.canvas_doc_mapping[canvas_id]
            try:
                # 直接使用文档ID进行删除，而不是Document对象
                self.global_index.delete(old_doc_ids)
            except Exception as e:
                print(f"删除embedding时出错: {str(e)}")
        
        # 添加新文档
        current_doc_count = len(self.global_index.docstore._dict)
        self.global_index.add_documents([doc])
        # 获取新添加的文档ID
        new_doc_ids = [list(self.global_index.docstore._dict.keys())[current_doc_count]]
        self.canvas_doc_mapping[canvas_id] = new_doc_ids
                
        # 保存索引和映射
        self._save_indices()

    def _save_indices(self):
        if self.global_index:
            os.makedirs("faiss_indices", exist_ok=True)
            self.global_index.save_local("faiss_indices/global_index")
            # 保存映射关系
            with open("faiss_indices/canvas_mapping.pkl", "wb") as f:
                pickle.dump(self.canvas_doc_mapping, f)

    def similarity_search_with_score(self, query: str, k: int = 10, user_id: str = None):
        """
        执行相似度搜索并返回文档及其相似度分数，同时进行权限控制
        
        Args:
            query (str): 搜索查询文本
            k (int): 返回结果的最大数量
            user_id (str): 当前用户ID，用于权限控制
            
        Returns:
            List[Tuple[Document, float]]: 包含文档和相似度分数的列表
        """
        if not self.global_index:
            return []
        
        # 获取所有匹配的文档
        docs_with_scores = self.global_index.similarity_search_with_score(query, k=k)
        # print(docs_with_scores)
        # 根据权限过滤文档
        # print(docs_with_scores)
        filtered_docs = []
        for doc, score in docs_with_scores:
            # 如果文档是公开的，或者用户是文档的所有者，则允许访问
            if doc.metadata.get("isPublic", 1) or doc.metadata.get("userId") == user_id:
                filtered_docs.append((doc, score))
            
            # 如果已经收集了足够的文档，就停止
            if len(filtered_docs) >= k:
                break
        # print(filtered_docs)
        return filtered_docs 

    def delete_canvas_embedding(self, canvas_id: int) -> bool:
        """
        删除指定画布的embedding
        
        Args:
            canvas_id (int): 要删除的画布ID
            
        Returns:
            bool: 删除是否成功
        """
        try:
            if not self.global_index or canvas_id not in self.canvas_doc_mapping:
                return False
                
            # 获取要删除的文档ID
            old_doc_ids = self.canvas_doc_mapping[canvas_id]
            
            # 直接使用文档ID进行删除，而不是Document对象
            self.global_index.delete(old_doc_ids)
            
            # 从映射中删除记录
            del self.canvas_doc_mapping[canvas_id]
            
            # 保存更新后的索引和映射
            self._save_indices()
            
            return True
        except Exception as e:
            print(f"删除embedding时出错: {str(e)}")
            return False 