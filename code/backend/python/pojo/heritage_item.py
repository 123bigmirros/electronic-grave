from dataclasses import dataclass

@dataclass
class HeritageItem:
    id: int
    heritage_id: int
    content: str
    is_private: bool
    user_id: int = 0 