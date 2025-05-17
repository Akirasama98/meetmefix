import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import 'lecturer_chat_detail_screen.dart';

class LecturerChatListScreen extends StatefulWidget {
  const LecturerChatListScreen({super.key});

  @override
  State<LecturerChatListScreen> createState() => _LecturerChatListScreenState();
}

class _LecturerChatListScreenState extends State<LecturerChatListScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatList = [];

  @override
  void initState() {
    super.initState();
    _loadChatList();
  }

  void _loadChatList() {
    _chatService.getChatList().listen(
      (chatList) {
        if (mounted) {
          setState(() {
            _chatList = chatList;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading chat list: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChatList,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatList.isEmpty
              ? _buildEmptyChatList()
              : ListView.builder(
                itemCount: _chatList.length,
                itemBuilder: (context, index) {
                  final chat = _chatList[index];
                  return _buildChatItem(chat);
                },
              ),
    );
  }

  Widget _buildEmptyChatList() {
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
            'Belum ada percakapan',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Mahasiswa akan muncul di sini saat mereka mengirim pesan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final String partnerId = chat['partnerId'] ?? '';
    final String partnerName = chat['partnerName'] ?? 'Unknown';
    final String partnerPhotoUrl = chat['partnerPhotoUrl'] ?? '';
    final int unreadCount = chat['unreadCount'] ?? 0;
    final Map<String, dynamic>? lastMessage = chat['lastMessage'];

    // Buat model mahasiswa dari data partner
    final student = UserModel(
      id: partnerId,
      name: partnerName,
      email: '',
      photoUrl: partnerPhotoUrl,
      role: 'student',
      nim: chat['partnerNim'] ?? '',
      department: chat['partnerDepartment'] ?? '',
    );

    return InkWell(
      onTap: () async {
        // Navigasi ke halaman chat detail
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LecturerChatDetailScreen(
                  student: student,
                  chatId: chat['chatId'],
                ),
          ),
        );

        // Refresh daftar chat setelah kembali
        _loadChatList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // Foto Profil
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      partnerPhotoUrl.isNotEmpty
                          ? NetworkImage(partnerPhotoUrl)
                          : null,
                  child:
                      partnerPhotoUrl.isEmpty
                          ? Text(
                            partnerName.isNotEmpty
                                ? partnerName.substring(0, 1)
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Informasi Chat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        partnerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (lastMessage != null)
                        Text(
                          _formatTimestamp(lastMessage['timestamp'] ?? 0),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage != null
                        ? lastMessage['message'] ?? ''
                        : 'Belum ada pesan',
                    style: TextStyle(
                      color:
                          unreadCount > 0 ? Colors.black : Colors.grey.shade600,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';

    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Hari ini
      return DateFormat('HH:mm').format(messageTime);
    } else if (difference.inDays == 1) {
      // Kemarin
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      // Dalam minggu ini
      return DateFormat('EEEE').format(messageTime);
    } else {
      // Lebih dari seminggu
      return DateFormat('dd/MM/yyyy').format(messageTime);
    }
  }
}
