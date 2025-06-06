import 'package:flutter/material.dart';
import 'chat_list_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Show chat list instead of lecturer list
    return const ChatListScreen();
  }
}
