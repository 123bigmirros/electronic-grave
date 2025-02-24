from typing import Optional, List, Dict
import mysql.connector
from datetime import datetime
from langchain.schema import Document
from pojo.canvas import Canvas
from pojo.text_box import TextBox
from pojo.image_box import ImageBox
from pojo.heritage import Heritage
from pojo.markdown_box import MarkdownBox
from pojo.heritage_item import HeritageItem

class CanvasRepository:
    def __init__(self, db_config):
        self.db_config = db_config

    def get_canvas_by_id(self, canvas_id: int) -> Optional[Canvas]:
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor(dictionary=True)
        
        try:
            # 获取画布基本信息
            cursor.execute("""
                SELECT c.*, u.username 
                FROM canvas c
                JOIN users u ON c.user_id = u.id
                WHERE c.id = %s
            """, (canvas_id,))
            canvas_data = cursor.fetchone()
            
            if not canvas_data:
                return None
                
            canvas = Canvas(
                id=canvas_data['id'],
                user_id=canvas_data['user_id'],
                title=canvas_data['title'],
                created_at=canvas_data['created_at'],
                is_public=canvas_data['is_public'],
                username=canvas_data['username']
            )
            
            # 获取所有组件
            canvas.texts = self._get_text_boxes(cursor, canvas_id)
            canvas.images = self._get_image_boxes(cursor, canvas_id)
            canvas.heritages = self._get_heritages(cursor, canvas_id)
            canvas.markdowns = self._get_markdown_boxes(cursor, canvas_id)
            
            return canvas
            
        finally:
            cursor.close()
            conn.close()

    def _get_text_boxes(self, cursor, canvas_id) -> List[TextBox]:
        cursor.execute("""
            SELECT * FROM text_box WHERE pid = %s
        """, (canvas_id,))
        return [TextBox(
            id=row['id'],
            pid=row['pid'],
            content=row['content'],
            left=row['left'],
            top=row['top'],
            width=row['width'],
            height=row['height']
        ) for row in cursor.fetchall()]

    def _get_image_boxes(self, cursor, canvas_id) -> List[ImageBox]:
        cursor.execute("""
            SELECT * FROM image_box WHERE pid = %s
        """, (canvas_id,))
        return [ImageBox(
            id=row['id'],
            pid=row['pid'],
            image_url=row['image_url'],
            left=row['left'],
            top=row['top'],
            width=row['width'],
            height=row['height']
        ) for row in cursor.fetchall()]

    def _get_heritages(self, cursor, canvas_id) -> List[Heritage]:
        cursor.execute("""
            SELECT * FROM heritage WHERE pid = %s
        """, (canvas_id,))
        heritages = []
        for row in cursor.fetchall():
            heritage = Heritage(
                id=row['id'],
                pid=row['pid'],
                public_time=row['public_time'],
                left=row['left'],
                top=row['top'],
                width=row['width'],
                height=row['height']
            )
            heritage.items = self._get_heritage_items(cursor, heritage.id)
            heritages.append(heritage)
        return heritages

    def _get_heritage_items(self, cursor, heritage_id) -> List[HeritageItem]:
        cursor.execute("""
            SELECT * FROM heritage_item WHERE heritage_id = %s
        """, (heritage_id,))
        return [HeritageItem(
            id=row['id'],
            heritage_id=row['heritage_id'],
            content=row['content'],
            is_private=row['is_private'],
            user_id=row['user_id']
        ) for row in cursor.fetchall()]

    def _get_markdown_boxes(self, cursor, canvas_id) -> List[MarkdownBox]:
        cursor.execute("""
            SELECT * FROM markdown_box WHERE pid = %s
        """, (canvas_id,))
        return [MarkdownBox(
            id=row['id'],
            pid=row['pid'],
            content=row['content'],
            left=row['left'],
            top=row['top'],
            width=row['width'],
            height=row['height']
        ) for row in cursor.fetchall()]

    def get_canvas_content_for_embedding(self, canvas_id: int) -> Optional[Document]:
        """
        获取画布的所有文本内容用于创建embedding
        返回一个Document对象，包含所有文本内容和metadata
        """
        canvas = self.get_canvas_by_id(canvas_id)
        if not canvas:
            return None

        # 收集所有文本内容
        text_contents = []
        
        # 添加普通文本框的内容
        for text_box in canvas.texts:
            text_contents.append('text_box:'+text_box.content)
        
        # 添加Markdown内容
        for markdown_box in canvas.markdowns:
            text_contents.append('markdown_box:'+markdown_box.content)
        
        # 添加遗产内容
        for heritage in canvas.heritages:
            for item in heritage.items:
                text_contents.append('heritage_item:'+item.content)
        
        # 合并所有文本
        combined_text = "\n".join(filter(None, text_contents))
        
        # 创建Document对象
        return Document(
            page_content=combined_text,
            metadata={
                "canvas_id": canvas_id,
                "user_id": canvas.user_id,
                "title": canvas.title,
                "is_public": canvas.is_public
            }
        )