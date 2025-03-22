import 'package:flutter/material.dart';
import 'package:electron_application/models/canvas_model.dart';

class TextItem extends StatefulWidget {
  final String content;
  final PositionModel position;
  final bool readonly;
  final Function(String)? onUpdate;
  final Function(PositionModel)? onPositionChange;
  final VoidCallback? onDelete;

  const TextItem({
    Key? key,
    required this.content,
    required this.position,
    this.readonly = false,
    this.onUpdate,
    this.onPositionChange,
    this.onDelete,
  }) : super(key: key);

  @override
  State<TextItem> createState() => _TextItemState();
}

class _TextItemState extends State<TextItem> {
  late String _content;
  late PositionModel _position;
  bool _isEditing = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 拖拽相关
  bool _isDragging = false;
  Offset _startPosition = Offset.zero;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
    _position = widget.position;
    _textController.text = _content;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _stopEditing();
      }
    });
  }

  @override
  void didUpdateWidget(TextItem oldWidget) {
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

  void _startEditing() {
    if (widget.readonly) return;

    setState(() {
      _isEditing = true;
      _textController.text = _content;
    });

    // 延迟一下再获取焦点，确保UI已经更新
    Future.delayed(const Duration(milliseconds: 50), () {
      _focusNode.requestFocus();
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
      _content = _textController.text;
    });

    if (widget.onUpdate != null) {
      widget.onUpdate!(_content);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.readonly) return;

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

  void _onKeyDown(RawKeyEvent event) {
    // 处理键盘事件，例如删除
    if (!widget.readonly && widget.onDelete != null) {
      // 处理删除操作
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取设备类型和尺寸信息
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 480;

    // 计算字体大小系数 - 在Android或小屏幕上使用更大字体
    final fontSizeMultiplier = (isAndroid || isSmallScreen) ? 1.6 : 1.0;
    // 添加垂直间距系数 - 在Android上增加垂直空间
    final verticalSpaceMultiplier = (isAndroid || isSmallScreen) ? 1.2 : 1.0;

    return Positioned(
      left: _position.left,
      top: _position.top,
      child: SizedBox(
        width: _position.width,
        height: _position.height,
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: _onKeyDown,
          child: GestureDetector(
            onTap: _isEditing ? null : _startEditing,
            onPanStart: _onDragStart,
            onPanUpdate: _onDragUpdate,
            onPanEnd: _onDragEnd,
            child: Container(
              padding: EdgeInsets.all(
                  isAndroid ? 16.0 * verticalSpaceMultiplier : 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color:
                      _isEditing ? Colors.blue : Colors.grey.withOpacity(0.3),
                  width: _isEditing ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isEditing
                  ? TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontSize: 20.0 * fontSizeMultiplier,
                        height: 1.3 * verticalSpaceMultiplier,
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (_) => _stopEditing(),
                    )
                  : Text(
                      _content,
                      style: TextStyle(
                        fontSize: 20.0 * fontSizeMultiplier,
                        height: 1.3 * verticalSpaceMultiplier,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.visible,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
