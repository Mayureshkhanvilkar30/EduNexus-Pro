import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // Naya import
import 'dart:convert';
import 'dart:ui';

class CourseSuggestionScreen extends StatefulWidget {
  const CourseSuggestionScreen({super.key});

  @override
  State<CourseSuggestionScreen> createState() => _CourseSuggestionScreenState();
}

class _CourseSuggestionScreenState extends State<CourseSuggestionScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _courses = [];
  List<String> _recentSearches = [];
  final user = FirebaseAuth.instance.currentUser;

  final _model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: "AIzaSyADOlj1wtHe37UDm4_iBNEfdMqFA3S31Ss");

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_course_searches') ?? [];
    });
  }

  _saveSearch(String query) async {
    if (query.isEmpty || _recentSearches.contains(query)) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    });
    await prefs.setStringList('recent_course_searches', _recentSearches);
  }

  Future<void> _fetchCourses(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _courses = []; });
    _saveSearch(query);

    final prompt = "Suggest 4 best online courses for: $query. Return ONLY a JSON array. "
        "Each object must have: 'name', 'platform', 'price', and 'link'.";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      String cleanText = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      setState(() {
        _courses = jsonDecode(cleanText);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error fetching courses")));
    }
  }

  // --- UPDATED ENROLL + REDIRECT LOGIC ---
  Future<void> _enrollAndRedirect(String courseName, String courseUrl) async {
    if (user != null) {
      // 1. Database Update
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'currentCourse': courseName,
        'courseProgress': 0.1,
      });

      // 2. Browser Open
      final Uri url = Uri.parse(courseUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open course link")));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enrolled and redirecting to $courseName"), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F3F8),
      appBar: AppBar(
        title: Text("Find Courses", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSearchBar(),
          ),
          if (_recentSearches.isNotEmpty) _buildRecentSearchSection(),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5AF0)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCard(_courses[index]);
                  },
                ),
          ),
          _buildStickyEnrolledTab(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "Search courses (e.g. Flutter, Java...)",
          hintStyle: GoogleFonts.poppins(fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2D5AF0)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF2D5AF0)),
            onPressed: () => _fetchCourses(_controller.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: _fetchCourses,
      ),
    );
  }

  Widget _buildRecentSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Text("Recent Searches", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            children: _recentSearches.map((query) => GestureDetector(
              onTap: () {
                _controller.text = query;
                _fetchCourses(query);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8), 
                  borderRadius: BorderRadius.circular(15), 
                  border: Border.all(color: Colors.blue.withOpacity(0.1))
                ),
                child: Center(child: Text(query, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF2D5AF0)))),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(dynamic course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(course['platform'] ?? "Online", style: GoogleFonts.poppins(color: const Color(0xFF2D5AF0), fontWeight: FontWeight.bold, fontSize: 12)),
              Text(course['price'] ?? "Free", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(course['name'] ?? "Course Title", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () => _enrollAndRedirect(course['name'], course['link']),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5AF0),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text("Enroll Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildStickyEnrolledTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String? course = data['currentCourse'];
        if (course == null || course == "" || course == "Find a Course") return const SizedBox();

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8), 
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_added, color: Color(0xFF2D5AF0)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ACTIVE ENROLLMENT", style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                        Text(course, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}