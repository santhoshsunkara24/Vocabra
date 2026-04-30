import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'YOUR_API_KEY_HERE'; // Replace with your key
  
  final model = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: 'AIzaSyDhrDNBh8OJczX-dWjcpbWanNhHkolgBwM',
  );

  final prompt = 'How do you pronounce "ephemeral"? Provide ONLY the syllable breakdown (e.g. "ar · TIK · yuh · luht"). No other text.';
  
  print('--- Testing Gemini 3 Flash Preview ---');
  try {
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    print('Response: ${response.text}');
  } catch (e) {
    print('Error: $e');
  }
}