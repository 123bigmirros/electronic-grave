from langchain.text_splitter import CharacterTextSplitter
from langchain.embeddings.openai import OpenAIEmbeddings
from langchain.vectorstores import FAISS
from langchain.schema import Document
import os
import json
import pickle
from mapper.canvas_repository import CanvasRepository

os.environ["OPENAI_API_BASE"] = "https://api.chatanywhere.tech/v1"
os.environ["OPENAI_API_KEY"] = "sk-X6qmvKSqTxaeFIrmq9v2KlAN6QJEKwxi6eGX5ads7wYERbx0"

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
            docs_to_delete = [self.global_index.docstore._dict[doc_id] for doc_id in old_doc_ids]
            if docs_to_delete:
                self.global_index.delete(docs_to_delete)
        
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