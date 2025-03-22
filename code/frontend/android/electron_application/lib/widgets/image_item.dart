import 'dart:io';
import 'package:flutter/material.dart';
import 'package:electron_application/models/canvas_model.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/utils/http_client.dart';
import 'package:image_picker/image_picker.dart';

class ImageItem extends StatefulWidget {
  final String imageUrl;
  final PositionModel position;
  final bool readonly;
  final Function(String)? onUpdateImage;
  final Function(PositionModel)? onPositionChange;
  final VoidCallback? onDelete;

  const ImageItem({
    Key? key,
    required this.imageUrl,
    required this.position,
    this.readonly = false,
    this.onUpdateImage,
    this.onPositionChange,
    this.onDelete,
  }) : super(key: key);

  @override
  State<ImageItem> createState() => _ImageItemState();
}

class _ImageItemState extends State<ImageItem> {
  late String _imageUrl;
  late PositionModel _position;
  bool _isUploading = false;
  final HttpClient _httpClient = HttpClient();
  final ImagePicker _imagePicker = ImagePicker();

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
    _imageUrl = widget.imageUrl;
    _position = widget.position;
  }

  @override
  void didUpdateWidget(ImageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageUrl = widget.imageUrl;
    }
    if (oldWidget.position != widget.position) {
      _position = widget.position;
    }
  }

  // 打开图片选择器
  Future<void> _pickImage() async {
    if (widget.readonly) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        await _uploadImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint('图片选择失败: $e');
    }
  }

  // 上传图片
  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final response = await _httpClient.uploadFile(
        ApiEndpoints.uploadImage,
        imagePath,
      );

      if (response['code'] == 1 && response['data'] != null) {
        final String path = response['data']['path'];
        final String fullUrl = '${ApiEndpoints.baseUrl}$path';

        setState(() {
          _imageUrl = fullUrl;
        });

        if (widget.onUpdateImage != null) {
          widget.onUpdateImage!(fullUrl);
        }
      } else {
        _showErrorSnackBar('图片上传失败: ${response['msg'] ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorSnackBar('图片上传错误: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 开始拖拽
  void _onDragStart(DragStartDetails details) {
    if (widget.readonly) return;

    setState(() {
      _isDragging = true;
      _startPosition = details.globalPosition;
      _dragOffset = Offset.zero;
    });
  }

  // 拖拽过程
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

  // 拖拽结束
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
    newWidth = newWidth < 50 ? 50 : newWidth;
    newHeight = newHeight < 50 ? 50 : newHeight;

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
            // 主体图片
            GestureDetector(
              onTap: widget.readonly ? null : _pickImage,
              onPanStart: _onDragStart,
              onPanUpdate: _onDragUpdate,
              onPanEnd: _onDragEnd,
              child: Container(
                width: _position.width,
                height: _position.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child:
                    _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            _imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text(
                                      '图片加载失败',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
              ),
            ),

            // 如果不是只读模式，添加调整大小的控制点
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
}
