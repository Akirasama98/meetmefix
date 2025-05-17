import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/lecturer_model.dart'; // Import the proper model
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _chatList.length,
                itemBuilder: (context, index) {
                  final chat = _chatList[index];
                  return _buildChatItem(chat);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/lecturer_list').then((_) {
            // Refresh daftar chat setelah kembali dari pencarian
            _loadChatList();
          });
        },
        backgroundColor: const Color(0xFF5BBFCB),
        tooltip: 'Cari Dosen',
        child: const Icon(Icons.person_add, color: Colors.white),
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
            'Tekan tombol + untuk mencari dosen dan memulai percakapan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/lecturer_list').then((_) {
                _loadChatList();
              });
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Cari Dosen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BBFCB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final partnerName = chat['partnerName'] ?? 'Unknown';
    final lastMessage = chat['lastMessage'];
    final unreadCount = chat['unreadCount'] ?? 0;

    // Create lecturer model from chat data using the imported model
    final lecturer = LecturerModel.fromMap({
      'name': partnerName,
      'photoUrl': chat['partnerPhotoUrl'] ?? '',
      'status': 'offline',
      'lastSeen': '',
      'department': chat['partnerDepartment'] ?? '',
      'title': chat['partnerTitle'] ?? '',
    }, chat['partnerId']);

    return InkWell(
      onTap: () async {
        // Navigate to chat detail
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  lecturer: lecturer,
                  chatId: chat['chatId'],
                ),
          ),
        );

        // Refresh chat list after returning
        _loadChatList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  chat['partnerPhotoUrl'] != null &&
                          chat['partnerPhotoUrl'].isNotEmpty
                      ? NetworkImage(chat['partnerPhotoUrl'])
                      : null,
              child:
                  chat['partnerPhotoUrl'] == null ||
                          chat['partnerPhotoUrl'].isEmpty
                      ? Text(
                        partnerName.isNotEmpty
                            ? partnerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 20),
                      )
                      : null,
            ),
            const SizedBox(width: 16),

            // Chat Info
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

            // Unread Count Badge
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF5BBFCB),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (now.difference(date).inDays == 0) {
      // Today, show time
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays == 1) {
      // Yesterday
      return 'Kemarin';
    } else if (now.difference(date).inDays < 7) {
      // This week, show day name
      final days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      return days[date.weekday - 1];
    } else {
      // Older, show date
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Remove the local LecturerModel class since we're now using the one from models/lecturer_model.dart
