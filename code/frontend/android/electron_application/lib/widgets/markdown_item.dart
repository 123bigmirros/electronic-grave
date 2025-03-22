import 'package:flutter/material.dart';
import 'package:electron_application/models/canvas_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownItem extends StatefulWidget {
  final String content;
  final PositionModel position;
  final bool readonly;
  final Function(String)? onUpdate;
  final Function(PositionModel)? onPositionChange;
  final VoidCallback? onDelete;

  const MarkdownItem({
    Key? key,
    required this.content,
    required this.position,
    this.readonly = false,
    this.onUpdate,
    this.onPositionChange,
    this.onDelete,
  }) : super(key: key);

  @override
  State<MarkdownItem> createState() => _MarkdownItemState();
}

class _MarkdownItemState extends State<MarkdownItem> {
  late String _content;
  late PositionModel _position;
  bool _isEditing = false;
  bool _isPreview = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 拖拽相关
  bool _isDragging = false;
  Offset _startPosition = Offset.zero;
  Offset _dragOffset = Offset.zero;

  // 调整大小相关
  bool _isResizing = false;
  String _resizeHandle = '';
  double _initialWidth = 0;
  double _initialHeight = 0;
  double _initialLeft = 0;
  double _initialTop = 0;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
    _position = widget.position;
    _textController.text = _content;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing && !_isPreview) {
        _updateContent();
      }
    });
  }

  @override
  void didUpdateWidget(MarkdownItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _content = widget.content;
      _textController.text = _content;
    }
    if (oldWidget.position != widget.position) {
      _position = widget.position;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _editMarkdown() {
    if (widget.readonly) return;
    setState(() {
      _isEditing = true;
      _isPreview = false;
      _textController.text = _content;
    });

    // 延迟获取焦点，确保UI更新完成
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
    });
  }

  void _togglePreview() {
    setState(() {
      _isPreview = !_isPreview;
    });
  }

  void _updateContent() {
    final newContent = _textController.text;
    setState(() {
      _content = newContent;
    });

    if (widget.onUpdate != null) {
      widget.onUpdate!(newContent);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.readonly || (_isEditing && !_isPreview)) return;

    setState(() {
      _isDragging = true;
      _startPosition = details.globalPosition;
      _dragOffset = Offset.zero;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || widget.readonly) return;

    setState(() {
      _dragOffset = details.globalPosition - _startPosition;
      _position = PositionModel(
        left: _position.left + details.delta.dx,
        top: _position.top + details.delta.dy,
        width: _position.width,
        height: _position.height,
        zIndex: _position.zIndex,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging || widget.readonly) return;

    setState(() {
      _isDragging = false;
    });

    if (widget.onPositionChange != null) {
      widget.onPositionChange!(_position);
    }
  }

  // 开始调整大小
  void _startResize(String handle, Offset position) {
    if (widget.readonly) return;

    setState(() {
      _isResizing = true;
      _resizeHandle = handle;
      _initialWidth = _position.width;
      _initialHeight = _position.height;
      _initialLeft = _position.left;
      _initialTop = _position.top;
      _startPosition = position;
    });
  }

  // 调整大小过程
  void _onResizeUpdate(Offset position) {
    if (!_isResizing || widget.readonly) return;

    final dx = position.dx - _startPosition.dx;
    final dy = position.dy - _startPosition.dy;

    double newWidth = _initialWidth;
    double newHeight = _initialHeight;
    double newLeft = _initialLeft;
    double newTop = _initialTop;

    switch (_resizeHandle) {
      case 'bottomRight':
        newWidth = _initialWidth + dx;
        newHeight = _initialHeight + dy;
        break;
      case 'bottomLeft':
        newWidth = _initialWidth - dx;
        newLeft = _initialLeft + dx;
        newHeight = _initialHeight + dy;
        break;
      case 'topRight':
        newWidth = _initialWidth + dx;
        newHeight = _initialHeight - dy;
        newTop = _initialTop + dy;
        break;
      case 'topLeft':
        newWidth = _initialWidth - dx;
        newHeight = _initialHeight - dy;
        newLeft = _initialLeft + dx;
        newTop = _initialTop + dy;
        break;
    }

    // 确保大小不小于最小值
    newWidth = newWidth < 100 ? 100 : newWidth;
    newHeight = newHeight < 100 ? 100 : newHeight;

    setState(() {
      _position = PositionModel(
        left: newLeft,
        top: newTop,
        width: newWidth,
        height: newHeight,
        zIndex: _position.zIndex,
      );
    });
  }

  // 调整大小结束
  void _stopResize() {
    if (!_isResizing || widget.readonly) return;

    setState(() {
      _isResizing = false;
    });

    if (widget.onPositionChange != null) {
      widget.onPositionChange!(_position);
    }
  }

  // 处理Tab键
  void _handleKeyPress(RawKeyEvent event) {
    // 实现Tab键处理逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.left,
      top: _position.top,
      child: SizedBox(
        width: _position.width,
        height: _position.height,
        child: Stack(
          children: [
            // 主体容器
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color:
                      _isEditing
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow:
                    _isEditing
                        ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                children: [
                  // 编辑模式下显示标题栏
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Markdown',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _togglePreview,
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isPreview ? '编辑' : '预览',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  _updateContent();
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  '完成',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // 内容区域
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          !_isEditing && !widget.readonly
                              ? _editMarkdown
                              : null,
                      onPanStart: _onDragStart,
                      onPanUpdate: _onDragUpdate,
                      onPanEnd: _onDragEnd,
                      child: Container(
                        width: _position.width,
                        height:
                            _isEditing
                                ? _position.height - 30
                                : _position.height, // 编辑模式减去标题栏高度
                        padding: const EdgeInsets.all(8),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 调整大小控制点
            if (!widget.readonly) ...[
              // 左上角
              Positioned(
                left: -5,
                top: -5,
                child: GestureDetector(
                  onPanStart:
                      (details) =>
                          _startResize('topLeft', details.globalPosition),
                  onPanUpdate:
                      (details) => _onResizeUpdate(details.globalPosition),
                  onPanEnd: (_) => _stopResize(),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),

              // 右上角
              Positioned(
                right: -5,
                top: -5,
                child: GestureDetector(
                  onPanStart:
                      (details) =>
                          _startResize('topRight', details.globalPosition),
                  onPanUpdate:
                      (details) => _onResizeUpdate(details.globalPosition),
                  onPanEnd: (_) => _stopResize(),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),

              // 左下角
              Positioned(
                left: -5,
                bottom: -5,
                child: GestureDetector(
                  onPanStart:
                      (details) =>
                          _startResize('bottomLeft', details.globalPosition),
                  onPanUpdate:
                      (details) => _onResizeUpdate(details.globalPosition),
                  onPanEnd: (_) => _stopResize(),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),

              // 右下角
              Positioned(
                right: -5,
                bottom: -5,
                child: GestureDetector(
                  onPanStart:
                      (details) =>
                          _startResize('bottomRight', details.globalPosition),
                  onPanUpdate:
                      (details) => _onResizeUpdate(details.globalPosition),
                  onPanEnd: (_) => _stopResize(),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isEditing && !_isPreview) {
      return RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyPress,
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: '输入Markdown内容...',
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      );
    } else {
      return Markdown(
        data: _content,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          p: const TextStyle(fontSize: 14),
          code: const TextStyle(
            fontSize: 12,
            backgroundColor: Color(0xFFf5f5f5),
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFFf5f5f5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }
  }
}
