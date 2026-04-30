import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  // New API provider as requested by the user
  static const String _baseUrl = 'https://freedictionaryapi.com/api/v1/entries/en/';

  static Future<Map<String, dynamic>?> fetchFullData(String word) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl${Uri.encodeComponent(word)}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> root = json.decode(response.body);
        final List<dynamic> entries = root['entries'] as List<dynamic>? ?? [];
        
        if (entries.isNotEmpty) {
          final firstEntry = entries[0] as Map<String, dynamic>;
          
          // Extract meanings from "senses"
          final List<String> meaningsList = [];
          final senses = firstEntry['senses'] as List<dynamic>? ?? [];
          for (var s in senses) {
            if (s['definition'] != null) {
              meaningsList.add(s['definition']);
            }
          }

          // Extract phonetic from "pronunciations"
          String? ipa;
          final pronunciations = firstEntry['pronunciations'] as List<dynamic>? ?? [];
          for (var p in pronunciations) {
            if (p['transcription'] != null && (p['transcription'] as String).isNotEmpty) {
              ipa = p['transcription'];
              // We could check for specific tags like "Received Pronunciation" here if needed
              break; 
            }
          }

          return {
            'meanings': meaningsList,
            'phonetic': ipa,
          };
        }
      }
    } catch (e) {
      print('❌ DictionaryService Error: $e');
    }
    return null;
  }

  // Backward compatibility
  static Future<List<String>> fetchMeanings(String word) async {
    final data = await fetchFullData(word);
    return (data?['meanings'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  // Backward compatibility
  static Future<String?> fetchPhonetic(String word) async {
    final data = await fetchFullData(word);
    return data?['phonetic'] as String?;
  }
}
