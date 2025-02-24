from dataclasses import dataclass
from .box_base import BoxBase

@dataclass
class ImageBox(BoxBase):
    image_url: str = "" 