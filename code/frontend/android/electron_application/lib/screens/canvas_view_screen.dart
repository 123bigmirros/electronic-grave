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
import 'package:electron_application/widgets/customer_service.dart';

class CanvasViewScreen extends StatefulWidget {
  final String canvasId;

  const CanvasViewScreen({Key? key, required this.canvasId}) : super(key: key);

  @override
  State<CanvasViewScreen> createState() => _CanvasViewScreenState();
}

class _CanvasViewScreenState extends State<CanvasViewScreen> {
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCanvasData();
    });
  }

  Future<void> _loadCanvasData() async {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await canvasProvider.getCanvas(widget.canvasId);

    if (canvasProvider.currentCanvas != null && mounted) {
      setState(() {
        _isOwner = authProvider.userId != null &&
            canvasProvider.currentCanvas!.userId.toString() ==
                authProvider.userId;
      });
    }
  }

  void _editCanvas() {
    Navigator.pushNamed(
      context,
      '${AppRoutes.gravePaint}/${widget.canvasId}',
    ).then((_) {
      // 返回时重新加载画布数据
      _loadCanvasData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('画布查看'),
        actions: [
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editCanvas,
              tooltip: '编辑画布',
            ),
        ],
      ),
      body: Stack(
        children: [
          // 画布内容
          Consumer<CanvasProvider>(
            builder: (context, canvasProvider, child) {
              if (canvasProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (canvasProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '加载失败: ${canvasProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCanvasData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }

              final canvas = canvasProvider.currentCanvas;
              if (canvas == null) {
                return const Center(child: Text('画布不存在或已被删除'));
              }

              return Container(
                padding: const EdgeInsets.all(16.0),
                color: const Color(0xFFFAFAFA),
                child: Stack(
                  children: [
                    // 标题
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          canvas.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 各种组件
                    ...canvas.texts.map(
                      (item) => TextItem(
                        key: Key('text-${item.hashCode}'),
                        content: item.content,
                        position: item.position,
                        readonly: true,
                      ),
                    ),

                    ...canvas.images.map(
                      (item) => ImageItem(
                        key: Key('image-${item.hashCode}'),
                        imageUrl: item.content,
                        position: item.position,
                        readonly: true,
                      ),
                    ),

                    ...canvas.heritages.map(
                      (item) => HeritageItem(
                        key: Key('heritage-${item.hashCode}'),
                        heritage: item,
                        position: item.position,
                        readonly: true,
                      ),
                    ),

                    ...canvas.markdowns.map(
                      (item) => MarkdownItem(
                        key: Key('markdown-${item.hashCode}'),
                        content: item.content,
                        position: item.position,
                        readonly: true,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 搜索框组件
          const SearchBox(),
        ],
      ),
      // 添加客服组件
      floatingActionButton: Consumer<CanvasProvider>(
        builder: (context, canvasProvider, child) {
          if (canvasProvider.currentCanvas == null) {
            return const SizedBox.shrink();
          }

          return CustomerService(
            canvasId: widget.canvasId,
            canvasData: canvasProvider.currentCanvas!,
          );
        },
      ),
    );
  }
}
