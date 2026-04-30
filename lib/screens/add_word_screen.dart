import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/dictionary_service.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';

class AddWordScreen extends StatefulWidget {
  final String? prefilledWord;
  final WordEntry? wordEntry;
  const AddWordScreen({super.key, this.prefilledWord, this.wordEntry});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final TextEditingController wordController = TextEditingController();
  final TextEditingController formalController = TextEditingController();
  final TextEditingController simpleController = TextEditingController();
  final TextEditingController usageController = TextEditingController();
  
  List<String> meanings = [];
  String _pronunciation = "";
  bool _isSearching = false;
  int selectedIndex = 0;
  Timer? _debounceTimer;

  bool get isEditing => widget.wordEntry != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      wordController.text = widget.wordEntry!.word ?? "";
      formalController.text = widget.wordEntry!.dictionaryMeaning ?? "";
      simpleController.text = widget.wordEntry!.simpleMeaning ?? "";
      usageController.text = widget.wordEntry!.usageExample ?? "";
      _pronunciation = widget.wordEntry!.pronunciation ?? "";
    } else if (widget.prefilledWord != null) {
      wordController.text = widget.prefilledWord!;
      _fetchWordData(widget.prefilledWord!);
    }
  }

  @override
  void dispose() {
    wordController.dispose();
    formalController.dispose();
    simpleController.dispose();
    usageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Note: Background word discovery has been removed to conserve AI quota.
  // Triggers are now exclusively on keyboard "Done" action.

  Future<void> _fetchWordData(String searchWord) async {
    if (searchWord.isEmpty) return;

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }
    
    try {
      // 1. Fetch Dictionary data (Meanings + IPA) in ONE call
      DictionaryService.fetchFullData(searchWord).timeout(const Duration(seconds: 10), onTimeout: () => null).then((data) {
        if (!mounted || searchWord != wordController.text.trim()) return;

        final resultsList = (data?['meanings'] as List<dynamic>?)?.cast<String>() ?? [];
        final ipa = data?['phonetic'] as String?;

        setState(() {
          meanings = resultsList.take(3).toList();
          if (resultsList.isNotEmpty && formalController.text.isEmpty) {
            formalController.text = resultsList[0];
          }
          _isSearching = false;
        });

        // 2. Fetch AI pronunciation using the IPA
        GeminiService.generatePronunciation(searchWord, ipa: ipa).timeout(const Duration(seconds: 10)).then((geminiData) {
          if (!mounted || searchWord != wordController.text.trim()) return;
          setState(() {
            _pronunciation = geminiData;
          });
        });

        // 3. Fetch AI extras
        GeminiService.generateAIExtras(searchWord).then((aiExtras) {
          if (!mounted || searchWord != wordController.text.trim()) return;
          setState(() {
            // Fallback for formal definition if meanings list is empty
            if (formalController.text.isEmpty || meanings.isEmpty) {
              formalController.text = aiExtras["formal_definition"] ?? "";
            }
            if (simpleController.text.isEmpty) simpleController.text = aiExtras["simple_meaning"] ?? "";
            if (usageController.text.isEmpty) usageController.text = aiExtras["usage_example"] ?? "";
          });
        });
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _saveWord() async {
    final word = wordController.text.trim();
    if (word.isEmpty) return;

    final Map<String, dynamic> wordData = {
      'word': word,
      'formalMeaning': formalController.text.trim(),
      'simpleMeaning': simpleController.text.trim(),
      'usageExample': usageController.text.trim(),
      'pronunciation': _pronunciation,
      'dateAdded': DateTime.now().toIso8601String(),
    };

    if (isEditing) {
      wordData['id'] = widget.wordEntry!.id;
      await StorageService.updateWord(wordData);
    } else {
      await StorageService.saveWord(wordData);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEditing ? 'Edit Word' : 'Add New Word', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Word"),
            TextField(
              controller: wordController,
              onSubmitted: (value) {
                if (value.trim().length >= 2) {
                  _fetchWordData(value.trim());
                }
              },
              textInputAction: TextInputAction.next,
              style: GoogleFonts.instrumentSerif(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: "Enter word...",
                hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 18),
                fillColor: Colors.transparent,
                filled: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_pronunciation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Row(
                  children: [
                    Text(
                      _pronunciation, 
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF2563EB).withOpacity(0.8),
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB), size: 24),
                      onPressed: () => TTSService.speak(wordController.text),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 32),

            _buildSectionLabel("Formal definition"),
            TextField(
              controller: formalController,
              maxLines: null,
              readOnly: true,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "Dictionary meaning...",
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                fillColor: const Color(0xFF1A1A1A),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionLabel("Simple meaning"),
            TextField(
              controller: simpleController,
              maxLines: null,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "Short child-friendly meaning...",
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                fillColor: const Color(0xFF1A1A1A),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionLabel("Usage example"),
            TextField(
              controller: usageController,
              maxLines: null,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: "A sentence using the word...",
                hintStyle: GoogleFonts.outfit(color: Colors.white24),
                fillColor: const Color(0xFF1A1A1A),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _saveWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Update word' : 'Save to vault', 
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label, 
        style: GoogleFonts.outfit(
          color: const Color(0xFF2563EB).withOpacity(0.9),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}