import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:electron_application/models/canvas_model.dart';

class CanvasItemWidget extends StatelessWidget {
  final String type; // text, image, markdown, heritage
  final String content;
  final PositionModel position;
  final bool readonly;
  final Function(PositionModel)? onUpdatePosition;
  final HeritageItemModel? heritageData;

  const CanvasItemWidget({
    super.key,
    required this.type,
    required this.content,
    required this.position,
    this.readonly = false,
    this.onUpdatePosition,
    this.heritageData,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.left,
      top: position.top,
      child: Container(
        width: position.width,
        height: position.height,
        decoration: BoxDecoration(
          border: readonly ? null : Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(5),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (type) {
      case 'text':
        return _buildTextItem();
      case 'image':
        return _buildImageItem();
      case 'markdown':
        return _buildMarkdownItem();
      case 'heritage':
        return _buildHeritageItem();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextItem() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        content,
        style: const TextStyle(fontSize: 16),
        overflow: TextOverflow.ellipsis,
        maxLines: 20,
      ),
    );
  }

  Widget _buildImageItem() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        content,
        fit: BoxFit.cover,
        width: position.width,
        height: position.height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 40,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarkdownItem() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Markdown(
        data: content,
        selectable: false,
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 14),
          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeritageItem() {
    if (heritageData == null) {
      return const Center(child: Text('无效的遗产数据'));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 遗产标题
          Text(
            heritageData?.title ?? '数字遗产',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),

          // 公开时间
          if (heritageData?.publicTime != null) ...[
            Text(
              '公开时间: ${heritageData!.publicTime}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
          ],

          // 遗产内容
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(heritageData!.content),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
