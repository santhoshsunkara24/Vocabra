import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get apiKey => dotenv.get('GEMINI_API_KEY', fallback: '');
  // Using gemini-2.0-flash for higher free-tier quota (1,500 RPM / 1M TPM)
  static const String baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

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
            "temperature": 0.4,
            "maxOutputTokens": 500,
            "responseMimeType": "application/json"
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
    Return a JSON object with exactly these keys: "formal_definition", "simple_meaning", "usage_example".
    Strict Rules:
    1. No trailing commas.
    2. Escape all quotes inside strings.
    3. Return ONLY the JSON object.
    
    Format:
    {
      "formal_definition": "precise definition",
      "simple_meaning": "kid-friendly explanation",
      "usage_example": "sentence using the word"
    }
    """;final text = await _generateContent(prompt, logPrefix: "AIExtras");
    
    if (text != null && text.isNotEmpty) {
      try {
        // Robust JSON extraction
        String jsonStr = text.trim();
        final firstBrace = jsonStr.indexOf('{');
        final lastBrace = jsonStr.lastIndexOf('}');
        
        if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
          jsonStr = jsonStr.substring(firstBrace, lastBrace + 1);
        }
        
        // Repair common JSON issues (like trailing commas)
        jsonStr = jsonStr.replaceAll(RegExp(r',\s*([\]}])'), r'$1');
        
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
