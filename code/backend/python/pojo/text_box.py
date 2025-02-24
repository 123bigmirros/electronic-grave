from dataclasses import dataclass
from .box_base import BoxBase

@dataclass
class TextBox(BoxBase):
    content: str = "" 