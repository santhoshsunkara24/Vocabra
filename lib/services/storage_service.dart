import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String key = "words";

  static Future<void> saveWord(Map<String, dynamic> word) async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(word));

    await prefs.setStringList(key, existing);
  }

  static Future<List<Map<String, dynamic>>> getWords() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(key) ?? [];

    return data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
  static Future<void> deleteWord(String id) async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(key) ?? [];

    final updated = data.where((item) {
      final decoded = jsonDecode(item);
      return decoded["id"] != id;
    }).toList();

    await prefs.setStringList(key, updated);
  }

  static Future<void> updateWord(Map<String, dynamic> updatedWord) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];

    final idToUpdate = updatedWord["id"];
    
    final updatedList = data.map((item) {
      final decoded = jsonDecode(item);
      if (decoded["id"] == idToUpdate) {
        return jsonEncode(updatedWord);
      }
      return item;
    }).toList();

    await prefs.setStringList(key, updatedList);
  }
}
