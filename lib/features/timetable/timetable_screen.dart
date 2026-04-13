import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String _selectedDay = 'Mon';
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  TimeOfDay? _pickedTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2D5AF0)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _pickedTime = picked;
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _timeController.text = DateFormat.jm().format(dt);
      });
    }
  }

  // --- SMART NOTIFICATION LOGIC ---
  void _addSchedule() async {
    if (_taskController.text.isEmpty || _pickedTime == null) return;

    String subject = _taskController.text.trim();
    String timeStr = _timeController.text.trim();

    DateTime now = DateTime.now();

    // 1. Calculate karna ki selected day kab aayega
    // Index: Mon=0...Sun=6. DateTime weekday: Mon=1...Sun=7
    int targetWeekday = _days.indexOf(_selectedDay) + 1;
    int currentWeekday = now.weekday;

    int daysUntilTarget = (targetWeekday - currentWeekday + 7) % 7;

    // 2. Scheduled date fix karna
    DateTime scheduledTime = DateTime(
        now.year, now.month, now.day, _pickedTime!.hour, _pickedTime!.minute, 0
    ).add(Duration(days: daysUntilTarget));

    // 3. Agar aaj hi wo din hai aur time nikal gaya, toh agle hafte (7 din baad) bhejo
    if (daysUntilTarget == 0 && scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    }

    // Firestore mein save
    await FirebaseFirestore.instance.collection('timetable').add({
      'day': _selectedDay,
      'subject': subject,
      'time': timeStr,
      'userId': user?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Notification Schedule karna
    await NotificationService.scheduleNotification(
      subject.hashCode,
      "Study Time: $subject 📖",
      "Hey Mayuresh, it's time for your $subject class on $_selectedDay!",
      scheduledTime,
    );

    if (mounted) {
      _taskController.clear();
      _timeController.clear();
      _pickedTime = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Reminder set for every $_selectedDay at $timeStr ✅"),
          backgroundColor: const Color(0xFF2D5AF0),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("My Timetable", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedDay == _days[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = _days[index]),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2D5AF0) : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                    ),
                    child: Center(
                      child: Text(_days[index], style: GoogleFonts.poppins(color: isSelected ? Colors.white : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('timetable').where('userId', isEqualTo: user?.uid).where('day', isEqualTo: _selectedDay).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text("No classes for $_selectedDay", style: GoogleFonts.poppins(color: Colors.grey)));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFF1F4FF), child: Icon(Icons.menu_book_rounded, color: Color(0xFF2D5AF0), size: 20)),
                        title: Text(data['subject'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text(data['time'], style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey)),
                        trailing: IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent), onPressed: () => data.reference.delete()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: const Color(0xFF2D5AF0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text("Add Class", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add Schedule for $_selectedDay", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: "Subject Name",
                prefixIcon: const Icon(Icons.book),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _timeController,
              readOnly: true,
              onTap: () => _selectTime(context),
              decoration: InputDecoration(
                labelText: "Select Time",
                hintText: "Tap to open clock",
                prefixIcon: const Icon(Icons.alarm),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
            onPressed: _addSchedule,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5AF0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Set Reminder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}