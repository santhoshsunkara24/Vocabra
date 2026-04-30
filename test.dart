import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("❌ Could not load .env file. Make sure it exists in the root directory.");
    return;
  }

  final apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
  
  if (apiKey.isEmpty) {
    print("❌ GEMINI_API_KEY not found in .env file.");
    return;
  }

  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  final prompt = 'How do you pronounce "ephemeral"? Provide ONLY the syllable breakdown (e.g. "ar · TIK · yuh · luht"). No other text.';
  
  print('--- Testing Gemini 2.5 Flash ---');
  try {
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    print('Response: ${response.text}');
  } catch (e) {
    print('Error: $e');
  }
}