import 'package:flutter/material.dart';
import 'lecturer_list_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Langsung tampilkan daftar dosen
    return const LecturerListScreen();
  }
}
