import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = "AIzaSyA9XCVlnETGZcEh86KnwUY2vFD_63P9PlM";
  // Using gemini-1.5-flash for higher free-tier quota (1,500 RPM / 1M TPM)
  static const String baseUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent";

  static Future<String?> _generateContent(String prompt, {String logPrefix = "Gemini Response"}) async {
    try {
      print("🧠 Gemini Request [$logPrefix] prompt length: ${prompt.length}");
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey.trim(),
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"}
          ],
          "generationConfig": {
            "temperature": 0.5,
            "maxOutputTokens": 400,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print("❌ Gemini API ERROR [$logPrefix]: ${response.statusCode}");
        print("❌ Gemini Error Body: ${response.body}");
        return null;
      }

      final data = jsonDecode(response.body);
      if (data["candidates"] == null || 
          (data["candidates"] as List).isEmpty || 
          data["candidates"][0]["content"] == null || 
          data["candidates"][0]["content"]["parts"] == null || 
          (data["candidates"][0]["content"]["parts"] as List).isEmpty) {
        return null;
      }

      return data["candidates"][0]["content"]["parts"][0]["text"].toString().trim();
    } catch (e) {
      print("❌ $logPrefix error: $e");
      return null;
    }
  }

  static Future<String> generatePronunciation(String word, {String? ipa}) async {
    String prompt;
    if (ipa != null && ipa.isNotEmpty) {
      prompt = 'Convert the IPA pronunciation "$ipa" for the word "$word" into a syllable-based phonetic spelling. \nRules:\n1. Use " · " as syllable separator.\n2. Use ALL CAPS for the stressed syllable.\n3. Provide ONLY the result (e.g. "ar · TIK · yuh · luht"). No other text.';
    } else {
      prompt = 'How do you pronounce "$word"? Provide ONLY the syllable breakdown (e.g. "ar · TIK · yuh · luht"). No other text.';
    }

    final text = await _generateContent(prompt, logPrefix: "Pronunciation");
    
    String pron = "Not available";

    if (text != null && text.isNotEmpty) {
      pron = text.trim().replaceAll('*', '');
      // Clean up common prefix if Gemini adds it despite instructions
      if (pron.toLowerCase().contains("pronunciation:")) {
        pron = pron.split(RegExp(r'pronunciation:', caseSensitive: false)).last.trim();
      }
      pron = pron.replaceAll(RegExp(r'[^a-zA-Z ·]'), '').trim();
    }

    if (pron.isEmpty || pron.toLowerCase() == word.toLowerCase()) pron = "Not available";
    
    return pron;
  }

  static Future<Map<String, String>> generateAIExtras(String word) async {
    final prompt = """
    Explain the word "$word" for a dictionary application.
    Return a JSON object with exactly these keys:
    1. "formal_definition": A standard, precise dictionary definition.
    2. "simple_meaning": A very simple, easy-to-understand explanation for a child or beginner.
    3. "usage_example": One natural-sounding example sentence using the word.
    
    JSON format only:
    {
      "formal_definition": "...",
      "simple_meaning": "...",
      "usage_example": "..."
    }
    """;final text = await _generateContent(prompt, logPrefix: "AIExtras");
    
    if (text != null && text.isNotEmpty) {
      try {
        // Clean up JSON if Gemini adds markdown blocks
        String jsonStr = text.trim();
        if (jsonStr.contains("```")) {
          jsonStr = jsonStr.split("```")[1];
          if (jsonStr.startsWith("json")) jsonStr = jsonStr.substring(4);
          jsonStr = jsonStr.trim();
        }
        
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return {
          "formal_definition": data["formal_definition"] ?? "Not available",
          "simple_meaning": data["simple_meaning"] ?? "Not available",
          "usage_example": data["usage_example"] ?? "Not available",
        };
      } catch (e) {
        print("❌ Error parsing AI JSON: $e");
      }
    }
    
    return {
      "simple_meaning": "Not available",
      "usage_example": "Not available",
    };
  }
}
