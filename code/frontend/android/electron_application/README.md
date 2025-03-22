# 电子墓碑 Flutter 应用

电子墓碑是一个数字化纪念和遗产保存应用，允许用户创建和管理数字化的纪念空间。

## 功能特点

- 轮播式画布展示
- 画布编辑与创作功能
- 多种组件：文本、图片、Markdown文本、遗产展示
- 个人主页管理
- 智能客服助手
- 搜索功能

## 开发环境要求

- Flutter 3.7.0 或更高版本
- Dart 3.0.0 或更高版本
- Android Studio / VS Code
- Android SDK (开发Android版本)
- Xcode (开发iOS版本)

## 安装与运行

1. 克隆代码库：
   ```
   git clone https://github.com/yourusername/electronic-grave.git
   ```

2. 进入项目目录：
   ```
   cd electronic-grave/code/frontend/android/electron_application
   ```

3. 安装依赖：
   ```
   flutter pub get
   ```

4. 运行应用：
   ```
   flutter run
   ```

## 项目结构

```
lib/
├── main.dart             # 应用入口
├── models/               # 数据模型
├── providers/            # 状态管理
├── screens/              # 页面
├── utils/                # 工具类
├── widgets/              # 组件
└── routes/               # 路由配置
```

## 接口配置

应用默认连接以下接口：
- Java后端: http://101.132.43.211:8090
- Python后端: http://101.132.43.211:5002

若需修改接口地址，请编辑 `lib/utils/constants.dart` 文件。

## 注意事项

1. 应用需要网络权限，请确保在AndroidManifest.xml和Info.plist中已添加相关权限。
2. 图片上传功能需要文件存储和相机权限。
3. 应用使用HTTP接口，需要在Android和iOS配置中允许非HTTPS连接。

## 贡献

欢迎提交Pull Request或Issue反馈问题。

## 许可证

MIT License
