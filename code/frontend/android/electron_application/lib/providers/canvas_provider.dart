import 'package:flutter/foundation.dart';
import 'package:electron_application/utils/http_client.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/models/canvas_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CanvasProvider with ChangeNotifier {
  final HttpClient _httpClient = HttpClient();

  List<CanvasModel> _canvasList = [];
  CanvasModel? _currentCanvas;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CanvasModel> get canvasList => _canvasList;
  CanvasModel? get currentCanvas => _currentCanvas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // 获取首页轮播画布列表
  Future<void> loadHomeCanvasList() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _httpClient.get(ApiEndpoints.homeCanvas);
      if (response['code'] == 1 && response['data'] != null) {
        final List<dynamic> data = response['data'];
        _canvasList = data.map((item) => CanvasModel.fromJson(item)).toList();
      } else {
        _error = response['msg'] ?? '加载失败';
      }
    } catch (e) {
      _error = '网络错误: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 获取用户的画布列表
  Future<void> loadUserCanvasList() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _httpClient.post(ApiEndpoints.userCanvas);
      if (response['code'] == 1 && response['data'] != null) {
        final List<dynamic> data = response['data'];
        _canvasList = data.map((item) => CanvasModel.fromJson(item)).toList();
      } else {
        _error = response['msg'] ?? '加载失败';
      }
    } catch (e) {
      _error = '网络错误: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 获取单个画布详情
  Future<void> getCanvas(String canvasId, {bool isEditing = false}) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _httpClient.get(
        '${ApiEndpoints.canvas}/get/$canvasId/${isEditing ? '1' : '0'}',
        requireAuth: isEditing, // 只有编辑模式需要身份验证
      );
      if (response['code'] == 1 && response['data'] != null) {
        _currentCanvas = CanvasModel.fromJson(response['data']);
      } else {
        _error = response['msg'] ?? '加载失败';
      }
    } catch (e) {
      _error = '网络错误: $e';
    } finally {
      _setLoading(false);
    }
  }

  // 删除画布
  Future<bool> deleteCanvas(String canvasId) async {
    _setLoading(true);
    _error = null;

    try {
      final response =
          await _httpClient.delete('${ApiEndpoints.canvas}/$canvasId');

      if (response['code'] == 1) {
        try {
          await _httpClient.post('${ApiEndpoints.deleteEmbedding}/$canvasId');
        } catch (embeddingError) {
          print('删除embedding失败: $embeddingError');
        }

        _canvasList.removeWhere((canvas) => canvas.id.toString() == canvasId);
        if (_currentCanvas?.id.toString() == canvasId) {
          _currentCanvas = null;
        }

        await loadUserCanvasList();

        return true;
      } else {
        _error = response['msg'] ?? '删除失败';
        return false;
      }
    } catch (e) {
      _error = '网络错误: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 保存画布
  Future<bool> saveCanvas(CanvasModel canvas) async {
    try {
      _setLoading(true);
      _setError(null);

      // 检查用户是否登录
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(StorageKeys.userId);

      if (userId == null || userId.isEmpty || userId == 'undefined') {
        _setError('用户未登录');
        return false;
      }

      // 处理画布数据，移除前端生成的ID
      final processedTexts = canvas.texts.map((item) {
        final Map<String, dynamic> newItem = item.toJson();
        if (newItem['id'] != null &&
            newItem['id'].toString().startsWith('text-')) {
          newItem.remove('id');
        }
        return newItem;
      }).toList();

      final processedImages = canvas.images.map((item) {
        final Map<String, dynamic> newItem = item.toJson();
        if (newItem['id'] != null &&
            newItem['id'].toString().startsWith('img-')) {
          newItem.remove('id');
        }
        return newItem;
      }).toList();

      final processedHeritages = canvas.heritages.map((item) {
        final Map<String, dynamic> newItem = item.toJson();
        if (newItem['id'] != null &&
            newItem['id'].toString().startsWith('heritage-')) {
          newItem.remove('id');
        }
        return newItem;
      }).toList();

      final processedMarkdowns = canvas.markdowns.map((item) {
        final Map<String, dynamic> newItem = item.toJson();
        if (newItem['id'] != null &&
            newItem['id'].toString().startsWith('md-')) {
          newItem.remove('id');
        }
        return newItem;
      }).toList();

      final canvasData = {
        'id': canvas.id,
        'title': canvas.title,
        'isPublic': canvas.isPublic ? 1 : 0,
        'texts': processedTexts,
        'images': processedImages,
        'heritages': processedHeritages,
        'markdowns': processedMarkdowns,
      };

      final response = await _httpClient.post(
        ApiEndpoints.saveCanvas,
        data: canvasData,
      );

      if (response['code'] == 1) {
        // 保存成功后调用embedding API
        try {
          await _httpClient.post(
            ApiEndpoints.canvasEmbedding,
            data: {'canvas_id': response['data']},
            usePythonServer: true,
          );
        } catch (embeddingError) {
          debugPrint('Embedding生成失败: $embeddingError');
        }
        return true;
      } else {
        _setError(response['msg'] ?? '保存画布失败');
        return false;
      }
    } catch (e) {
      _setError('保存画布失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 清除当前画布
  void clearCurrentCanvas() {
    _currentCanvas = CanvasModel.empty();
    notifyListeners();
  }

  // 创建新画布
  Future<bool> createCanvas(CanvasModel canvas) async {
    _setLoading(true);
    _error = null;

    try {
      final Map<String, dynamic> data = {
        'title': canvas.title,
        'isPublic': canvas.isPublic,
        'texts': canvas.texts.map((e) => e.toJson()).toList(),
        'images': canvas.images.map((e) => e.toJson()).toList(),
        'markdowns': canvas.markdowns.map((e) => e.toJson()).toList(),
        'heritages': canvas.heritages.map((e) => e.toJson()).toList(),
      };

      final response = await _httpClient.post(
        ApiEndpoints.canvas,
        data: data,
      );

      if (response['code'] == 1 && response['data'] != null) {
        final newCanvas = CanvasModel.fromJson(response['data']);
        _canvasList.add(newCanvas);
        _currentCanvas = newCanvas;
        notifyListeners();
        return true;
      } else {
        _error = response['msg'] ?? '创建失败';
        return false;
      }
    } catch (e) {
      _error = '网络错误: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 更新画布
  Future<bool> updateCanvas(CanvasModel canvas) async {
    _setLoading(true);
    _error = null;

    try {
      final Map<String, dynamic> data = {
        'title': canvas.title,
        'isPublic': canvas.isPublic,
        'texts': canvas.texts.map((e) => e.toJson()).toList(),
        'images': canvas.images.map((e) => e.toJson()).toList(),
        'markdowns': canvas.markdowns.map((e) => e.toJson()).toList(),
        'heritages': canvas.heritages.map((e) => e.toJson()).toList(),
      };

      final response = await _httpClient.put(
        '${ApiEndpoints.canvas}/${canvas.id}',
        data: data,
      );

      if (response['code'] == 1) {
        // 更新本地数据
        final index = _canvasList.indexWhere((c) => c.id == canvas.id);
        if (index != -1) {
          _canvasList[index] = canvas;
        }
        _currentCanvas = canvas;
        notifyListeners();
        return true;
      } else {
        _error = response['msg'] ?? '更新失败';
        return false;
      }
    } catch (e) {
      _error = '网络错误: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 添加文本
  void addTextItem(String content) {
    if (_currentCanvas == null) return;

    final position = PositionModel(
      left: 50,
      top: 50,
      width: 200,
      height: 100,
      zIndex: _getNextZIndex(),
    );

    final textItem = TextItemModel(
      content: content,
      position: position,
    );

    _currentCanvas!.texts.add(textItem);
    notifyListeners();
  }

  // 更新文本
  void updateTextItem(TextItemModel item, String content) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.texts.indexOf(item);
    if (index != -1) {
      _currentCanvas!.texts[index].content = content;
      notifyListeners();
    }
  }

  // 更新文本位置
  void updateTextPosition(TextItemModel item, PositionModel position) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.texts.indexOf(item);
    if (index != -1) {
      _currentCanvas!.texts[index].position = position;
      notifyListeners();
    }
  }

  // 删除文本
  void removeTextItem(TextItemModel item) {
    if (_currentCanvas == null) return;

    _currentCanvas!.texts.remove(item);
    notifyListeners();
  }

  // 添加图片
  void addImageItem(String imageUrl) {
    if (_currentCanvas == null) return;

    final position = PositionModel(
      left: 50,
      top: 50,
      width: 300,
      height: 200,
      zIndex: _getNextZIndex(),
    );

    final imageItem = ImageItemModel(
      content: imageUrl,
      position: position,
    );

    _currentCanvas!.images.add(imageItem);
    notifyListeners();
  }

  // 更新图片
  void updateImageItem(ImageItemModel item, String imageUrl) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.images.indexOf(item);
    if (index != -1) {
      _currentCanvas!.images[index].content = imageUrl;
      notifyListeners();
    }
  }

  // 更新图片位置
  void updateImagePosition(ImageItemModel item, PositionModel position) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.images.indexOf(item);
    if (index != -1) {
      _currentCanvas!.images[index].position = position;
      notifyListeners();
    }
  }

  // 删除图片
  void removeImageItem(ImageItemModel item) {
    if (_currentCanvas == null) return;

    _currentCanvas!.images.remove(item);
    notifyListeners();
  }

  // 添加Markdown
  void addMarkdownItem(String content) {
    if (_currentCanvas == null) return;

    final position = PositionModel(
      left: 50,
      top: 50,
      width: 350,
      height: 250,
      zIndex: _getNextZIndex(),
    );

    final markdownItem = MarkdownItemModel(
      content: content,
      position: position,
    );

    _currentCanvas!.markdowns.add(markdownItem);
    notifyListeners();
  }

  // 更新Markdown
  void updateMarkdownItem(MarkdownItemModel item, String content) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.markdowns.indexOf(item);
    if (index != -1) {
      _currentCanvas!.markdowns[index].content = content;
      notifyListeners();
    }
  }

  // 更新Markdown位置
  void updateMarkdownPosition(MarkdownItemModel item, PositionModel position) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.markdowns.indexOf(item);
    if (index != -1) {
      _currentCanvas!.markdowns[index].position = position;
      notifyListeners();
    }
  }

  // 删除Markdown
  void removeMarkdownItem(MarkdownItemModel item) {
    if (_currentCanvas == null) return;

    _currentCanvas!.markdowns.remove(item);
    notifyListeners();
  }

  // 添加遗产
  void addHeritageItem() {
    if (_currentCanvas == null) return;

    final position = PositionModel(
      left: 50,
      top: 50,
      width: 400,
      height: 300,
      zIndex: _getNextZIndex(),
    );

    final heritageItem = HeritageItemModel(
      title: '新遗产',
      content: '遗产内容',
      author: '',
      position: position,
      publicTime: DateTime.now(),
    );

    _currentCanvas!.heritages.add(heritageItem);
    notifyListeners();
  }

  // 更新遗产
  void updateHeritageItem(HeritageItemModel item, HeritageItemModel heritage) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.heritages.indexOf(item);
    if (index != -1) {
      _currentCanvas!.heritages[index] = heritage;
      notifyListeners();
    }
  }

  // 更新遗产位置
  void updateHeritagePosition(HeritageItemModel item, PositionModel position) {
    if (_currentCanvas == null) return;

    final index = _currentCanvas!.heritages.indexOf(item);
    if (index != -1) {
      _currentCanvas!.heritages[index].position = position;
      notifyListeners();
    }
  }

  // 删除遗产
  void removeHeritageItem(HeritageItemModel item) {
    if (_currentCanvas == null) return;

    _currentCanvas!.heritages.remove(item);
    notifyListeners();
  }

  // 获取下一个zIndex值
  int _getNextZIndex() {
    if (_currentCanvas == null) return 1;

    int maxZIndex = 0;

    for (var item in _currentCanvas!.texts) {
      if (item.position.zIndex > maxZIndex) {
        maxZIndex = item.position.zIndex;
      }
    }

    for (var item in _currentCanvas!.images) {
      if (item.position.zIndex > maxZIndex) {
        maxZIndex = item.position.zIndex;
      }
    }

    for (var item in _currentCanvas!.markdowns) {
      if (item.position.zIndex > maxZIndex) {
        maxZIndex = item.position.zIndex;
      }
    }

    for (var item in _currentCanvas!.heritages) {
      if (item.position.zIndex > maxZIndex) {
        maxZIndex = item.position.zIndex;
      }
    }

    return maxZIndex + 1;
  }
}
