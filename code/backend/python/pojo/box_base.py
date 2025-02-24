from dataclasses import dataclass
from .position import Position

@dataclass
class BoxBase:
    id: int
    pid: int  # 用户ID
    left: int = 0
    top: int = 0
    width: int = 0
    height: int = 0

    def set_position(self, position: Position):
        self.left = position.left
        self.top = position.top
        self.width = position.width
        self.height = position.height 