import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../services/gemini_service.dart';
import '../services/dictionary_service.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import 'word_detail_screen.dart';
import '../services/tts_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _savedWords = [];
  List<Map<String, dynamic>> _filteredWords = [];
  List<String> _dictionaryResults = [];
  bool _isLoading = false;
  int _selectedMeaningIndex = 0;
  WordEntry? _discoveryResult;
  String _loadingMessage = "Making it simple to understand...";
  bool _anySaved = false;

  final Map<String, WordEntry> _sessionCache = {};

  // Voice Search
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // Editing discovery results
  final TextEditingController _formalController = TextEditingController();
  final TextEditingController _simpleController = TextEditingController();
  final TextEditingController _usageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedWords();
    
    // Auto-search if initial query provided
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchController.text = widget.initialQuery!;
        _startDiscoveryFlow(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _formalController.dispose();
    _simpleController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // Optionally trigger search automatically when confidence is high and done speaking
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_searchController.text.isNotEmpty) {
        _startDiscoveryFlow(_searchController.text.trim());
      }
    }
  }

  Future<void> _loadSavedWords() async {
    final words = await StorageService.getWords();
    if (mounted) {
      setState(() {
        _savedWords = words;
        _filteredWords = words;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredWords = _savedWords;
          _discoveryResult = null;
          _isLoading = false;
        });
      }
      return;
    }

    final queryLower = query.toLowerCase();
    
    // 1. FAST Local Search (Instant filtering of your vault)
    final filtered = _savedWords.where((word) {
      final wordTitle = (word['word'] ?? "").toString().toLowerCase();
      return wordTitle.contains(queryLower);
    }).toList();

    if (mounted) {
      setState(() {
        _filteredWords = filtered;
        // IMPORTANT: We do NOT clear _discoveryResult here anymore 
        // to prevent flickering while typing an existing word.
      });
    }
  }

  Future<void> _startDiscoveryFlow(String query) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadingMessage = "Making it simple to understand...";
        _discoveryResult = WordEntry.create(
          word: query,
          dictionaryMeaning: "Checking dictionary...",
          pronunciation: "...",
        );
      });
    }

    // Fetch Dictionary data (Meanings + IPA) in ONE call
    DictionaryService.fetchFullData(query).timeout(const Duration(seconds: 7), onTimeout: () => null).then((data) async {
      if (!mounted || _searchController.text.trim().toLowerCase() != query.toLowerCase()) return;

      final dictResults = (data?['meanings'] as List<dynamic>?)?.cast<String>() ?? [];
      final ipa = data?['phonetic'] as String?;

      setState(() {
        _dictionaryResults = dictResults;
        _discoveryResult = WordEntry.create(
          word: query,
          dictionaryMeaning: dictResults.isNotEmpty ? dictResults.first : "No formal definition found.",
          pronunciation: _discoveryResult?.pronunciation ?? "...",
        );
      });

      // Now trigger AI for pronunciation and extras
      try {
        // Run AI tasks in parallel
        final results = await Future.wait([
          GeminiService.generatePronunciation(query, ipa: ipa),
          GeminiService.generateAIExtras(query),
        ]);
        
        final String geminiPron = results[0] as String;
        final Map<String, String> aiExtras = results[1] as Map<String, String>;
        
        if (!mounted || _searchController.text.trim().toLowerCase() != query.toLowerCase()) return;

        // Use AI formal definition if dictionary failed or returned generic error message
        String formalDef = _discoveryResult?.dictionaryMeaning ?? "No formal definition found.";
        if (formalDef == "No formal definition found." || formalDef.isEmpty) {
          formalDef = aiExtras["formal_definition"] ?? formalDef;
        }

        final finalEntry = WordEntry.create(
          word: query,
          dictionaryMeaning: formalDef,
          simpleMeaning: aiExtras["simple_meaning"],
          usageExample: aiExtras["usage_example"],
          pronunciation: geminiPron,
        );

        setState(() {
          _discoveryResult = finalEntry;
          _formalController.text = finalEntry.dictionaryMeaning ?? "";
          _simpleController.text = finalEntry.simpleMeaning ?? "";
          _usageController.text = finalEntry.usageExample ?? "";
          _isLoading = false;
          _sessionCache[query.toLowerCase()] = finalEntry;
        });
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }).catchError((e) {
       if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _saveResult() async {
    if (_discoveryResult == null) return;

    final wordData = {
      "word": _discoveryResult!.word,
      "formalMeaning": _formalController.text.trim(),
      "simpleMeaning": _simpleController.text.trim(),
      "usageExample": _usageController.text.trim(),
      "pronunciation": _discoveryResult!.pronunciation,
    };

    await StorageService.saveWord(wordData);
    _anySaved = true;
    await _loadSavedWords(); // Refresh local list
    
    if (mounted) {
      setState(() {
        _discoveryResult = null;
        _searchController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to your vault'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) return;
          Navigator.pop(context, _anySaved);
        },
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: const Color(0xFF0B0B0B),
              elevation: 0,
              toolbarHeight: 48,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context, _anySaved),
              ),
            ),
            
            // Search Input Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) {
                    if (value.trim().length >= 2) {
                      _startDiscoveryFlow(value.trim());
                    }
                  },
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Discover or search...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white30),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_rounded, 
                        color: _isListening ? Colors.redAccent : const Color(0xFF2563EB)
                      ),
                      onPressed: _listen,
                    ),
                    fillColor: const Color(0xFF1A1A1A),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), 
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), 
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),
            ),

            // Main Content Area
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildLoadingCard(),
                ),
              )
            else if (_discoveryResult != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: _buildDiscoveryCard(),
                ),
              ),

            // Saved Words Header
            if (!_isLoading && _discoveryResult == null && _filteredWords.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: Text(
                    'Results',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF2563EB).withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

            // Saved/Filtered Words List
            if (!_isLoading && _discoveryResult == null && _filteredWords.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final word = _filteredWords[index];
                      if (index >= _filteredWords.length) return null;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildLexiResultCard(word),
                      );
                    },
                    childCount: _filteredWords.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: Color(0xFF2563EB), strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(_loadingMessage, style: GoogleFonts.outfit(color: const Color(0xFF2563EB), fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _discoveryResult!.word ?? "",
                      style: GoogleFonts.instrumentSerif(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    if (_discoveryResult!.pronunciation != null && _discoveryResult!.pronunciation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _discoveryResult!.pronunciation!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF2563EB).withOpacity(0.8),
                            fontSize: 17,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => TTSService.speak(_discoveryResult!.word ?? ""),
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB), size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDiscoverySection("Formal definition", _formalController, isEditable: false),
          const SizedBox(height: 28),
          _buildDiscoverySection("Simple meaning", _simpleController, isEditable: true),
          const SizedBox(height: 28),
          _buildDiscoverySection("Usage example", _usageController, isEditable: true),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _saveResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: Text('Save to vault', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 17)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverySection(String label, TextEditingController controller, {bool isEditable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF2563EB).withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        if (isEditable)
          TextField(
            controller: controller,
            maxLines: null,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label...',
              hintStyle: GoogleFonts.outfit(color: Colors.white24),
              fillColor: const Color(0xFF151515).withOpacity(0.5),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF151515).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              controller.text,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLexiResultCard(Map<String, dynamic> word) {
    return GestureDetector(
      onTap: () {
        final entry = WordEntry.fromMap({
          ...word,
          'formalMeaning': word['formalMeaning'],
          'simpleMeaning': word['simpleMeaning'],
          'usageExample': word['usageExample'],
          'pronunciation': word['pronunciation'],
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) => WordDetailScreen(word: entry)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bookmark_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word['word'] ?? "", 
                    style: GoogleFonts.outfit(
                      color: Colors.white, 
                      fontSize: 17, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    word['formalMeaning'] ?? "No meaning available", 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white38, 
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => TTSService.speak(word['word'] ?? ""),
              icon: const Icon(Icons.volume_up_rounded, color: Colors.white24, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, Color accentColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.outfit(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
