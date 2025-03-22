import 'package:flutter/material.dart';
import 'package:electron_application/screens/home_screen.dart';
import 'package:electron_application/screens/login_screen.dart';
import 'package:electron_application/screens/personal_screen.dart';
import 'package:electron_application/screens/canvas_view_screen.dart';
import 'package:electron_application/screens/grave_paint_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String personal = '/personal';
  static const String gravePaint = '/gravepaint';
  static const String canvasView = '/canvas/view';

  static Map<String, WidgetBuilder> get routes => {
        home: (context) => const HomeScreen(),
        login: (context) => const LoginScreen(),
        personal: (context) => const PersonalScreen(),
        gravePaint: (context) => const GravePaintScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final String? path = settings.name;

    // 处理画布编辑路由
    if (path?.startsWith(gravePaint) == true) {
      // 如果是基础路径，返回新建画布页面
      if (path == gravePaint) {
        return MaterialPageRoute(
          builder: (_) => const GravePaintScreen(),
        );
      }
      // 提取画布ID
      final canvasId = path?.split('/').last;
      return MaterialPageRoute(
        builder: (_) => GravePaintScreen(canvasId: canvasId),
      );
    }

    // 处理画布查看路由
    if (path?.startsWith(canvasView) == true) {
      final canvasId = path?.split('/').last;
      return MaterialPageRoute(
        builder: (_) => CanvasViewScreen(canvasId: canvasId ?? ''),
      );
    }

    // 默认返回404页面
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('404 - 页面不存在')),
      ),
    );
  }
}
