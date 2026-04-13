import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../services/notification_service.dart'; // Apna service import karo

class TaskGoalScreen extends StatefulWidget {
  const TaskGoalScreen({super.key});

  @override
  State<TaskGoalScreen> createState() => _TaskGoalScreenState();
}

class _TaskGoalScreenState extends State<TaskGoalScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // --- 1. MANUAL ADD LOGIC WITH NOTIFICATION ---
  void _showAddHabitSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 25, right: 25, top: 25,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text("Create New Habit", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "What's your goal?",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: timeController,
                readOnly: true,
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (pickedTime != null) {
                    setState(() => timeController.text = pickedTime.format(context));
                  }
                },
                decoration: InputDecoration(
                  hintText: "Set Time (Optional)",
                  prefixIcon: const Icon(Icons.access_time_filled, color: Color(0xFF2D5AF0)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty && user != null) {
                    final habitName = nameController.text;
                    final habitTime = timeController.text.isEmpty ? "Anytime" : timeController.text;

                    // 1. Save to Firestore
                    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('habits').add({
                      'name': habitName,
                      'time': habitTime,
                      'isCompleted': false,
                      'progress': 0.0,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    // 2. Schedule Notification
                    if (habitTime != "Anytime") {
                      DateTime scheduledDate = NotificationService.parseTimeString(habitTime);
                      NotificationService.scheduleNotification(
                        DateTime.now().millisecond,
                        "Habit Reminder! 📚",
                        "Time to start: $habitName",
                        scheduledDate,
                      );
                    }

                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5AF0),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text("Add Habit", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. DELETE LOGIC ---
  Future<void> _deleteHabit(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('habits').doc(docId).delete();
  }

  // --- 3. TOGGLE STATUS ---
  Future<void> _toggleHabitStatus(String docId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('habits').doc(docId).update({
      'isCompleted': !currentStatus,
      'progress': !currentStatus ? 1.0 : 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Habit Tracker", style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
      ),
      body: Stack(
        children: [
          Positioned(top: 150, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.05)))),
          
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeeklyCalendar(),
                const SizedBox(height: 30),
                Text("Daily Tasks", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                const SizedBox(height: 15),
                
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('habits').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text("No habits yet.\nAdd manually or ask AI!", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey)),
                      ));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.data!.docs[index];
                        var habit = doc.data() as Map<String, dynamic>;

                        // --- SWIPE TO DELETE INTEGRATION ---
                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(28)),
                            child: const Icon(Icons.delete_sweep, color: Colors.white),
                          ),
                          onDismissed: (direction) => _deleteHabit(doc.id),
                          child: _buildHabitCard(doc.id, habit),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildSyncStatus(),
              ],
            ),
          ),
          
          Positioned(
            bottom: 30, left: 30, right: 30,
            child: InkWell(
              onTap: _showAddHabitSheet,
              child: _buildGlossyContainer(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, color: Color(0xFF2D5AF0)),
                    const SizedBox(width: 10),
                    Text("Add Habit Manually", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2D5AF0))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI Methods same as before...
  Widget _buildWeeklyCalendar() {
    return _buildGlossyContainer(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          DateTime now = DateTime.now();
          DateTime day = now.add(Duration(days: index - 3));
          bool isToday = index == 3;
          return Column(
            children: [
              Text(["M", "T", "W", "T", "F", "S", "S"][day.weekday - 1], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF2D5AF0) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text("${day.day}", style: TextStyle(color: isToday ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHabitCard(String docId, Map<String, dynamic> habit) {
    bool isDone = habit['isCompleted'] ?? false;
    double progress = (habit['progress'] ?? 0.0).toDouble();
    Color themeColor = isDone ? Colors.greenAccent.shade700 : const Color(0xFF2D5AF0);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: _buildGlossyContainer(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: themeColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                ),
                Icon(isDone ? Icons.check : Icons.access_time_filled_rounded, size: 15, color: themeColor),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit['name'] ?? "New Task", 
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : const Color(0xFF1E293B)
                    )),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: Colors.blueGrey[300]),
                      const SizedBox(width: 4),
                      Text(habit['time'] ?? "Anytime", style: GoogleFonts.poppins(fontSize: 11, color: Colors.blueGrey[400])),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: isDone ? Colors.green : Colors.grey.shade400),
              onPressed: () => _toggleHabitStatus(docId, isDone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text("AI-Sync & Smart Reminders Active", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildGlossyContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}