import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isNotificationEnabled = value);
    await prefs.setBool('notifications_enabled', value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "Notifications Enabled" : "Notifications Disabled"),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D5AF0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // --- FIX 1: Prevent crash if user is null during transition ---
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Settings",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.5),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: -50,
            child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2D5AF0).withOpacity(0.05))),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 30),
            child: Column(
              children: [
                // --- PROFILE SECTION ---
                _buildGlossyContainer(
                  padding:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF2D5AF0),
                          child: Text(
                            // --- FIX 2: Null safe substring check ---
                            (user.displayName != null && user.displayName!.isNotEmpty)
                                ? user.displayName!.substring(0, 1).toUpperCase()
                                : "S",
                            style: const TextStyle(
                                fontSize: 35,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        user.displayName ?? "Student Name",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        user.email ?? "student@edunexus.com",
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.blueGrey[400]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- OPTIONS LIST ---
                _buildGlossyContainer(
                  child: Column(
                    children: [
                      _buildSettingTile(
                        icon: Icons.notifications_active_outlined,
                        title: "Study Reminders",
                        color: Colors.orangeAccent,
                        trailing: Switch.adaptive(
                          value: _isNotificationEnabled,
                          onChanged: _toggleNotification,
                          activeColor: const Color(0xFF2D5AF0),
                        ),
                      ),
                      _buildDivider(),
                      _buildSettingTile(
                        icon: Icons.person_outline,
                        title: "Edit Profile",
                        color: Colors.blueAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfileScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingTile(
                        icon: Icons.feedback_outlined,
                        title: "Send Feedback",
                        color: Colors.teal.shade400,
                        onTap: () => _showFeedbackDialog(context),
                      ),
                      _buildDivider(),
                      _buildSettingTile(
                        icon: Icons.info_outline,
                        title: "About EduNexus",
                        color: Colors.purpleAccent,
                        onTap: () => _showAboutApp(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- LOGOUT ---
                _buildGlossyContainer(
                  child: _buildSettingTile(
                    icon: Icons.logout_rounded,
                    title: "Logout Session",
                    color: Colors.redAccent,
                    onTap: () => FirebaseAuth.instance.signOut(),
                  ),
                ),

                const SizedBox(height: 30),
                Text("Version 1.0.0 • Developed by Mayuresh",
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GLOSSY BUILDER ---
  Widget _buildGlossyContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
      {required IconData icon,
      required String title,
      required Color color,
      Widget? trailing,
      VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155))),
      trailing:
          trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildDivider() => Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.withOpacity(0.1),
      indent: 60);

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("Feedback",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "How can we help?",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5AF0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutApp(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "EduNexus",
      applicationVersion: "1.0.0",
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.school, color: Color(0xFF2D5AF0), size: 40),
      ),
      children: [
        const SizedBox(height: 15),
        Text(
          "EduNexus is a Smart AI Study Assistant that helps students organize notes, scan documents, and manage study schedules effectively.",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        const SizedBox(height: 15),
        Text("Key Features:",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Text("• AI Note Summarization\n• OCR Document Scanning\n• Smart Timetable & Alerts",
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.black87, height: 1.5)),
        const Divider(height: 30),
        Text("Developed By:",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        Text(
          "Mayuresh Khanvilkar",
          style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D5AF0)),
        ),
        const SizedBox(height: 5),
        Text("Tech: Flutter | Firebase | ML Kit",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueGrey)),
      ],
    );
  }
}