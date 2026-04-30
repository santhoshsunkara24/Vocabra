import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = "AIzaSyDhrDNBh8OJczX-dWjcpbWanNhHkolgBwM";
  final url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey";
  
  try {
    final response = await http.get(Uri.parse(url));
    print('Status Code: ${response.statusCode}');
    final data = jsonDecode(response.body);
    if (data['models'] != null) {
      for (var model in data['models']) {
        if (model['name'].contains('gemini')) {
          print(model['name']);
        }
      }
    } else {
      print(response.body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
