import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MindfulnessScreen extends StatefulWidget {
  const MindfulnessScreen({super.key});

  @override
  State<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends State<MindfulnessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(title: Text("Mindfulness", style: GoogleFonts.poppins()), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Breathe with the circle", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 50),
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.5),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)],
                ),
              ),
            ),
            const SizedBox(height: 80),
            Text("Inhale... Exhale...", style: GoogleFonts.poppins(color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}