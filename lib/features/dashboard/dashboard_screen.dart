import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; 
import 'dart:async';

// Module aur Service Imports
import '../ocr/ocr_scanner_screen.dart';
import '../ocr/saved_notes_screen.dart';
import '../tasks/task_goal_screen.dart'; 
import '../timetable/timetable_screen.dart';
import '../learning/course_suggestion_screen.dart';
import '../ai_support/ai_chat_screen.dart'; 
import '../../services/notification_service.dart';
import '../settings/settings_screen.dart';      

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "Student";
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _updateStreak(); 
    NotificationService.init();
  }

  // --- STREAK LOGIC (Daily Consistency) ---
  Future<void> _updateStreak() async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final doc = await docRef.get();
    
    if (doc.exists) {
      Map<String, dynamic> data = doc.data()!;
      DateTime now = DateTime.now();
      Timestamp? lastOpenTs = data['lastAppOpen'];
      int currentStreak = data['streakCount'] ?? 0;

      if (lastOpenTs != null) {
        DateTime lastOpen = lastOpenTs.toDate();
        int diffInDays = now.difference(DateTime(lastOpen.year, lastOpen.month, lastOpen.day)).inDays;

        if (diffInDays == 1) {
          await docRef.update({
            'streakCount': currentStreak + 1,
            'lastAppOpen': FieldValue.serverTimestamp(),
          });
        } else if (diffInDays > 1) {
          await docRef.update({
            'streakCount': 1,
            'lastAppOpen': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await docRef.set({
          'streakCount': 1,
          'lastAppOpen': FieldValue.serverTimestamp(),
          'xpPoints': 0,
        }, SetOptions(merge: true));
      }
    }
  }

  void _fetchUserName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) setState(() => userName = doc.data()?['name'] ?? "Student");
    }
  }

  // --- STREAK & XP MODULE ---
  Widget _buildStreakXPModule() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        int streak = 0;
        int xp = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          streak = data['streakCount'] ?? 0;
          xp = data['xpPoints'] ?? 0;
        }

        return _buildBaseContainer(
          onTap: () {}, 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text("🔥", style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$streak Day Streak", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Consistency is key!", style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[400])),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF2D5AF0).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFF2D5AF0), size: 18),
                      const SizedBox(width: 5),
                      Text("$xp XP", style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF2D5AF0))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- EFFICIENCY MODULE ---
  Widget _buildOverallProgress() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('habits').snapshots(),
      builder: (context, snapshot) {
        double percentage = 0.0;
        int completed = 0;
        int total = 0;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          total = snapshot.data!.docs.length;
          completed = snapshot.data!.docs.where((doc) => doc['isCompleted'] == true).length;
          percentage = completed / total;
        }

        return _buildBaseContainer(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskGoalScreen())),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60, height: 60,
                      child: CircularProgressIndicator(
                        value: percentage,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFF2D5AF0).withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D5AF0)),
                      ),
                    ),
                    Text("${(percentage * 100).toInt()}%", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D5AF0))),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Daily Efficiency", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(total == 0 ? "No tasks today" : "$completed/$total tasks completed", style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F8), 
      appBar: AppBar(
        title: Text("EduNexus Pro", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 22, color: const Color(0xFF1E293B))),
        centerTitle: false, backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2D5AF0).withOpacity(0.05)))),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back,", style: GoogleFonts.poppins(fontSize: 16, color: Colors.blueGrey)),
                Text(userName, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                
                _buildStreakXPModule(), 
                const SizedBox(height: 15),
                _buildOverallProgress(),
                
                const SizedBox(height: 25),
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18,
                  children: [
                    _buildModuleBlock("Study Hub", Icons.chat_bubble_rounded, const Color(0xFF6C63FF), const AIChatScreen()),
                    _buildModuleBlock("OCR Scanner", Icons.camera_rounded, const Color(0xFF2D5AF0), const OCRScannerScreen()),
                    _buildModuleBlock("Habit Tracker", Icons.auto_graph_rounded, Colors.greenAccent.shade700, const TaskGoalScreen()),
                    _buildModuleBlock("My Notes", Icons.folder_copy_rounded, Colors.pinkAccent, const SavedNotesScreen()),
                    _buildModuleBlock("Timetable", Icons.calendar_month_rounded, Colors.orangeAccent.shade700, const TimetableScreen()),
                    _buildModuleBlock("Courses", Icons.school_rounded, Colors.indigoAccent, const CourseSuggestionScreen()),
                  ],
                ),
                const SizedBox(height: 40),
                Center(child: Text("Consistency breeds excellence.", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleBlock(String title, IconData icon, Color color, Widget screen) {
    return _buildBaseContainer(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBaseContainer({required Widget child, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(onTap: onTap, child: child),
        ),
      ),
    );
  }
}