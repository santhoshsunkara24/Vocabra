import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyA9XCVlnETGZcEh86KnwUY2vFD_63P9PlM';
  
  final model = GenerativeModel(
    model: 'gemini-2.5-flash-lite',
    apiKey: apiKey,
  );

  final prompt = 'How do you pronounce "ephemeral"? Provide ONLY the syllable breakdown (e.g. "ar · TIK · yuh · luht"). No other text.';
  
  print('--- Testing Gemini 1.5 Flash ---');
  try {
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    print('Response: ${response.text}');
  } catch (e) {
    print('Error: $e');
  }
}