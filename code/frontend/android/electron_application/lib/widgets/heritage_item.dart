import 'package:flutter/material.dart';
import 'package:electron_application/models/canvas_model.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:intl/intl.dart';

class HeritageItem extends StatefulWidget {
  final HeritageItemModel heritage;
  final PositionModel position;
  final bool readonly;
  final Function(HeritageItemModel)? onUpdate;
  final Function(PositionModel)? onPositionChange;
  final VoidCallback? onDelete;

  const HeritageItem({
    Key? key,
    required this.heritage,
    required this.position,
    this.readonly = false,
    this.onUpdate,
    this.onPositionChange,
    this.onDelete,
  }) : super(key: key);

  @override
  State<HeritageItem> createState() => _HeritageItemState();
}

class _HeritageItemState extends State<HeritageItem> {
  late HeritageItemModel _heritage;
  late PositionModel _position;
  bool _isEditing = false;

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

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _publicTimeController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _heritage = widget.heritage;
    _position = widget.position;
    _titleController.text = _heritage.title;
    _publicTimeController.text = _dateFormat.format(_heritage.publicTime);
  }

  @override
  void didUpdateWidget(HeritageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heritage != widget.heritage) {
      _heritage = widget.heritage;
      _titleController.text = _heritage.title;
      _publicTimeController.text = _dateFormat.format(_heritage.publicTime);
    }
    if (oldWidget.position != widget.position) {
      _position = widget.position;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _publicTimeController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (widget.readonly) return;
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _titleController.text = _heritage.title;
        _publicTimeController.text = _dateFormat.format(_heritage.publicTime);
      }
    });
  }

  void _saveChanges() {
    final newHeritage = HeritageItemModel(
      title: _titleController.text,
      content: _heritage.content,
      author: _heritage.author,
      position: _heritage.position,
      publicTime:
          DateTime.tryParse(_publicTimeController.text) ?? DateTime.now(),
    );

    setState(() {
      _heritage = newHeritage;
      _isEditing = false;
    });

    if (widget.onUpdate != null) {
      widget.onUpdate!(_heritage);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.readonly || _isEditing) return;

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
    newWidth = newWidth < 150 ? 150 : newWidth;
    newHeight = newHeight < 150 ? 150 : newHeight;

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
            GestureDetector(
              onTap: _isEditing ? null : _toggleEdit,
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Container(
                width: _position.width,
                height: _position.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isEditing
                        ? Colors.blue.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.3),
                    width: _isEditing ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isEditing ? _buildEditor() : _buildDisplay(),
              ),
            ),

            // 调整大小控制点
            if (!widget.readonly && !_isEditing) ...[
              // 左上角
              Positioned(
                left: -5,
                top: -5,
                child: GestureDetector(
                  onPanStart: (details) =>
                      _startResize('topLeft', details.globalPosition),
                  onPanUpdate: (details) =>
                      _onResizeUpdate(details.globalPosition),
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
                  onPanStart: (details) =>
                      _startResize('topRight', details.globalPosition),
                  onPanUpdate: (details) =>
                      _onResizeUpdate(details.globalPosition),
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
                  onPanStart: (details) =>
                      _startResize('bottomLeft', details.globalPosition),
                  onPanUpdate: (details) =>
                      _onResizeUpdate(details.globalPosition),
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
                  onPanStart: (details) =>
                      _startResize('bottomRight', details.globalPosition),
                  onPanUpdate: (details) =>
                      _onResizeUpdate(details.globalPosition),
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

  Widget _buildDisplay() {
    // 获取设备类型和尺寸信息
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 480;

    // 为Android和小屏幕设备增加尺寸
    final sizeFactor = (isAndroid || isSmallScreen) ? 1.5 : 1.0;
    // 添加垂直空间系数 - 增加Android设备上的垂直空间
    final verticalSpaceFactor = (isAndroid || isSmallScreen) ? 1.3 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和删除按钮
        Container(
          padding: EdgeInsets.fromLTRB(
              16.0 * sizeFactor,
              12.0 * sizeFactor * verticalSpaceFactor,
              16.0 * sizeFactor,
              12.0 * sizeFactor * verticalSpaceFactor),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.withOpacity(0.4),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _heritage.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0 * sizeFactor,
                    color: Colors.black87,
                    height: 1.2 * verticalSpaceFactor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.readonly)
                IconButton(
                  icon: Icon(Icons.delete, size: 22.0 * sizeFactor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onDelete,
                  color: Colors.red,
                ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.0 * sizeFactor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 遗产内容
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _heritage.content,
                      style: TextStyle(
                        fontSize: 16.0 * sizeFactor,
                        height: 1.5 * verticalSpaceFactor,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                // 底部信息
                Container(
                  margin: EdgeInsets.only(
                      top: 8.0 * sizeFactor * verticalSpaceFactor),
                  padding: EdgeInsets.only(
                      top: 8.0 * sizeFactor * verticalSpaceFactor),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 作者信息
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16.0 * sizeFactor,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.0 * sizeFactor),
                          Text(
                            _heritage.author,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14.0 * sizeFactor,
                              fontWeight: FontWeight.w500,
                              height: 1.2 * verticalSpaceFactor,
                            ),
                          ),
                        ],
                      ),

                      // 时间信息
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16.0 * sizeFactor,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 4.0 * sizeFactor),
                          Text(
                            _dateFormat.format(_heritage.publicTime),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14.0 * sizeFactor,
                              fontWeight: FontWeight.w500,
                              height: 1.2 * verticalSpaceFactor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '编辑遗产',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _saveChanges,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('保存'),
                  ),
                  TextButton(
                    onPressed: _toggleEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 编辑表单
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 12),

                  // 公开时间
                  TextField(
                    controller: _publicTimeController,
                    decoration: const InputDecoration(
                      labelText: '公开时间',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'YYYY-MM-DD',
                    ),
                    style: const TextStyle(fontSize: 14),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _heritage.publicTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        setState(() {
                          _publicTimeController.text = _dateFormat.format(date);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // 内容编辑
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 5,
                    minLines: 3,
                    controller: TextEditingController(text: _heritage.content),
                    onChanged: (value) {
                      _heritage = HeritageItemModel(
                        title: _heritage.title,
                        content: value,
                        author: _heritage.author,
                        position: _heritage.position,
                        publicTime: _heritage.publicTime,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '编辑遗产',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _saveChanges,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('保存'),
                  ),
                  TextButton(
                    onPressed: _toggleEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 编辑表单
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 12),

                  // 公开时间
                  TextField(
                    controller: _publicTimeController,
                    decoration: const InputDecoration(
                      labelText: '公开时间',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'YYYY-MM-DD',
                    ),
                    style: const TextStyle(fontSize: 14),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _heritage.publicTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        setState(() {
                          _publicTimeController.text = _dateFormat.format(date);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // 内容编辑
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 5,
                    minLines: 3,
                    controller: TextEditingController(text: _heritage.content),
                    onChanged: (value) {
                      _heritage = HeritageItemModel(
                        title: _heritage.title,
                        content: value,
                        author: _heritage.author,
                        position: _heritage.position,
                        publicTime: _heritage.publicTime,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
