from dataclasses import dataclass, field
from datetime import datetime
from typing import List
from .box_base import BoxBase
from .heritage_item import HeritageItem

@dataclass
class Heritage(BoxBase):
    public_time: datetime = None
    items: List[HeritageItem] = field(default_factory=list) 