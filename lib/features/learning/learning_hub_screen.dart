import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isChatOpen = false;
  bool _isTyping = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  // API KEY & MODEL SETUP
  static const String _apiKey = "AIzaSyADOlj1wtHe37UDm4_iBNEfdMqFA3S31Ss";

  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite', // Flash is faster for real-time chat
      apiKey: _apiKey,
    );
    _messages.add({"role": "bot", "msg": "Hi! I am Nexus AI. I've analyzed your study sessions. Need help with a concept?"});
  }

  Future<void> _sendAiMessage() async {
    if (_chatController.text.isEmpty) return;
    String userMsg = _chatController.text;
    setState(() {
      _messages.add({"role": "user", "msg": userMsg});
      _isTyping = true;
    });
    _chatController.clear();

    try {
      final response = await _model.generateContent([Content.text(userMsg)]);
      setState(() {
        _messages.add({"role": "bot", "msg": response.text ?? "I'm processing that..."});
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({"role": "bot", "msg": "Brain Fog! 🧠 Let's try again in a moment."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("Nexus Intelligence Hub", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true, elevation: 0.5, backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          _buildFocusAnalytics(), // Unique Analytics UI (No more boring notes list)
          if (_isChatOpen) _buildAdvancedChatWindow(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
        backgroundColor: const Color(0xFF2D5AF0),
        icon: Icon(_isChatOpen ? Icons.close : Icons.psychology_alt, color: Colors.white),
        label: Text(_isChatOpen ? "Close" : "AI Tutor", style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- UNIQUE ANALYTICS UI ---
  Widget _buildFocusAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Productivity Score Card
          _buildEfficiencyCard(),
          const SizedBox(height: 30),

          Text("Cognitive Load Analysis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // 2. Deep Work Metrics
          _buildMetricRow("Deep Work", "5.2 Hours", Icons.timer, Colors.deepPurple),
          _buildMetricRow("Recall Rate", "88%", Icons.auto_graph, Colors.green),
          _buildMetricRow("Distractions", "Low", Icons.do_not_disturb_on, Colors.orange),

          const SizedBox(height: 30),

          // 3. AI Generated Insight
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFF2D5AF0)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "AI Observation: Your concentration peaks between 10 AM - 12 PM. We recommend scanning complex notes during this window.",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2D5AF0), Color(0xFF6C63FF)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text("Current Study Efficiency", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Text("94%", style: GoogleFonts.poppins(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const LinearProgressIndicator(value: 0.94, backgroundColor: Colors.white24, color: Colors.white),
          const SizedBox(height: 15),
          Text("You're in the Top 5% of active learners!", style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 15),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // --- CHATBOT WINDOW (GEMINI INTEGRATED) ---
  Widget _buildAdvancedChatWindow() {
    return Positioned(
      bottom: 85, right: 15, left: 15,
      child: Container(
        height: 500,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40)]),
        child: Column(
          children: [
            _chatHeader(),
            Expanded(child: _messageList()),
            if (_isTyping) const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator()),
            _inputArea(),
          ],
        ),
      ),
    );
  }

  Widget _chatHeader() => Container(
    padding: const EdgeInsets.all(18),
    decoration: const BoxDecoration(color: Color(0xFF2D5AF0), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    child: Row(children: [const Icon(Icons.auto_awesome, color: Colors.white), const SizedBox(width: 10), Text("Real-time AI Tutor", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))]),
  );

  Widget _messageList() => ListView.builder(
    padding: const EdgeInsets.all(15),
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      bool isBot = _messages[index]['role'] == 'bot';
      return Align(
        alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: isBot ? Colors.grey[100] : const Color(0xFF2D5AF0), borderRadius: BorderRadius.circular(18)),
          child: Text(_messages[index]['msg']!, style: GoogleFonts.poppins(color: isBot ? Colors.black87 : Colors.white, fontSize: 13)),
        ),
      );
    },
  );

  Widget _inputArea() => Padding(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _chatController,
            onSubmitted: (_) => _sendAiMessage(),
            decoration: InputDecoration(hintText: "Clear your doubts...", filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(backgroundColor: const Color(0xFF2D5AF0), child: IconButton(onPressed: _sendAiMessage, icon: const Icon(Icons.send, color: Colors.white, size: 18))),
      ],
    ),
  );
}