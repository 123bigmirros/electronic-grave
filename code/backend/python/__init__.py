# 这使得 python 目录成为一个 Python 包
from .controller import search_api
from .service import canvas_processor
from .pojo import box_base, position, text_box, image_box, markdown_box, heritage_item, heritage, canvas
from .mapper import canvas_repository