import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/lecturer_model.dart';
import '../models/chat_message_model.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final LecturerModel lecturer;
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.lecturer,
    required this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _chatService.currentUserId;
    _loadMessages();

    // Tandai semua pesan sebagai sudah dibaca
    _chatService.markAllAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Menggunakan ChatService untuk mendapatkan pesan
    _chatService
        .getMessages(widget.chatId)
        .listen(
          (messages) {
            if (mounted) {
              setState(() {
                _messages = messages;
                _isLoading = false;
              });

              // Scroll ke bawah setelah pesan dimuat
              _scrollToBottom();
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading messages: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    final message = text.trim();
    _messageController.clear();

    try {
      // Kirim pesan menggunakan ChatService
      await _chatService.sendMessage(
        chatId: widget.chatId,
        receiverId: widget.lecturer.id,
        message: message,
      );

      // Scroll ke bawah
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.lecturer.photoUrl),
              onBackgroundImageError: (_, __) {
                // Fallback jika gambar tidak dapat dimuat
              },
              child:
                  widget.lecturer.photoUrl.isEmpty
                      ? Text(
                        widget.lecturer.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lecturer.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  widget.lecturer.status == 'online'
                      ? 'Online'
                      : 'Terakhir dilihat ${widget.lecturer.lastSeen}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        widget.lecturer.status == 'online'
                            ? Colors.green
                            : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Daftar Pesan
                  Expanded(
                    child:
                        _messages.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada pesan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Mulai percakapan dengan mengirim pesan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final message = _messages[index];
                                final isMe = message.senderId == _currentUserId;

                                // Tandai pesan sebagai sudah dibaca jika belum dibaca dan bukan dari pengguna saat ini
                                if (!message.isRead && !isMe) {
                                  _chatService.markAsRead(
                                    widget.chatId,
                                    message.id,
                                  );
                                }

                                // Tampilkan tanggal jika berbeda dari pesan sebelumnya
                                bool showDate = false;
                                if (index == 0) {
                                  showDate = true;
                                } else {
                                  final prevMessage = _messages[index - 1];
                                  if (!_isSameDay(
                                    prevMessage.timestamp,
                                    message.timestamp,
                                  )) {
                                    showDate = true;
                                  }
                                }

                                return Column(
                                  children: [
                                    if (showDate)
                                      _buildDateSeparator(message.timestamp),
                                    _buildMessageItem(message, isMe),
                                  ],
                                );
                              },
                            ),
                  ),

                  // Divider
                  const Divider(height: 1),

                  // Input Pesan
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatDate(date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.lecturer.photoUrl),
              onBackgroundImageError: (_, __) {
                // Fallback jika gambar tidak dapat dimuat
              },
              child:
                  widget.lecturer.photoUrl.isEmpty
                      ? Text(
                        widget.lecturer.name.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? const Color(0xFF5BBFCB).withAlpha(51)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft:
                      isMe
                          ? const Radius.circular(16)
                          : const Radius.circular(0),
                  bottomRight:
                      isMe
                          ? const Radius.circular(0)
                          : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.message, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: const Color(0xFF5BBFCB),
            onPressed: () {
              // Handle attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF5BBFCB),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () => _handleSubmitted(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Hari Ini';
    } else if (dateToCheck == yesterday) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
