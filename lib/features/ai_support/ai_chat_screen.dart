import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // Gemini API Configuration
  final _model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: 'AIzaSyADOlj1wtHe37UDm4_iBNEfdMqFA3S31Ss');

  // --- 1. SAVE CHAT TO FIREBASE ---
  Future<void> _saveChatToFirebase(String message, String role) async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('chats')
          .add({
        'message': message,
        'role': role,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- 2. SYNC TASK + TIME TO HABIT TRACKER ---
  Future<void> _syncToHabitTracker(String aiResponse) async {
    if (aiResponse.contains("[HABIT_SYNC]")) {
      try {
        // AI format expected: [HABIT_SYNC] Task Name | Time
        String rawData = aiResponse.split("[HABIT_SYNC]").last.trim();
        String taskName = rawData.split("|").first.trim();
        String taskTime = rawData.contains("|") ? rawData.split("|").last.trim() : "Anytime";
        
        if (user != null && taskName.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('habits')
              .add({
            'name': taskName,
            'time': taskTime,
            'isCompleted': false,
            'progress': 0.0,
            'timestamp': FieldValue.serverTimestamp(),
            'color': 0xFF2D5AF0,
          });
          print("Synced: $taskName at $taskTime");
        }
      } catch (e) {
        print("Sync error: $e");
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    _controller.clear();
    
    // Save user message to history
    await _saveChatToFirebase(userMessage, "user");

    setState(() => _isLoading = true);

    final prompt = """
    User Message: $userMessage
    You are a Smart Study Assistant. 
    1. Answer normally as a helpful tutor.
    2. If user mentions a goal or routine, add '[HABIT_SYNC] TaskName | HH:MM AM/PM' at the very end.
    3. Keep TaskName very short (max 3 words).
    """;
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String fullText = response.text ?? "";

      // Logic: Hide the sync tag from user UI
      String displayMessage = fullText.split("[HABIT_SYNC]").first.trim();

      // Save AI response to history
      await _saveChatToFirebase(displayMessage, "ai");

      // Background Habit Sync
      _syncToHabitTracker(fullText);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Connection Error!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF0F3F8),
      appBar: AppBar(
        title: Text("Study Hub AI", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: () => _clearChatHistory(),
          )
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.withOpacity(0.1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // --- REAL-TIME HISTORY VIEW ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('chats')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  var messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true, // Newer messages at the bottom
                    padding: const EdgeInsets.fromLTRB(15, 120, 15, 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var data = messages[index].data() as Map<String, dynamic>;
                      return _buildGlossyBubble(data['message'], data['role'] == "user");
                    },
                  );
                },
              ),
            ),
            if (_isLoading) const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF2D5AF0)),
            ),
            _buildGlossyInputArea(),
          ],
        ),
      ),
    );
  }

  // --- HELPER: CLEAR CHAT ---
  void _clearChatHistory() async {
    var collection = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('chats');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Widget _buildGlossyBubble(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(15),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2D5AF0).withOpacity(0.85) : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 22),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              ),
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: isUser ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlossyInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Plan your day with AI...",
                      hintStyle: TextStyle(color: Colors.blueGrey[300]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF2D5AF0), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}