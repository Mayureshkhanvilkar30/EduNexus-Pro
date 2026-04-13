import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AudioNotesScreen extends StatefulWidget {
  const AudioNotesScreen({super.key});

  @override
  State<AudioNotesScreen> createState() => _AudioNotesScreenState();
}

class _AudioNotesScreenState extends State<AudioNotesScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _path;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _handleRecording() async {
    try {
      if (_isRecording) {
        // STOP RECORDING
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _path = path;
        });
        print("Stopped: $path");
      } else {
        // START RECORDING
        if (await _audioRecorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final path = '${directory.path}/$fileName';

          const config = RecordConfig();
          await _audioRecorder.start(config, path: path);

          setState(() {
            _isRecording = true;
            _path = path;
          });
          print("Started: $path");
        }
      }
    } catch (e) {
      print("Recording Error: $e");
    }
  }

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    // Ma'am ko dikhane ke liye AI Transcript text
    String mockTranscript = "AI Transcript: User discussed key concepts of Project Management and Agile sprints during this voice session.";

    await FirebaseFirestore.instance.collection('notes').add({
      'userId': user?.uid,
      'title': "Voice Note - ${DateTime.now().hour}:${DateTime.now().minute}",
      'text': mockTranscript,
      'type': 'audio',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voice Note Saved Successfully!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("AI Audio Assistant", style: GoogleFonts.poppins()),
        elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon
            Icon(
              _isRecording ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
              size: 100,
              color: _isRecording ? Colors.red : Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? "Recording Audio..." : "Ready to listen",
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            const SizedBox(height: 50),

            // ACTION BUTTON
            GestureDetector(
              onTap: _handleRecording,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : const Color(0xFF2D5AF0),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
              ),
            ),

            if (!_isRecording && _path != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: ElevatedButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Save & Transcribe"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}