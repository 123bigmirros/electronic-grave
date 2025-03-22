import 'package:flutter/material.dart';
import 'package:electron_application/utils/constants.dart';
import 'package:electron_application/utils/http_client.dart';
import 'package:electron_application/models/canvas_model.dart';

class CustomerService extends StatefulWidget {
  final String canvasId;
  final CanvasModel canvasData;
  final Function(bool)? onExpandChange;

  const CustomerService({
    Key? key,
    required this.canvasId,
    required this.canvasData,
    this.onExpandChange,
  }) : super(key: key);

  @override
  State<CustomerService> createState() => _CustomerServiceState();
}

class _CustomerServiceState extends State<CustomerService>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final HttpClient _httpClient = HttpClient();
  final ScrollController _scrollController = ScrollController();

  bool _isExpanded = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _messages = [];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    widget.onExpandChange?.call(_isExpanded);

    if (_isExpanded) {
      _animationController.forward();
      if (_messages.isEmpty) {
        _sendInitMessage();
      }
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _sendInitMessage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _httpClient.post(
        ApiEndpoints.chat,
        data: {
          'type': 'init',
          'canvas_id': widget.canvasId,
          'canvas_data': widget.canvasData.toJson(),
          'history': _messages,
        },
        usePythonServer: true,
      );

      if (response['answer'] != null) {
        setState(() {
          _messages.add({'type': 'assistant', 'content': response['answer']});
        });
        _scrollToBottom();
      }
    } catch (error) {
      setState(() {
        _messages.add({'type': 'system', 'content': '连接失败，请稍后重试'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();

    setState(() {
      _messages.add({'type': 'user', 'content': message});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _httpClient.post(
        ApiEndpoints.chat,
        data: {
          'type': 'message',
          'message': message,
          'canvas_id': widget.canvasId,
          'canvas_data': widget.canvasData.toJson(),
          'history': _messages.where((msg) => msg['type'] != 'system').toList(),
        },
        usePythonServer: true,
      );

      if (response['answer'] != null) {
        setState(() {
          _messages.add({'type': 'assistant', 'content': response['answer']});
        });
      } else {
        setState(() {
          _messages.add({'type': 'system', 'content': '回复失败，请稍后重试'});
        });
      }
    } catch (error) {
      setState(() {
        _messages.add({'type': 'system', 'content': '发送失败，请稍后重试'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (!_isExpanded) {
          return FloatingActionButton(
            onPressed: _toggleExpand,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.support_agent, size: 28),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 350,
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // 头部
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '智能助手',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _toggleExpand,
                          ),
                        ],
                      ),
                    ),

                    // 消息区域
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _messages.isEmpty && !_isLoading
                            ? const Center(
                                child: Text(
                                  '有什么问题都可以问我哦！',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount:
                                    _messages.length + (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _messages.length) {
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final message = _messages[index];
                                  return _buildMessageBubble(
                                    message['content'],
                                    message['type'],
                                  );
                                },
                              ),
                      ),
                    ),

                    // 输入区域
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: '请输入您的问题...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            onPressed: _isLoading ? null : _sendMessage,
                            backgroundColor: AppColors.primary,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(String content, String type) {
    final isUser = type == 'user';
    final isSystem = type == 'system';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && !isSystem) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: const Icon(
                Icons.support_agent,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : isSystem
                        ? Colors.amber
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                content,
                style: TextStyle(color: isUser ? Colors.white : Colors.black),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
