import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electron_application/utils/http_client.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/providers/auth_provider.dart';
import 'package:electron_application/routes/app_routes.dart';
import 'dart:convert';

class SearchBox extends StatefulWidget {
  const SearchBox({Key? key}) : super(key: key);

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final HttpClient _httpClient = HttpClient();

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isExpanded = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final List<List<String>> _chatHistory = [];

  // 拖动相关变量
  Offset _position = const Offset(20, 20); // 初始位置
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 设置初始位置在左下角
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _position = Offset(20, size.height - 80);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleSearch() {
    if (_searchController.text.isNotEmpty) {
      _handleSearchWithResults();
    }
  }

  Future<void> _handleSearchWithResults() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _httpClient.post(
        ApiEndpoints.search,
        data: {'query': query, 'chat_history': _chatHistory},
        usePythonServer: true,
      );

      debugPrint('搜索响应: ${json.encode(response)}');

      if (response['sources'] != null) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response['sources']);
        });
        debugPrint('搜索结果: ${json.encode(_searchResults)}');

        // 更新聊天历史
        if (response['answer'] != null) {
          _chatHistory.add([query, response['answer']]);
        }
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _viewCanvas(String canvasId) {
    debugPrint('查看画布: $canvasId');
    if (canvasId == 'null' || canvasId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无效的画布ID')),
      );
      return;
    }
    Navigator.pushNamed(context, '${AppRoutes.canvasView}/$canvasId');
    setState(() {
      _searchResults = [];
      _isExpanded = false;
    });
    _animationController.reverse();
  }

  void _goToHome() {
    Navigator.pushNamed(context, AppRoutes.home);
    _toggleExpand();
  }

  void _goToPersonal() {
    Navigator.pushNamed(context, AppRoutes.personal);
    _toggleExpand();
  }

  void _goToCreate() {
    Navigator.pushNamed(context, AppRoutes.gravePaint);
    _toggleExpand();
  }

  @override
  Widget build(BuildContext context) {
    // 使用Positioned而不是Container来实现浮动效果
    return Positioned(
      left: _position.dx,
      bottom: MediaQuery.of(context).size.height - _position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        // 搜索图标按钮
                        IconButton(
                          icon: Icon(_isExpanded ? Icons.close : Icons.search),
                          onPressed: _toggleExpand,
                          color: AppColors.primary,
                        ),

                        // 展开后的内容
                        if (_isExpanded) ...[
                          // 搜索输入框
                          Container(
                            width: 200,
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: '搜索画布...',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onSubmitted: (_) => _handleSearch(),
                            ),
                          ),

                          // 功能按钮区域
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _handleSearchWithResults,
                            color: AppColors.primary,
                            tooltip: '搜索',
                          ),

                          IconButton(
                            icon: const Icon(Icons.home),
                            onPressed: _goToHome,
                            color: AppColors.primary,
                            tooltip: '主页',
                          ),

                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _goToCreate,
                            color: AppColors.primary,
                            tooltip: '创建画布',
                          ),

                          IconButton(
                            icon: const Icon(Icons.person),
                            onPressed: _goToPersonal,
                            color: AppColors.primary,
                            tooltip: '个人中心',
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            // 搜索结果显示
            if (_isExpanded && (_isSearching || _searchResults.isNotEmpty))
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 350,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          final canvasId = result['canvas_id']?.toString() ??
                              result['id']?.toString();
                          debugPrint('结果项: ${json.encode(result)}');
                          return ListTile(
                            title: Text(
                              result['title'] ?? '未命名画布',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              result['content'] ?? '无描述',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _viewCanvas(canvasId ?? ''),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
