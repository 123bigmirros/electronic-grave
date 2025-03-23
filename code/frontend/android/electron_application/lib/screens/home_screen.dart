import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electron_application/providers/auth_provider.dart';
import 'package:electron_application/providers/canvas_provider.dart';
import 'package:electron_application/widgets/canvas_item_widget.dart';
import 'package:electron_application/widgets/search_box.dart';
import 'package:electron_application/widgets/customer_service.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/models/canvas_model.dart';
import 'package:electron_application/widgets/text_item.dart';
import 'package:electron_application/widgets/image_item.dart';
import 'package:electron_application/widgets/heritage_item.dart';
import 'package:electron_application/widgets/markdown_item.dart';
import 'package:electron_application/routes/app_routes.dart';

// 修改画布适配工具类
class HomeCanvasAdapter {
  static const double webCanvasWidth = 1920.0;
  static const double webCanvasHeight = 1080.0;
  static const double minScale = 0.5; // 最小缩放比例
  static const double maxScale = 3.5; // 增大最大缩放比例
  static const double androidScaleFactor = 3.0; // 增加Android特定缩放系数
  static const double androidHeightEnhancement = 2.0; // 进一步提高Android高度增强系数
  static const double generalHeightEnhancement = 1.5; // 提高所有平台高度增强系数

  // 缓存每个画布的高度增强系数，确保重绘时保持一致
  static final Map<String, double> _heightFactorCache = {};

  static double getScaleFactor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // 计算基础缩放系数
    final widthScale = screenWidth / webCanvasWidth;
    final heightScale = screenHeight / webCanvasHeight;
    double scale = widthScale < heightScale ? widthScale : heightScale;

    // 确保缩放比例在合理范围内
    scale = scale.clamp(minScale, maxScale);

    // 为Android设备应用额外的缩放系数
    if (isAndroid) {
      scale *= androidScaleFactor;
    }

    return scale;
  }

  // 获取高度增强系数，使用缓存机制确保重绘时一致
  static double getHeightScaleFactor(BuildContext context, [String? canvasId]) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // 如果提供了画布ID并且已缓存，则返回缓存值
    if (canvasId != null && _heightFactorCache.containsKey(canvasId)) {
      return _heightFactorCache[canvasId]!;
    }

    // 计算新的高度增强系数
    final heightFactor =
        isAndroid ? androidHeightEnhancement : generalHeightEnhancement;

    // 如果提供了画布ID，则缓存该值
    if (canvasId != null) {
      _heightFactorCache[canvasId] = heightFactor;
    }

    return heightFactor;
  }

  static Size getItemSize(Size originalSize, BuildContext context,
      [String? canvasId]) {
    final scale = getScaleFactor(context);
    final heightScale = getHeightScaleFactor(context, canvasId);

    return Size(
      originalSize.width * scale,
      originalSize.height * scale,
    );
  }

  // 确保页面动画结束后不会重置高度
  static void ensureConsistentHeight() {
    if (_heightFactorCache.isEmpty) {
      // 初始化默认值确保稳定性
      _heightFactorCache['default'] = 1.8;
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isScrolling = false;
  bool _isCustomerServiceExpanded = false;
  bool _isMouseHovering = false; // 鼠标悬停状态
  bool _isTouching = false; // 添加触摸状态跟踪
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserAuth();
      Provider.of<CanvasProvider>(context, listen: false).loadHomeCanvasList();
    });

    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted &&
          !_isScrolling &&
          !_isCustomerServiceExpanded &&
          !_isMouseHovering &&
          !_isTouching) {
        // 添加触摸检查
        final canvasList =
            Provider.of<CanvasProvider>(context, listen: false).canvasList;
        if (canvasList.isNotEmpty) {
          final nextIndex = (_currentIndex + 1) % canvasList.length;
          _animateToPage(nextIndex);
        }
        _startAutoPlay();
      } else {
        // 如果鼠标悬停或触摸中，继续检查，但不执行轮播
        _startAutoPlay();
      }
    });
  }

  void _animateToPage(int index) {
    // 确保高度一致性
    HomeCanvasAdapter.ensureConsistentHeight();

    _fadeController.forward().then((_) {
      _pageController
          .animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _fadeController.reverse();
        // 确保动画结束后不重置高度
        setState(() {
          _isScrolling = false;
        });
      });
    });
  }

  void _stopAutoPlay() {
    // 停止自动轮播
  }

  void _checkUserAuth() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      Navigator.pushNamed(context, AppRoutes.login);
    }
  }

  Widget _buildCanvasPage(CanvasModel canvas, BuildContext context) {
    final scale = HomeCanvasAdapter.getScaleFactor(context);
    final heightScale =
        HomeCanvasAdapter.getHeightScaleFactor(context, canvas.id.toString());
    final size = MediaQuery.of(context).size;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // 在构建页面时确保高度一致性
    HomeCanvasAdapter.ensureConsistentHeight();

    return Container(
      width: size.width,
      height: size.height,
      color: Colors.white,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // 背景网格
            SizedBox.expand(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),

            // 内容容器，居中显示
            Center(
              child: SizedBox(
                width: isAndroid
                    ? size.width * 0.9 // 在Android上使用屏幕宽度的90%
                    : HomeCanvasAdapter.webCanvasWidth * scale,
                height: isAndroid
                    ? size.height * 0.9 // 增加高度利用率和增强系数
                    : HomeCanvasAdapter.webCanvasHeight * scale,
                child: Stack(
                  children: [
                    // 文本组件
                    ...canvas.texts.map(
                      (item) => Positioned(
                        left: item.position.left * scale,
                        top: item.position.top * scale,
                        width: item.position.width * scale,
                        height: item.position.height * scale, // 增加高度
                        child: TextItem(
                          key: Key('text-${item.hashCode}-${canvas.id}'),
                          content: item.content,
                          position: item.position,
                          readonly: true,
                        ),
                      ),
                    ),

                    // 图片组件
                    ...canvas.images.map(
                      (item) => Positioned(
                        left: item.position.left * scale,
                        top: item.position.top * scale,
                        width: item.position.width * scale,
                        height: item.position.height * scale, // 增加高度
                        child: ImageItem(
                          key: Key('image-${item.hashCode}-${canvas.id}'),
                          imageUrl: item.content,
                          position: item.position,
                          readonly: true,
                        ),
                      ),
                    ),

                    // 遗产组件
                    ...canvas.heritages.map(
                      (item) => Positioned(
                        left: item.position.left * scale,
                        top: item.position.top * scale,
                        width: item.position.width * scale,
                        height: item.position.height * scale, // 增加高度
                        child: HeritageItem(
                          key: Key('heritage-${item.hashCode}-${canvas.id}'),
                          heritage: item,
                          position: item.position,
                          readonly: true,
                        ),
                      ),
                    ),

                    // Markdown组件
                    ...canvas.markdowns.map(
                      (item) => Positioned(
                        left: item.position.left * scale,
                        top: item.position.top * scale,
                        width: item.position.width * scale,
                        height: item.position.height * scale, // 增加高度
                        child: MarkdownItem(
                          key: Key('markdown-${item.hashCode}-${canvas.id}'),
                          content: item.content,
                          position: item.position,
                          readonly: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    // 根据平台选择合适的交互容器
    Widget interactionContainer;

    if (isAndroid) {
      // Android设备使用GestureDetector检测触摸
      interactionContainer = GestureDetector(
        onTapDown: (_) => _handleTouchStart(),
        onPanStart: (_) => _handleTouchStart(),
        onLongPressStart: (_) => _handleTouchStart(),
        onTapUp: (_) => _handleTouchEnd(),
        onPanEnd: (_) => _handleTouchEnd(),
        onLongPressEnd: (_) => _handleTouchEnd(),
        child: Stack(
          children: _buildScreenContent(context),
        ),
      );
    } else {
      // 非Android设备使用MouseRegion
      interactionContainer = MouseRegion(
        onEnter: (_) => setState(() => _isMouseHovering = true),
        onExit: (_) => setState(() => _isMouseHovering = false),
        child: Stack(
          children: _buildScreenContent(context),
        ),
      );
    }

    return Scaffold(
      body: interactionContainer,
    );
  }

  // 提取构建屏幕内容的方法
  List<Widget> _buildScreenContent(BuildContext context) {
    return [
      // 画布轮播
      Consumer<CanvasProvider>(
        builder: (context, canvasProvider, child) {
          final canvasList = canvasProvider.canvasList;

          if (canvasProvider.isLoading && canvasList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (canvasList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '没有可展示的画布',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isScrolling = false; // 确保页面切换后不会误判为正在滚动
              });
            },
            // 关闭自动预加载以避免渲染问题
            physics: const ClampingScrollPhysics(),
            itemCount: canvasList.length,
            itemBuilder: (context, index) {
              // 确保每个画布使用一致的缓存高度系数
              HomeCanvasAdapter.getHeightScaleFactor(
                  context, canvasList[index].id.toString());
              return _buildCanvasPage(canvasList[index], context);
            },
          );
        },
      ),

      // 页面指示器
      Positioned(
        right: 20,
        top: 0,
        bottom: 0,
        child: Center(
          child: Consumer<CanvasProvider>(
            builder: (context, canvasProvider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  canvasProvider.canvasList.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? AppColors.primary
                          : Colors.grey[300],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // 客服组件
      Consumer<CanvasProvider>(
        builder: (context, canvasProvider, child) {
          final canvasList = canvasProvider.canvasList;
          if (canvasList.isEmpty || _currentIndex >= canvasList.length) {
            return const SizedBox();
          }

          return Positioned(
            bottom: 20,
            right: 20,
            child: CustomerService(
              canvasId: canvasList[_currentIndex].id.toString(),
              canvasData: canvasList[_currentIndex],
              onExpandChange: (isExpanded) {
                setState(() {
                  _isCustomerServiceExpanded = isExpanded;
                });
              },
            ),
          );
        },
      ),

      // 搜索框
      const Positioned(
        top: 20,
        left: 20,
        right: 20,
        child: SearchBox(),
      ),
    ];
  }

  // 用户触摸开始时调用
  void _handleTouchStart() {
    setState(() {
      _isTouching = true;
    });
  }

  // 用户触摸结束时调用
  void _handleTouchEnd() {
    // 延迟重置触摸状态，让用户有时间查看
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isTouching = false;
        });
      }
    });
  }
}

// 添加网格背景绘制器
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

    // 基础网格间距 - 针对高DPI设备调整
    final gridSpacing = devicePixelRatio > 2.0 ? 60.0 : 40.0;

    // 细网格线
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = devicePixelRatio > 2.0 ? 0.8 : 0.5;

    // 主网格线 - 每3条细线绘制一条主线
    final majorPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = devicePixelRatio > 2.0 ? 1.2 : 0.8;

    // 绘制垂直线
    for (double i = 0; i < size.width; i += gridSpacing) {
      // 每3条线使用主线
      final isMainLine = (i / gridSpacing) % 3 == 0;

      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        isMainLine ? majorPaint : paint,
      );
    }

    // 绘制水平线
    for (double i = 0; i < size.height; i += gridSpacing) {
      // 每3条线使用主线
      final isMainLine = (i / gridSpacing) % 3 == 0;

      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        isMainLine ? majorPaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
