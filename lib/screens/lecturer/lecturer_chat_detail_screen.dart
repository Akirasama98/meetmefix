import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';

class LecturerChatDetailScreen extends StatefulWidget {
  final UserModel student;
  final String chatId;

  const LecturerChatDetailScreen({
    super.key,
    required this.student,
    required this.chatId,
  });

  @override
  State<LecturerChatDetailScreen> createState() =>
      _LecturerChatDetailScreenState();
}

class _LecturerChatDetailScreenState extends State<LecturerChatDetailScreen> {
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
        receiverId: widget.student.id,
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (_isSameDay(date, now)) {
      return 'Hari ini';
    } else if (_isSameDay(date, yesterday)) {
      return 'Kemarin';
    } else {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (widget.student.photoUrl?.isNotEmpty ?? false)
                      ? widget.student.photoUrl!.startsWith('data:image')
                          ? MemoryImage(
                            StorageService.base64ToImage(
                              widget.student.photoUrl!,
                            )!,
                          )
                          : NetworkImage(widget.student.photoUrl!)
                              as ImageProvider
                      : null,
              child:
                  (widget.student.photoUrl?.isEmpty ?? true) ||
                          ((widget.student.photoUrl?.startsWith('data:image') ??
                                  false) &&
                              StorageService.base64ToImage(
                                    widget.student.photoUrl!,
                                  ) ==
                                  null)
                      ? Text(
                        widget.student.name.isNotEmpty
                            ? widget.student.name.substring(0, 1)
                            : '?',
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
                Text(widget.student.name, style: const TextStyle(fontSize: 16)),
                Text(
                  widget.student.nim ?? 'Mahasiswa',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
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
      body: Column(
        children: [
          // Daftar Pesan
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == _currentUserId;

                        // Tandai pesan sebagai sudah dibaca jika belum dibaca dan bukan dari pengguna saat ini
                        if (!message.isRead && !isMe) {
                          _chatService.markAsRead(widget.chatId, message.id);
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

  Widget _buildEmptyChat() {
    return Center(
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai percakapan dengan ${widget.student.name}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  (widget.student.photoUrl?.isNotEmpty ?? false)
                      ? widget.student.photoUrl!.startsWith('data:image')
                          ? MemoryImage(
                            StorageService.base64ToImage(
                              widget.student.photoUrl!,
                            )!,
                          )
                          : NetworkImage(widget.student.photoUrl!)
                              as ImageProvider
                      : null,
              child:
                  (widget.student.photoUrl?.isEmpty ?? true) ||
                          ((widget.student.photoUrl?.startsWith('data:image') ??
                                  false) &&
                              StorageService.base64ToImage(
                                    widget.student.photoUrl!,
                                  ) ==
                                  null)
                      ? Text(
                        widget.student.name.isNotEmpty
                            ? widget.student.name.substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF5BBFCB) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
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
                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.isRead ? Colors.white : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          // Input Field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _handleSubmitted,
            ),
          ),
          // Send Button
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFF5BBFCB),
            onPressed: () => _handleSubmitted(_messageController.text),
          ),
        ],
      ),
    );
  }
}
