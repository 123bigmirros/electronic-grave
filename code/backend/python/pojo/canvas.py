from dataclasses import dataclass, field
from typing import List
from datetime import datetime
from .text_box import TextBox
from .image_box import ImageBox
from .heritage import Heritage
from .markdown_box import MarkdownBox

@dataclass
class Canvas:
    id: int
    user_id: int
    title: str
    is_public: bool
    images: List[ImageBox] = field(default_factory=list)
    texts: List[TextBox] = field(default_factory=list)
    heritages: List[Heritage] = field(default_factory=list)
    markdowns: List[MarkdownBox] = field(default_factory=list)

    def to_document(self):
        from langchain.schema import Document
        
        text_content = []
        for text in self.texts:
            text_content.append(text["content"])
        for md in self.markdowns:
            text_content.append(md["content"])
            
        return Document(
            page_content="\n".join(text_content),
            metadata={
                "canvas_id": self.id,
                "user_id": self.user_id,
                "title": self.title,
                "created_at": self.created_at.isoformat(),
                "is_public": self.is_public
            }
        )