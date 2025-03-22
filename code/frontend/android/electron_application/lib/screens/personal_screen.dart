import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electron_application/providers/auth_provider.dart';
import 'package:electron_application/providers/canvas_provider.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/routes/app_routes.dart';
import 'package:electron_application/widgets/search_box.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({Key? key}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthProvider>(context, listen: false).initialize();
      // 加载用户的画布列表
      Provider.of<CanvasProvider>(context, listen: false).loadUserCanvasList();
    });
  }

  // 查看画布
  void _viewCanvas(String canvasId) {
    Navigator.pushNamed(context, '${AppRoutes.canvasView}/$canvasId');
  }

  // 编辑画布
  void _editCanvas(String canvasId) {
    Navigator.pushNamed(
      context,
      '${AppRoutes.gravePaint}/$canvasId',
    );
  }

  // 创建新画布
  void _createNewCanvas() {
    Navigator.pushNamed(context, AppRoutes.gravePaint);
  }

  // 删除画布
  Future<void> _deleteCanvas(String canvasId) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个画布吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('正在删除...'),
              ],
            ),
          ),
        );
      }

      try {
        final result = await Provider.of<CanvasProvider>(
          context,
          listen: false,
        ).deleteCanvas(canvasId);

        // 关闭加载对话框
        if (mounted) {
          Navigator.pop(context);
        }

        if (result && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('画布已删除')));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                Provider.of<CanvasProvider>(context, listen: false).error ??
                    '删除失败'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        // 关闭加载对话框
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canvasProvider = Provider.of<CanvasProvider>(context);

    // 检查用户是否登录
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人主页'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewCanvas,
            tooltip: '创建新画布',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            tooltip: '退出登录',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 用户信息卡片
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 30,
                          child:
                              Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '欢迎回来',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.username ?? '用户',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 画布列表标题
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      '我的画布',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (canvasProvider.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // 画布列表
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (canvasProvider.isLoading &&
                        canvasProvider.canvasList.isEmpty) {
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
                              onPressed: () {
                                Provider.of<CanvasProvider>(
                                  context,
                                  listen: false,
                                ).loadUserCanvasList();
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (canvasProvider.canvasList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('暂无画布'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.gravePaint,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('创建画布'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: canvasProvider.canvasList.length,
                        itemBuilder: (context, index) {
                          final canvas = canvasProvider.canvasList[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 3,
                            child: InkWell(
                              onTap: () => _viewCanvas(canvas.id.toString()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 标题栏
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    color: AppColors.primary,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            canvas.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (canvas.isPublic)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                10,
                                              ),
                                            ),
                                            child: Text(
                                              '公开',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // 预览内容
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Center(
                                        child: Text(
                                          '画布预览',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 操作按钮
                                  ButtonBar(
                                    alignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            _editCanvas(canvas.id.toString()),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('编辑'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _deleteCanvas(canvas.id.toString()),
                                        icon:
                                            const Icon(Icons.delete, size: 16),
                                        label: const Text('删除'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // 搜索框
          const SearchBox(),
        ],
      ),
    );
  }
}
