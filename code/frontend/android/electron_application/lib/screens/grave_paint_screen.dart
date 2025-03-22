import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electron_application/providers/auth_provider.dart';
import 'package:electron_application/providers/canvas_provider.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/routes/app_routes.dart';
import 'package:electron_application/widgets/search_box.dart';
import 'package:electron_application/widgets/text_item.dart';
import 'package:electron_application/widgets/image_item.dart';
import 'package:electron_application/widgets/heritage_item.dart';
import 'package:electron_application/widgets/markdown_item.dart';
import 'package:electron_application/models/canvas_model.dart';
import 'package:electron_application/utils/http_client.dart';
import 'dart:convert';

// 添加画布适配工具类
class CanvasAdapter {
  static const double webCanvasWidth = 1920.0; // Vue版本的参考宽度
  static const double webCanvasHeight = 1080.0; // Vue版本的参考高度
  static const double minZoomFactor = 1.5; // 最小放大系数
  static const double maxZoomFactor = 3.5; // 增加最大放大系数
  static const double mobileScreenThreshold = 480.0; // 移动设备屏幕宽度阈值

  // 设置基础缩放系数，用于整体放大所有内容
  static const double baseScaleFactor = 2.5; // 增加基础缩放系数以提高高度

  // 高度额外放大系数，专门用于调整Android设备上的组件高度
  static const double heightEnhancementFactor = 1.2;

  static double getScaleFactor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // 计算宽度和高度的缩放比例
    final widthScale = screenWidth / webCanvasWidth;
    final heightScale = screenHeight / webCanvasHeight;

    // 基础缩放比例，取较小的一个以确保画布完全显示
    double baseScale = widthScale < heightScale ? widthScale : heightScale;

    // 根据屏幕尺寸动态调整放大系数
    double dynamicZoom;
    if (screenWidth <= mobileScreenThreshold || isAndroid) {
      // 小屏幕设备或Android设备使用更大的缩放系数
      dynamicZoom = maxZoomFactor;
    } else {
      // 根据屏幕宽度在最小和最大缩放系数之间插值
      double screenRatio = (screenWidth - mobileScreenThreshold) /
          (1000 - mobileScreenThreshold);
      screenRatio = screenRatio.clamp(0.0, 1.0); // 确保在0到1之间
      dynamicZoom =
          maxZoomFactor - screenRatio * (maxZoomFactor - minZoomFactor);
    }

    // 应用基础缩放系数来放大所有内容
    return baseScale * dynamicZoom * baseScaleFactor;
  }

  // 提供高度缩放增强系数，用于Android设备
  static double getHeightScaleFactor(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return isAndroid ? heightEnhancementFactor : 1.0;
  }

  // 提供文本大小转换方法
  static double getTextScaleFactor(BuildContext context) {
    final scale = getScaleFactor(context);
    // 文本通常需要较小的缩放以避免过大
    return scale * 0.5;
  }

  static Offset webToFlutterPosition(Offset webPosition, BuildContext context) {
    final scale = getScaleFactor(context);
    return Offset(webPosition.dx * scale, webPosition.dy * scale);
  }

  static Offset flutterToWebPosition(
      Offset flutterPosition, BuildContext context) {
    final scale = getScaleFactor(context);
    return Offset(flutterPosition.dx / scale, flutterPosition.dy / scale);
  }

  static Size webToFlutterSize(Size webSize, BuildContext context) {
    final scale = getScaleFactor(context);
    final heightScale = getHeightScaleFactor(context);
    return Size(webSize.width * scale, webSize.height * scale * heightScale);
  }

  static Size flutterToWebSize(Size flutterSize, BuildContext context) {
    final scale = getScaleFactor(context);
    final heightScale = getHeightScaleFactor(context);
    return Size(
        flutterSize.width / scale, flutterSize.height / (scale * heightScale));
  }
}

// 添加网格背景绘制器
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    // 调整网格间距和线条粗细
    final minorGridSize = devicePixelRatio > 2.0 ? 75.0 : 50.0;
    final majorGridSize = devicePixelRatio > 2.0 ? 300.0 : 200.0;

    // 次网格线
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = devicePixelRatio > 2.0 ? 1.0 : 0.8;

    // 主网格线
    final majorPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = devicePixelRatio > 2.0 ? 1.5 : 1.2;

    // 绘制垂直次要网格线
    for (double i = 0; i < size.width; i += minorGridSize) {
      // 是否为主网格线
      final isMajor =
          (i / minorGridSize) % (majorGridSize / minorGridSize) == 0;

      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        isMajor ? majorPaint : paint,
      );
    }

    // 绘制水平次要网格线
    for (double i = 0; i < size.height; i += minorGridSize) {
      // 是否为主网格线
      final isMajor =
          (i / minorGridSize) % (majorGridSize / minorGridSize) == 0;

      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        isMajor ? majorPaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}

class GravePaintScreen extends StatefulWidget {
  final String? canvasId;

  const GravePaintScreen({Key? key, this.canvasId}) : super(key: key);

  @override
  State<GravePaintScreen> createState() => _GravePaintScreenState();
}

class _GravePaintScreenState extends State<GravePaintScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _toolbarScrollController = ScrollController();
  bool _isPublic = true;
  bool _isSaving = false;
  String _selectedTool = '';
  bool _showChatInput = false;
  bool _isProcessing = false;
  List<Map<String, String>> _chatHistory = [];

  // 添加画布平移控制
  Offset _canvasOffset = Offset.zero;
  bool _isDraggingCanvas = false;
  Offset _lastDragPosition = Offset.zero;
  double _canvasScale = 1.0; // 增加画布缩放控制
  double _minScale = 0.8;
  double _maxScale = 1.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 检查用户是否登录
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }

      if (widget.canvasId != null && widget.canvasId != '-1') {
        // 编辑已有画布
        await _loadCanvasData();
      } else {
        // 新建画布，清空当前画布状态
        Provider.of<CanvasProvider>(context, listen: false)
            .clearCurrentCanvas();
        _titleController.text = '新画布';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _chatController.dispose();
    _toolbarScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCanvasData() async {
    try {
      final canvasProvider =
          Provider.of<CanvasProvider>(context, listen: false);
      await canvasProvider.getCanvas(widget.canvasId!, isEditing: true);

      if (canvasProvider.currentCanvas != null && mounted) {
        setState(() {
          _titleController.text = canvasProvider.currentCanvas!.title;
          _isPublic = canvasProvider.currentCanvas!.isPublic;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载画布失败')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载画布出错：$e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveCanvas() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入画布标题')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final canvasProvider =
          Provider.of<CanvasProvider>(context, listen: false);
      final canvas = canvasProvider.currentCanvas ?? CanvasModel.empty();

      // 更新画布标题和公开状态
      canvas.title = _titleController.text.trim();
      canvas.isPublic = _isPublic;

      // 设置画布ID：新建画布使用-1，已存在的画布使用其ID
      canvas.id = widget.canvasId ?? '-1';

      final success = await canvasProvider.saveCanvas(canvas);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画布保存成功！')),
          );
          // 返回上一页（个人主页）
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(canvasProvider.error ?? '保存失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存出错：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addTextItem() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    canvasProvider.addTextItem("新文本");
    setState(() {
      _selectedTool = '';
    });
  }

  void _addImageItem() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    canvasProvider.addImageItem("");
    setState(() {
      _selectedTool = '';
    });
  }

  void _addMarkdownItem() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    canvasProvider.addMarkdownItem("# 新Markdown\n\n内容在这里");
    setState(() {
      _selectedTool = '';
    });
  }

  void _addHeritageItem() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    canvasProvider.addHeritageItem();
    setState(() {
      _selectedTool = '';
    });
  }

  void _toggleChatInput() {
    setState(() {
      _showChatInput = !_showChatInput;
    });

    // 延迟设置焦点，确保对话框已经显示出来
    if (_showChatInput) {
      // 清空现有文本
      _chatController.clear();

      // 更长的延迟确保UI完全渲染
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _chatController.text.isEmpty) {
          // 创建新的焦点节点并请求焦点
          final FocusNode focusNode = FocusNode();
          FocusScope.of(context).requestFocus(focusNode);
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty || _isProcessing) return;

    final message = _chatController.text;
    setState(() {
      _isProcessing = true;
    });

    try {
      // 准备画布摘要信息
      final canvasSummary = _prepareCanvasSummary();

      // 添加用户消息到历史记录
      _chatHistory.add({'role': 'user', 'content': message});

      print('发送消息: $message');
      print('画布摘要: $canvasSummary');

      // 发送请求到后端
      final response = await HttpClient().post(
        '/api/chat',
        data: {
          'type': 'canvas_control',
          'message': message,
          'history': _chatHistory,
          'canvas_summary': canvasSummary
        },
        usePythonServer: true,
      );

      print('接收响应: $response');

      // 获取响应数据
      final Map responseData = response is Map ? response : {};
      final String answer = responseData['answer']?.toString() ?? '无法解析回答';

      // 添加AI回复到历史记录
      _chatHistory.add({'role': 'assistant', 'content': answer});

      // 显示AI回复作为SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(answer)),
        );
      }

      // 简化处理AI返回的action
      if (responseData.containsKey('action')) {
        print('处理操作: ${responseData['action']}');
        _executeAction(responseData['action']);
      }

      // 关闭对话输入框并清空内容
      setState(() {
        _showChatInput = false;
        _chatController.clear();
      });
    } catch (error) {
      print('错误详情: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理消息失败: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Map<String, dynamic> _prepareCanvasSummary() {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final canvas = canvasProvider.currentCanvas;

    if (canvas == null) return {};

    return {
      'texts': canvas.texts.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return {
          'id': 'text-${index + 1}',
          'index': index + 1,
          'name': '文本框${index + 1}',
          'content': item.content,
          'position': {
            'left': item.position.left,
            'top': item.position.top,
            'width': item.position.width,
            'height': item.position.height,
          },
        };
      }).toList(),
      'images': canvas.images.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return {
          'id': 'img-${index + 1}',
          'index': index + 1,
          'name': '图片${index + 1}',
          'imageUrl': item.content,
          'position': {
            'left': item.position.left,
            'top': item.position.top,
            'width': item.position.width,
            'height': item.position.height,
          },
        };
      }).toList(),
      'heritages': canvas.heritages.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return {
          'id': 'heritage-${index + 1}',
          'index': index + 1,
          'name': '遗产信息${index + 1}',
          'publicTime': item.publicTime ?? '',
          'itemCount': 0, // 默认值，Flutter版本没有items字段
          'position': {
            'left': item.position.left,
            'top': item.position.top,
            'width': item.position.width,
            'height': item.position.height,
          },
        };
      }).toList(),
      'markdowns': canvas.markdowns.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return {
          'id': 'md-${index + 1}',
          'index': index + 1,
          'name': 'Markdown${index + 1}',
          'content': item.content,
          'position': {
            'left': item.position.left,
            'top': item.position.top,
            'width': item.position.width,
            'height': item.position.height,
          },
        };
      }).toList(),
    };
  }

  void _executeAction(dynamic actionData) {
    try {
      print('执行操作: $actionData');

      if (actionData == null || !(actionData is Map)) {
        print('操作数据无效');
        return;
      }

      final canvasProvider =
          Provider.of<CanvasProvider>(context, listen: false);

      // 确保我们有一个可用的Map并提取基本字段
      final actionMap = Map<String, dynamic>.from(actionData);
      final String action = actionMap['action']?.toString() ?? '';
      final String targetType = actionMap['targetType']?.toString() ?? '';
      int targetIndex = 1;

      // 安全地获取targetIndex，确保它是一个整数
      if (actionMap['targetIndex'] != null) {
        if (actionMap['targetIndex'] is int) {
          targetIndex = actionMap['targetIndex'];
        } else {
          try {
            targetIndex = int.parse(actionMap['targetIndex'].toString());
          } catch (e) {
            print('无法解析targetIndex: ${actionMap['targetIndex']}');
          }
        }
      }

      // 安全地获取params
      Map<String, dynamic> params = {};
      if (actionMap['params'] != null && actionMap['params'] is Map) {
        params = Map<String, dynamic>.from(actionMap['params']);
      }

      // 打印完整的操作信息用于调试
      print(
          '解析后的操作: action=$action, targetType=$targetType, targetIndex=$targetIndex, params=$params');

      // 索引从1开始，需要转换为从0开始
      final int arrayIndex = targetIndex - 1;
      if (arrayIndex < 0) {
        print('无效的索引值: $targetIndex');
        return;
      }

      // 基于action类型执行相应操作
      switch (action) {
        case 'move':
          _safelyMoveComponent(canvasProvider, targetType, arrayIndex, params);
          break;
        case 'edit':
          _safelyEditComponent(canvasProvider, targetType, arrayIndex, params);
          break;
        case 'delete':
          _safelyDeleteComponent(canvasProvider, targetType, arrayIndex);
          break;
        case 'add':
          _safelyAddComponent(canvasProvider, targetType, params);
          break;
        default:
          print('未知操作类型: $action');
      }
    } catch (e) {
      print('执行操作时出错: $e');
    }
  }

  // 安全地移动组件，捕获任何可能的异常
  void _safelyMoveComponent(CanvasProvider provider, String type, int index,
      Map<String, dynamic> params) {
    try {
      final canvas = provider.currentCanvas;
      if (canvas == null) return;

      // 确保索引在有效范围内
      if (!_isValidIndex(type, index, canvas)) {
        print('无效的组件索引: type=$type, index=$index');
        return;
      }

      // 安全地获取位置参数
      num? left, top, width, height;

      if (params.containsKey('left')) {
        left = _parseNumParam(params['left']);
      }

      if (params.containsKey('top')) {
        top = _parseNumParam(params['top']);
      }

      if (params.containsKey('width')) {
        width = _parseNumParam(params['width']);
      }

      if (params.containsKey('height')) {
        height = _parseNumParam(params['height']);
      }

      // 获取当前组件位置作为默认值
      PositionModel currentPosition;
      switch (type) {
        case 'text':
          currentPosition = canvas.texts[index].position;
          break;
        case 'image':
          currentPosition = canvas.images[index].position;
          break;
        case 'heritage':
          currentPosition = canvas.heritages[index].position;
          break;
        case 'markdown':
          currentPosition = canvas.markdowns[index].position;
          break;
        default:
          print('未知组件类型: $type');
          return;
      }

      // 创建新的位置对象，使用当前值作为默认值
      final position = PositionModel(
        left: left?.toDouble() ?? currentPosition.left,
        top: top?.toDouble() ?? currentPosition.top,
        width: width?.toDouble() ?? currentPosition.width,
        height: height?.toDouble() ?? currentPosition.height,
        zIndex: currentPosition.zIndex,
      );

      // 根据组件类型更新位置
      switch (type) {
        case 'text':
          provider.updateTextPosition(canvas.texts[index], position);
          break;
        case 'image':
          provider.updateImagePosition(canvas.images[index], position);
          break;
        case 'heritage':
          provider.updateHeritagePosition(canvas.heritages[index], position);
          break;
        case 'markdown':
          provider.updateMarkdownPosition(canvas.markdowns[index], position);
          break;
      }

      print('成功移动组件: type=$type, index=$index, position=$position');
    } catch (e) {
      print('移动组件时出错: $e');
    }
  }

  // 安全地编辑组件
  void _safelyEditComponent(CanvasProvider provider, String type, int index,
      Map<String, dynamic> params) {
    try {
      final canvas = provider.currentCanvas;
      if (canvas == null) return;

      // 确保索引在有效范围内
      if (!_isValidIndex(type, index, canvas)) {
        print('无效的组件索引: type=$type, index=$index');
        return;
      }

      switch (type) {
        case 'text':
          if (params.containsKey('content')) {
            provider.updateTextItem(
                canvas.texts[index], params['content'].toString());
          }
          break;
        case 'image':
          if (params.containsKey('imageUrl')) {
            provider.updateImageItem(
                canvas.images[index], params['imageUrl'].toString());
          }
          break;
        case 'heritage':
          if (params.containsKey('publicTime')) {
            // 获取当前heritage项并创建一个新的对象，仅更新publicTime
            final currentHeritage = canvas.heritages[index];
            final updatedHeritage = HeritageItemModel(
              title: currentHeritage.title,
              content: currentHeritage.content,
              author: currentHeritage.author,
              position: currentHeritage.position,
              publicTime: DateTime.tryParse(params['publicTime'].toString()) ??
                  DateTime.now(),
            );
            provider.updateHeritageItem(currentHeritage, updatedHeritage);
          }
          break;
        case 'markdown':
          if (params.containsKey('content')) {
            provider.updateMarkdownItem(
                canvas.markdowns[index], params['content'].toString());
          }
          break;
      }

      print('成功编辑组件: type=$type, index=$index');
    } catch (e) {
      print('编辑组件时出错: $e');
    }
  }

  // 安全地删除组件
  void _safelyDeleteComponent(CanvasProvider provider, String type, int index) {
    try {
      final canvas = provider.currentCanvas;
      if (canvas == null) return;

      // 确保索引在有效范围内
      if (!_isValidIndex(type, index, canvas)) {
        print('无效的组件索引: type=$type, index=$index');
        return;
      }

      switch (type) {
        case 'text':
          provider.removeTextItem(canvas.texts[index]);
          break;
        case 'image':
          provider.removeImageItem(canvas.images[index]);
          break;
        case 'heritage':
          provider.removeHeritageItem(canvas.heritages[index]);
          break;
        case 'markdown':
          provider.removeMarkdownItem(canvas.markdowns[index]);
          break;
      }

      print('成功删除组件: type=$type, index=$index');
    } catch (e) {
      print('删除组件时出错: $e');
    }
  }

  // 安全地添加组件
  void _safelyAddComponent(
      CanvasProvider provider, String type, Map<String, dynamic> params) {
    try {
      switch (type) {
        case 'text':
          final content = params.containsKey('content')
              ? params['content'].toString()
              : '新文本';
          provider.addTextItem(content);
          break;
        case 'image':
          final imageUrl = params.containsKey('imageUrl')
              ? params['imageUrl'].toString()
              : '';
          provider.addImageItem(imageUrl);
          break;
        case 'heritage':
          provider.addHeritageItem();
          break;
        case 'markdown':
          final content = params.containsKey('content')
              ? params['content'].toString()
              : '# 新Markdown\n\n内容在这里';
          provider.addMarkdownItem(content);
          break;
      }

      print('成功添加组件: type=$type');
    } catch (e) {
      print('添加组件时出错: $e');
    }
  }

  // 辅助方法：检查索引是否有效
  bool _isValidIndex(String type, int index, CanvasModel canvas) {
    switch (type) {
      case 'text':
        return index >= 0 && index < canvas.texts.length;
      case 'image':
        return index >= 0 && index < canvas.images.length;
      case 'heritage':
        return index >= 0 && index < canvas.heritages.length;
      case 'markdown':
        return index >= 0 && index < canvas.markdowns.length;
      default:
        return false;
    }
  }

  // 辅助方法：安全地解析数字参数
  num? _parseNumParam(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;

    try {
      return num.parse(value.toString());
    } catch (e) {
      print('无法解析为数字: $value');
      return null;
    }
  }

  // 修改画布编辑区域的构建方法
  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer<CanvasProvider>(
          builder: (context, canvasProvider, child) {
            final canvas = canvasProvider.currentCanvas;
            if (canvas == null) {
              return const Center(child: Text('初始化画布中...'));
            }

            // 获取缩放比例
            final scaleFactor = CanvasAdapter.getScaleFactor(context);
            final heightScaleFactor =
                CanvasAdapter.getHeightScaleFactor(context);

            // 计算画布工作区域的大小
            final canvasWidth = CanvasAdapter.webCanvasWidth * scaleFactor;
            final canvasHeight =
                CanvasAdapter.webCanvasHeight * scaleFactor * heightScaleFactor;

            // 计算实际可用空间
            final availableWidth = constraints.maxWidth;
            final availableHeight = constraints.maxHeight;

            // 计算需要的边距，使画布居中
            final horizontalPadding =
                (availableWidth - canvasWidth * _canvasScale) / 2;
            final verticalPadding =
                (availableHeight - canvasHeight * _canvasScale) / 2;

            return Stack(
              children: [
                // 添加网格背景
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(),
                  ),
                ),

                // 使用GestureDetector包装整个画布区域，支持平移和缩放
                GestureDetector(
                  // 添加画布平移手势
                  onPanStart: (details) {
                    if (!_isDraggingCanvas) {
                      _isDraggingCanvas = true;
                      _lastDragPosition = details.globalPosition;
                    }
                  },
                  onPanUpdate: (details) {
                    if (_isDraggingCanvas) {
                      setState(() {
                        final delta =
                            details.globalPosition - _lastDragPosition;
                        _canvasOffset += delta;
                        _lastDragPosition = details.globalPosition;

                        // 限制平移范围，防止画布移出视野
                        final maxOffsetX = canvasWidth * _canvasScale * 0.5;
                        final maxOffsetY = canvasHeight * _canvasScale * 0.5;

                        if (_canvasOffset.dx > maxOffsetX) {
                          _canvasOffset = Offset(maxOffsetX, _canvasOffset.dy);
                        }
                        if (_canvasOffset.dx < -maxOffsetX) {
                          _canvasOffset = Offset(-maxOffsetX, _canvasOffset.dy);
                        }
                        if (_canvasOffset.dy > maxOffsetY) {
                          _canvasOffset = Offset(_canvasOffset.dx, maxOffsetY);
                        }
                        if (_canvasOffset.dy < -maxOffsetY) {
                          _canvasOffset = Offset(_canvasOffset.dx, -maxOffsetY);
                        }
                      });
                    }
                  },
                  onPanEnd: (_) {
                    _isDraggingCanvas = false;
                  },
                  // 添加画布缩放手势
                  onScaleStart: (details) {
                    _lastDragPosition = details.focalPoint;
                  },
                  onScaleUpdate: (details) {
                    if (details.scale != 1.0) {
                      setState(() {
                        // 根据手势更新画布缩放
                        final newScale = (_canvasScale * details.scale)
                            .clamp(_minScale, _maxScale);

                        // 在缩放时保持焦点位置不变
                        final focalPoint = details.focalPoint;
                        final oldScale = _canvasScale;

                        _canvasScale = newScale;

                        // 调整偏移以保持焦点位置
                        if (oldScale != newScale) {
                          final focalPointDelta =
                              focalPoint - _lastDragPosition;
                          _canvasOffset +=
                              focalPointDelta * (1.0 - details.scale);
                          _lastDragPosition = focalPoint;
                        }
                      });
                    } else {
                      // 处理拖动
                      final delta = details.focalPoint - _lastDragPosition;
                      if (delta.distance > 0) {
                        setState(() {
                          _canvasOffset += delta;
                          _lastDragPosition = details.focalPoint;
                        });
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      // 实际画布工作区域
                      Positioned(
                        left: (horizontalPadding > 0 ? horizontalPadding : 0) +
                            _canvasOffset.dx,
                        top: (verticalPadding > 0 ? verticalPadding : 0) +
                            _canvasOffset.dy,
                        width: canvasWidth * _canvasScale,
                        height: canvasHeight * _canvasScale,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.3), width: 1),
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),

                      // 组件索引标签 - 文本
                      ...canvas.texts.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final item = entry.value;
                          // 计算屏幕上的实际位置（考虑缩放和平移）
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;

                          return Positioned(
                            left: screenX - 20 * _canvasScale,
                            top: screenY - 28 * _canvasScale,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '文本[${index + 1}]',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 组件索引标签 - 图片
                      ...canvas.images.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;

                          return Positioned(
                            left: screenX - 20 * _canvasScale,
                            top: screenY - 28 * _canvasScale,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '图片[${index + 1}]',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 组件索引标签 - 遗产
                      ...canvas.heritages.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;

                          return Positioned(
                            left: screenX - 20 * _canvasScale,
                            top: screenY - 28 * _canvasScale,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '遗产[${index + 1}]',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 组件索引标签 - Markdown
                      ...canvas.markdowns.asMap().entries.map(
                        (entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;

                          return Positioned(
                            left: screenX - 20 * _canvasScale,
                            top: screenY - 28 * _canvasScale,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'MD[${index + 1}]',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 文本组件
                      ...canvas.texts.map(
                        (item) {
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;
                          final width =
                              item.position.width * scaleFactor * _canvasScale;
                          final height = item.position.height *
                              scaleFactor *
                              heightScaleFactor *
                              _canvasScale;

                          return Positioned(
                            left: screenX,
                            top: screenY,
                            width: width,
                            height: height,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: TextItem(
                                key: Key('text-${item.hashCode}'),
                                content: item.content,
                                position: item.position,
                                onUpdate: (content) {
                                  canvasProvider.updateTextItem(item, content);
                                },
                                onPositionChange: (position) {
                                  // 更新UI状态的同时也立即更新provider中的数据，实现实时跟随
                                  setState(() {
                                    // 在边界范围内移动 - 限制不能移出画布
                                    if (position.left < 0) position.left = 0;
                                    if (position.top < 0) position.top = 0;
                                    if (position.left + position.width >
                                        CanvasAdapter.webCanvasWidth) {
                                      position.left =
                                          CanvasAdapter.webCanvasWidth -
                                              position.width;
                                    }
                                    if (position.top + position.height >
                                        CanvasAdapter.webCanvasHeight) {
                                      position.top =
                                          CanvasAdapter.webCanvasHeight -
                                              position.height;
                                    }

                                    item.position = position;
                                  });

                                  // 转换位置到Web坐标系，考虑画布缩放
                                  final webPosition =
                                      CanvasAdapter.flutterToWebPosition(
                                    Offset(position.left, position.top),
                                    context,
                                  );
                                  position.left = webPosition.dx;
                                  position.top = webPosition.dy;
                                  canvasProvider.updateTextPosition(
                                      item, position);
                                },
                                onDelete: () {
                                  canvasProvider.removeTextItem(item);
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      // 图片组件
                      ...canvas.images.map(
                        (item) {
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;
                          final width =
                              item.position.width * scaleFactor * _canvasScale;
                          final height = item.position.height *
                              scaleFactor *
                              heightScaleFactor *
                              _canvasScale;

                          return Positioned(
                            left: screenX,
                            top: screenY,
                            width: width,
                            height: height,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: ImageItem(
                                key: Key('image-${item.hashCode}'),
                                imageUrl: item.content,
                                position: item.position,
                                onUpdateImage: (imageUrl) {
                                  canvasProvider.updateImageItem(
                                      item, imageUrl);
                                },
                                onPositionChange: (position) {
                                  // 更新UI状态的同时也立即更新provider中的数据，实现实时跟随
                                  setState(() {
                                    // 在边界范围内移动
                                    if (position.left < 0) position.left = 0;
                                    if (position.top < 0) position.top = 0;
                                    if (position.left + position.width >
                                        CanvasAdapter.webCanvasWidth) {
                                      position.left =
                                          CanvasAdapter.webCanvasWidth -
                                              position.width;
                                    }
                                    if (position.top + position.height >
                                        CanvasAdapter.webCanvasHeight) {
                                      position.top =
                                          CanvasAdapter.webCanvasHeight -
                                              position.height;
                                    }

                                    item.position = position;
                                  });

                                  // 转换位置到Web坐标系，考虑画布缩放
                                  final webPosition =
                                      CanvasAdapter.flutterToWebPosition(
                                    Offset(position.left, position.top),
                                    context,
                                  );
                                  position.left = webPosition.dx;
                                  position.top = webPosition.dy;
                                  canvasProvider.updateImagePosition(
                                      item, position);
                                },
                                onDelete: () {
                                  canvasProvider.removeImageItem(item);
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      // Markdown组件
                      ...canvas.markdowns.map(
                        (item) {
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;
                          final width =
                              item.position.width * scaleFactor * _canvasScale;
                          final height = item.position.height *
                              scaleFactor *
                              heightScaleFactor *
                              _canvasScale;

                          return Positioned(
                            left: screenX,
                            top: screenY,
                            width: width,
                            height: height,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: MarkdownItem(
                                key: Key('markdown-${item.hashCode}'),
                                content: item.content,
                                position: item.position,
                                onUpdate: (content) {
                                  canvasProvider.updateMarkdownItem(
                                      item, content);
                                },
                                onPositionChange: (position) {
                                  // 更新UI状态的同时也立即更新provider中的数据，实现实时跟随
                                  setState(() {
                                    // 在边界范围内移动
                                    if (position.left < 0) position.left = 0;
                                    if (position.top < 0) position.top = 0;
                                    if (position.left + position.width >
                                        CanvasAdapter.webCanvasWidth) {
                                      position.left =
                                          CanvasAdapter.webCanvasWidth -
                                              position.width;
                                    }
                                    if (position.top + position.height >
                                        CanvasAdapter.webCanvasHeight) {
                                      position.top =
                                          CanvasAdapter.webCanvasHeight -
                                              position.height;
                                    }

                                    item.position = position;
                                  });

                                  // 转换位置到Web坐标系，考虑画布缩放
                                  final webPosition =
                                      CanvasAdapter.flutterToWebPosition(
                                    Offset(position.left, position.top),
                                    context,
                                  );
                                  position.left = webPosition.dx;
                                  position.top = webPosition.dy;
                                  canvasProvider.updateMarkdownPosition(
                                      item, position);
                                },
                                onDelete: () {
                                  canvasProvider.removeMarkdownItem(item);
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      // 遗产组件
                      ...canvas.heritages.map(
                        (item) {
                          final screenX = item.position.left *
                                  scaleFactor *
                                  _canvasScale +
                              (horizontalPadding > 0 ? horizontalPadding : 0) +
                              _canvasOffset.dx;
                          final screenY =
                              item.position.top * scaleFactor * _canvasScale +
                                  (verticalPadding > 0 ? verticalPadding : 0) +
                                  _canvasOffset.dy;
                          final width =
                              item.position.width * scaleFactor * _canvasScale;
                          final height = item.position.height *
                              scaleFactor *
                              heightScaleFactor *
                              _canvasScale;

                          return Positioned(
                            left: screenX,
                            top: screenY,
                            width: width,
                            height: height,
                            child: Transform.scale(
                              scale: _canvasScale,
                              alignment: Alignment.topLeft,
                              child: HeritageItem(
                                key: Key('heritage-${item.hashCode}'),
                                heritage: item,
                                position: item.position,
                                onUpdate: (HeritageItemModel heritage) {
                                  canvasProvider.updateHeritageItem(
                                      item, heritage);
                                },
                                onPositionChange: (position) {
                                  // 更新UI状态的同时也立即更新provider中的数据，实现实时跟随
                                  setState(() {
                                    // 在边界范围内移动
                                    if (position.left < 0) position.left = 0;
                                    if (position.top < 0) position.top = 0;
                                    if (position.left + position.width >
                                        CanvasAdapter.webCanvasWidth) {
                                      position.left =
                                          CanvasAdapter.webCanvasWidth -
                                              position.width;
                                    }
                                    if (position.top + position.height >
                                        CanvasAdapter.webCanvasHeight) {
                                      position.top =
                                          CanvasAdapter.webCanvasHeight -
                                              position.height;
                                    }

                                    item.position = position;
                                  });

                                  // 转换位置到Web坐标系，考虑画布缩放
                                  final webPosition =
                                      CanvasAdapter.flutterToWebPosition(
                                    Offset(position.left, position.top),
                                    context,
                                  );
                                  position.left = webPosition.dx;
                                  position.top = webPosition.dy;
                                  canvasProvider.updateHeritagePosition(
                                      item, position);
                                },
                                onDelete: () {
                                  canvasProvider.removeHeritageItem(item);
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      // 添加提示信息
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app,
                                size: 18,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '拖动和捏合手势可以移动和缩放画布',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.canvasId != null ? '编辑画布' : '创建画布'),
        actions: [
          // 对话控制按钮
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _toggleChatInput,
            tooltip: '对话控制',
          ),
          // 保存按钮
          TextButton.icon(
            onPressed: _isSaving ? null : _saveCanvas,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 底层：画布主体内容
          Column(
            children: [
              // 画布设置
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // 标题输入
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '画布标题',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 公开选项
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _isPublic,
                          onChanged: (value) {
                            setState(() {
                              _isPublic = value;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Text(_isPublic ? '公开' : '私有',
                            style: TextStyle(
                                fontSize: 12,
                                color: _isPublic
                                    ? AppColors.primary
                                    : Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              // 工具栏 - 改为可滚动
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.grey[200],
                child: SingleChildScrollView(
                  controller: _toolbarScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      _buildToolButton(
                        icon: Icons.text_fields,
                        label: '文本',
                        onPressed: _addTextItem,
                        isSelected: _selectedTool == 'text',
                      ),
                      _buildToolButton(
                        icon: Icons.image,
                        label: '图片',
                        onPressed: _addImageItem,
                        isSelected: _selectedTool == 'image',
                      ),
                      _buildToolButton(
                        icon: Icons.code,
                        label: 'MD',
                        onPressed: _addMarkdownItem,
                        isSelected: _selectedTool == 'markdown',
                      ),
                      _buildToolButton(
                        icon: Icons.inventory,
                        label: '遗产',
                        onPressed: _addHeritageItem,
                        isSelected: _selectedTool == 'heritage',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              // 画布编辑区域
              Expanded(
                child: Container(
                  color: const Color(0xFFFAFAFA),
                  child: _buildCanvas(),
                ),
              ),
            ],
          ),

          // 中层：搜索框
          const SearchBox(),

          // 最底层：点击空白处关闭聊天框的遮罩
          if (_showChatInput)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleChatInput,
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),

          // 最顶层：聊天输入框
          if (_showChatInput)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  // 防止点击事件传递到下面的遮罩层
                },
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '输入指令控制画布',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                decoration: const InputDecoration(
                                  hintText: '例如：将第一个文本框移到左上角',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                autofocus: true,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isProcessing ? null : _sendMessage,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                backgroundColor: AppColors.primary,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.send,
                                            color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text('发送',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 80,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? AppColors.primary : Colors.white,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
