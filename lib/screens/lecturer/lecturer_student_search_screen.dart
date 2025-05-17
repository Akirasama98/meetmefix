import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import 'lecturer_chat_detail_screen.dart';

class LecturerStudentSearchScreen extends StatefulWidget {
  const LecturerStudentSearchScreen({super.key});

  @override
  State<LecturerStudentSearchScreen> createState() =>
      _LecturerStudentSearchScreenState();
}

class _LecturerStudentSearchScreenState
    extends State<LecturerStudentSearchScreen> {
  final ChatService _chatService = ChatService();
  List<UserModel> _students = [];
  bool _isLoading = true;

  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStudents() {
    // Menggunakan ChatService untuk mendapatkan daftar mahasiswa
    _chatService.getStudents().listen(
      (students) {
        if (mounted) {
          setState(() {
            _students = students;
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
              content: Text('Error loading students: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  // Filter mahasiswa berdasarkan pencarian
  List<UserModel> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    return _students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (student.nim?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (student.department?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Mahasiswa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                        hintText: 'Cari mahasiswa...',
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

                  // Daftar Mahasiswa
                  Expanded(
                    child:
                        _students.isEmpty
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
                                    'Tidak ada mahasiswa yang tersedia',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadStudents,
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            )
                            : _filteredStudents.isEmpty
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
                                    'Tidak ada mahasiswa yang ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                return _buildStudentItem(student);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStudentItem(UserModel student) {
    return InkWell(
      onTap: () async {
        // Dapatkan atau buat chat room
        try {
          final chatId = await _chatService.getOrCreateChatRoom(student.id);

          if (mounted) {
            // Navigasi ke halaman chat dengan mahasiswa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => LecturerChatDetailScreen(
                      student: student,
                      chatId: chatId,
                    ),
              ),
            ).then((_) {
              // Kembali ke halaman daftar chat setelah selesai chat
              if (mounted) {
                Navigator.pop(context);
              }
            });
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
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  (student.photoUrl?.isNotEmpty ?? false)
                      ? NetworkImage(student.photoUrl!)
                      : null,
              child:
                  (student.photoUrl?.isEmpty ?? true)
                      ? Text(
                        student.name.isNotEmpty
                            ? student.name.substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),

            // Informasi Mahasiswa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.nim ?? 'NIM tidak tersedia',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.department ?? 'Jurusan tidak tersedia',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
