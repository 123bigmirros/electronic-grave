from dataclasses import dataclass
from .box_base import BoxBase

@dataclass
class MarkdownBox(BoxBase):
    content: str = "" 