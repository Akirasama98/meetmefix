import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lecturer_model.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class LecturerListScreen extends StatefulWidget {
  const LecturerListScreen({super.key});

  @override
  State<LecturerListScreen> createState() => _LecturerListScreenState();
}

class _LecturerListScreenState extends State<LecturerListScreen> {
  final ChatService _chatService = ChatService();
  List<LecturerModel> _lecturers = [];
  bool _isLoading = true;

  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLecturers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Update status user menjadi offline saat keluar dari halaman
    _chatService.updateUserStatus(false);
    super.dispose();
  }

  void _loadLecturers() {
    // Menggunakan ChatService untuk mendapatkan daftar dosen
    _chatService.getLecturers().listen(
      (lecturers) {
        if (mounted) {
          setState(() {
            _lecturers = lecturers;
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
              content: Text('Error loading lecturers: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    // Update status user menjadi online
    _chatService.updateUserStatus(true);
  }

  // Filter dosen berdasarkan pencarian
  List<LecturerModel> get _filteredLecturers {
    if (_searchQuery.isEmpty) {
      return _lecturers;
    }
    return _lecturers.where((lecturer) {
      return lecturer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lecturer.department.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Dosen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLecturers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari dosen...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),

                  // Daftar Dosen
                  Expanded(
                    child:
                        _lecturers.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada dosen yang tersedia',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadLecturers,
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            )
                            : _filteredLecturers.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada dosen yang ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _filteredLecturers.length,
                              itemBuilder: (context, index) {
                                final lecturer = _filteredLecturers[index];
                                return _buildLecturerItem(lecturer);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildLecturerItem(LecturerModel lecturer) {
    // Warna status
    Color statusColor;
    switch (lecturer.status) {
      case 'online':
        statusColor = Colors.green;
        break;
      case 'busy':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return InkWell(
      onTap: () async {
        // Dapatkan atau buat chat room
        try {
          final chatId = await _chatService.getOrCreateChatRoom(lecturer.id);

          if (mounted) {
            // Navigasi ke halaman chat dengan dosen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ChatDetailScreen(lecturer: lecturer, chatId: chatId),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating chat: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
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
                  backgroundImage: NetworkImage(lecturer.photoUrl),
                  onBackgroundImageError: (_, __) {
                    // Fallback jika gambar tidak dapat dimuat
                  },
                  child:
                      lecturer.photoUrl.isEmpty
                          ? Text(
                            lecturer.name.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Informasi Dosen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecturer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lecturer.title} - ${lecturer.department}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lecturer.status == 'online'
                        ? 'Online'
                        : 'Terakhir dilihat ${lecturer.lastSeen}',
                    style: TextStyle(
                      color:
                          lecturer.status == 'online'
                              ? Colors.green
                              : Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Ikon Chat
            const Icon(Icons.chat_bubble_outline, color: Color(0xFF5BBFCB)),
          ],
        ),
      ),
    );
  }
}
