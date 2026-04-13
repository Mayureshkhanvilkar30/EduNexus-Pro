import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CareerRoadmapScreen extends StatefulWidget {
  const CareerRoadmapScreen({super.key});

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _dynamicRoadmap = [];

  // API KEY & STABLE MODEL
  static const String _apiKey = "AIzaSyBzsX504qDnXoqvIrxaGHszPYTIP1xkeAE";

  // FIX: Using 'gemini-pro' as a fallback if '1.5-flash' shows error
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-tts', // Agar error aaye toh yahan 'gemini-pro' likh dena
      apiKey: _apiKey,
    );
  }

  Future<void> _generateRoadmap() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _dynamicRoadmap = [];
    });

    final prompt = "Give me a 5-step career roadmap for '${_searchController.text}'. "
        "Format each step exactly as: Title | Description. "
        "Example: Step Title | Step Detail.";

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        List<String> lines = response.text!.trim().split('\n');
        List<Map<String, dynamic>> tempRoadmap = [];

        for (var line in lines) {
          if (line.contains('|')) {
            var parts = line.split('|');
            tempRoadmap.add({
              "title": parts[0].trim().replaceAll('*', ''),
              "desc": parts[1].trim(),
            });
          }
        }

        setState(() {
          _dynamicRoadmap = tempRoadmap;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API ERROR: $e");
      setState(() => _isLoading = false);

      // Agar 'model not found' error hai, toh pro model try karo
      if (e.toString().contains('model')) {
        _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
        _generateRoadmap(); // Retry once
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("AI Connection failed. Try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("AI Career Navigator", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true, elevation: 0.5, backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _dynamicRoadmap.isEmpty
                ? _buildEmptyState()
                : _buildAnimatedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Enter Career (e.g. Game Developer)",
          prefixIcon: const Icon(Icons.auto_fix_high),
          suffixIcon: IconButton(icon: const Icon(Icons.send), onPressed: _generateRoadmap),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onSubmitted: (_) => _generateRoadmap(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("Search your future with AI", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAnimatedList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: _dynamicRoadmap.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 200)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: _buildRoadmapStep(index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoadmapStep(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(radius: 15, backgroundColor: Colors.indigo, child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12))),
            if (index < _dynamicRoadmap.length - 1) Container(width: 2, height: 60, color: Colors.indigo.withOpacity(0.2)),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dynamicRoadmap[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(_dynamicRoadmap[index]['desc'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}