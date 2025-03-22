import 'dart:convert';

class CanvasModel {
  String id;
  String title;
  String userId;
  bool isPublic;
  List<TextItemModel> texts;
  List<ImageItemModel> images;
  List<MarkdownItemModel> markdowns;
  List<HeritageItemModel> heritages;
  DateTime createdAt;
  DateTime updatedAt;

  CanvasModel({
    required this.id,
    required this.title,
    required this.userId,
    required this.isPublic,
    required this.texts,
    required this.images,
    required this.markdowns,
    required this.heritages,
    required this.createdAt,
    required this.updatedAt,
  });

  // 创建空画布的工厂方法
  factory CanvasModel.empty() {
    return CanvasModel(
      id: '',
      title: '新画布',
      userId: '',
      isPublic: true,
      texts: [],
      images: [],
      markdowns: [],
      heritages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory CanvasModel.fromJson(Map<String, dynamic> json) {
    return CanvasModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      isPublic: json['is_public'] ?? true,
      texts: json['texts'] != null
          ? List<TextItemModel>.from(
              json['texts'].map((x) => TextItemModel.fromJson(x)))
          : [],
      images: json['images'] != null
          ? List<ImageItemModel>.from(
              json['images'].map((x) => ImageItemModel.fromJson(x)))
          : [],
      markdowns: json['markdowns'] != null
          ? List<MarkdownItemModel>.from(
              json['markdowns'].map((x) => MarkdownItemModel.fromJson(x)))
          : [],
      heritages: json['heritages'] != null
          ? List<HeritageItemModel>.from(
              json['heritages'].map((x) => HeritageItemModel.fromJson(x)))
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'user_id': userId,
      'is_public': isPublic,
      'texts': texts.map((x) => x.toJson()).toList(),
      'images': images.map((x) => x.toJson()).toList(),
      'markdowns': markdowns.map((x) => x.toJson()).toList(),
      'heritages': heritages.map((x) => x.toJson()).toList(),
    };
  }
}

class PositionModel {
  double left;
  double top;
  double width;
  double height;
  int zIndex;

  PositionModel({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.zIndex = 0,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      left: (json['left'] ?? 0).toDouble(),
      top: (json['top'] ?? 0).toDouble(),
      width: (json['width'] ?? 200).toDouble(),
      height: (json['height'] ?? 100).toDouble(),
      zIndex: json['z_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'z_index': zIndex,
    };
  }

  // 添加copyWith方法
  PositionModel copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    int? zIndex,
  }) {
    return PositionModel(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
    );
  }
}

class TextItemModel {
  String content;
  PositionModel position;

  TextItemModel({
    required this.content,
    required this.position,
  });

  factory TextItemModel.fromJson(Map<String, dynamic> json) {
    return TextItemModel(
      content: json['content'] ?? '',
      position: PositionModel.fromJson(json['position'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'position': position.toJson(),
    };
  }
}

class ImageItemModel {
  String content;
  PositionModel position;

  ImageItemModel({
    required this.content,
    required this.position,
  });

  factory ImageItemModel.fromJson(Map<String, dynamic> json) {
    return ImageItemModel(
      content: json['content'] ?? '',
      position: PositionModel.fromJson(json['position'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'position': position.toJson(),
    };
  }
}

class MarkdownItemModel {
  String content;
  PositionModel position;

  MarkdownItemModel({
    required this.content,
    required this.position,
  });

  factory MarkdownItemModel.fromJson(Map<String, dynamic> json) {
    return MarkdownItemModel(
      content: json['content'] ?? '',
      position: PositionModel.fromJson(json['position'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'position': position.toJson(),
    };
  }
}

class HeritageItemModel {
  String title;
  String content;
  String author;
  PositionModel position;
  DateTime publicTime;

  HeritageItemModel({
    required this.title,
    required this.content,
    required this.author,
    required this.position,
    required this.publicTime,
  });

  factory HeritageItemModel.fromJson(Map<String, dynamic> json) {
    return HeritageItemModel(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      author: json['author'] ?? '',
      position: PositionModel.fromJson(json['position'] ?? {}),
      publicTime: json['public_time'] != null
          ? DateTime.parse(json['public_time'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'position': position.toJson(),
      'public_time': publicTime.toIso8601String(),
    };
  }
}
