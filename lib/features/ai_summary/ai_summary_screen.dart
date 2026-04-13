import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AISummaryScreen extends StatelessWidget {
  const AISummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text("AI Summaries", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIXED: Agar red screen aaye toh 'orderBy' wali line ko temporary comment kar dein
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Error Handling
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error: ${snapshot.error}\n\nTip: Check if Firestore Index is created.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          // 2. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No AI summaries yet.", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // 4. Safe Data Mapping (Bad State se bachne ke liye)
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String summary = data.containsKey('summary') ? data['summary'] : "No summary available";
              String title = data.containsKey('title') ? data['title'] : "Untitled Note";

              // Agar sirf scan hai, summary nahi, toh list mein skip karein
              if (summary == "No summary generated") return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
                child: ExpansionTile(
                  leading: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                  title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("AI Generated", style: GoogleFonts.poppins(fontSize: 11)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        summary,
                        style: GoogleFonts.poppins(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}