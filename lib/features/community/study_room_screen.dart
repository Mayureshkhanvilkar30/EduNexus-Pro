import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudyRoomScreen extends StatelessWidget {
  const StudyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Global Study Room", style: GoogleFonts.poppins())),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _chatBubble("Rahul", "Hey, anyone has notes for Physics?", false),
                _chatBubble("Sneha", "Yes, check the Learning Hub section!", true),
              ],
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _chatBubble(String user, String msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.blue)),
            Text(msg, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Ask a doubt...",
          suffixIcon: const Icon(Icons.send, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true, fillColor: Colors.white,
        ),
      ),
    );
  }
}