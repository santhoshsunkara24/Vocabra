import 'package:uuid/uuid.dart';

class WordEntry {
  final String id;
  String? word;
  String? dictionaryMeaning;
  String? simpleMeaning;
  String? usageExample;
  DateTime? dateAdded;
  bool isFavorite;
  String? source; // 'local' | 'api' | 'ai'
  String? pronunciation;


  String get meaning {
    if (dictionaryMeaning != null && dictionaryMeaning!.isNotEmpty) {
      return dictionaryMeaning!;
    }
    return '';
  }

  WordEntry({
    required this.id,
    this.word,
    this.dictionaryMeaning,
    this.simpleMeaning,
    this.usageExample,
    this.dateAdded,
    this.isFavorite = false,
    this.source = 'api',
    this.pronunciation,
  });

  factory WordEntry.create({
    String? word,
    String? dictionaryMeaning,
    String? simpleMeaning,
    String? usageExample,
    String source = 'api',
    String? pronunciation,
  }) {
    return WordEntry(
      id: const Uuid().v4(),
      word: word,
      dictionaryMeaning: dictionaryMeaning,
      simpleMeaning: simpleMeaning,
      usageExample: usageExample,
      dateAdded: DateTime.now(),
      source: source,
      pronunciation: pronunciation,
    );
  }

  WordEntry copyWith({
    String? word,
    String? dictionaryMeaning,
    String? simpleMeaning,
    String? usageExample,
    bool? isFavorite,
    String? source,
    String? pronunciation,
  }) {
    return WordEntry(
      id: id,
      word: word ?? this.word,
      dictionaryMeaning: dictionaryMeaning ?? this.dictionaryMeaning,
      simpleMeaning: simpleMeaning ?? this.simpleMeaning,
      usageExample: usageExample ?? this.usageExample,
      dateAdded: dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      pronunciation: pronunciation ?? this.pronunciation,
    );
  }

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id: map['id'] ?? '',
      word: map['word'],
      dictionaryMeaning: map['formalMeaning'] ?? map['dictionaryMeaning'],
      simpleMeaning: map['simpleMeaning'],
      usageExample: map['usageExample'],
      dateAdded: map['dateAdded'] != null 
          ? DateTime.parse(map['dateAdded']) 
          : null,
      isFavorite: map['isFavorite'] ?? false,
      source: map['source'] ?? 'local',
      pronunciation: map['pronunciation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'formalMeaning': dictionaryMeaning,
      'simpleMeaning': simpleMeaning,
      'usageExample': usageExample,
      'dateAdded': dateAdded?.toIso8601String(),
      'isFavorite': isFavorite,
      'source': source,
      'pronunciation': pronunciation,
    };
  }
}
