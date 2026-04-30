import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = "AIzaSyDhrDNBh8OJczX-dWjcpbWanNhHkolgBwM";
  final baseUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-flash-latest:generateContent";
  
  final prompt = "Hello";
  
  try {
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
        ]
      }),
    );

    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
