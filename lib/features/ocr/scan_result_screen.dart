import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_service.dart';

class ScanResultScreen extends StatefulWidget {
  final String scannedText;
  const ScanResultScreen({super.key, required this.scannedText});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late TextEditingController _textController;
  bool _isSaving = false;
  String? _currentSummary; // Summary ko temp store karne ke liye

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.scannedText);
  }

  // 1. Updated Database Logic: Original Text aur Summary dono handle karega
  Future<void> _saveToFirestore({String? aiSummary}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('notes').add({
        'userId': user.uid,
        'text': _textController.text.trim(), // My Notes ke liye
        'summary': aiSummary ?? _currentSummary ?? "No summary generated", // AI Block ke liye
        'createdAt': FieldValue.serverTimestamp(),
        'title': _textController.text.split('\n').first.length > 30
            ? _textController.text.split('\n').first.substring(0, 30)
            : _textController.text.split('\n').first,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved to Dashboard & My Notes! ✅")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verify Scanned Text"),
        actions: [
          _isSaving
              ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
            onPressed: () => _saveToFirestore(), // Normal Save
            child: const Text("SAVE", style: TextStyle(color: Color(0xFF2D5AF0), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "No text found."),
              ),
            ),
            const Divider(),

            // AI Summary Module
            ElevatedButton.icon(
              onPressed: () async {
                if (_textController.text.isEmpty) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                String aiSummary = await AIService.summarizeText(_textController.text);

                if (context.mounted) Navigator.pop(context);

                // Summary BottomSheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(20),
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("AI Smart Summary ✨", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Divider(),
                        Expanded(child: SingleChildScrollView(child: Text(aiSummary, style: const TextStyle(fontSize: 16)))),
                        const SizedBox(height: 15),

                        // CLOSE ki jagah SAVE TO DASHBOARD button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // BottomSheet band karein
                            _saveToFirestore(aiSummary: aiSummary); // AI Summary ke saath save karein
                          },
                          icon: const Icon(Icons.dashboard_customize_rounded),
                          label: const Text("SAVE TO DASHBOARD"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF2D5AF0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Summarize with AI"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}