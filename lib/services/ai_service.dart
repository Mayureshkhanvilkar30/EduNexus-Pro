class AIService {
  static Future<String> summarizeText(String text) async {
    // 1. Fake Delay (AI jaisa feel dene ke liye)
    await Future.delayed(const Duration(seconds: 2));

    if (text.length < 50) {
      return "• Note: Text is too short to summarize.\n• Key Point: ${text.trim()}";
    }

    // 2. Simple Logic: Pehli 3-4 lines ko points mein badalna
    List<String> sentences = text.split('.');
    String summary = "✨ AI Smart Summary:\n\n";

    for (int i = 0; i < sentences.length && i < 4; i++) {
      if (sentences[i].trim().isNotEmpty) {
        summary += "• ${sentences[i].trim()}\n";
      }
    }

    return summary;
  }
}