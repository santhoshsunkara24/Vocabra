import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import 'add_word_screen.dart';
import 'ocr_scan_screen.dart';
import 'word_detail_screen.dart';
import '../models/word_entry.dart';
import '../theme/app_theme.dart';
import 'search_screen.dart';
import '../services/tts_service.dart';
import '../services/daily_word_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> words = [];
  WordEntry? dailyWord;
  String _vaultSearchQuery = '';

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  Future<void> loadWords() async {
    final data = await StorageService.getWords();
    final daily = await DailyWordService().getDailyWord();
    setState(() {
      words = data.reversed.toList(); // latest first
      dailyWord = daily;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔹 HEADER
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Vocabra",
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 ACTION CARDS
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanScreen()),
                        );
                        if (result == true) loadWords();
                      },
                      child: _actionCard(
                        color: const Color(0xFF2563EB),
                        icon: Icons.camera_alt_rounded,
                        text: "Scan Word",
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddWordScreen()),
                        );
                        if (result == true) loadWords();
                      },
                      child: _actionCard(
                        color: const Color(0xFF22C55E),
                        icon: Icons.add_rounded,
                        text: "Add Word",
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 🔹 SEARCH BAR
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                  if (result == true) loadWords();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Universal search...",
                          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.mic_rounded, color: Color(0xFF2563EB), size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 🔹 WORD OF THE DAY LABEL
              Text(
                "Word of the day",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2563EB).withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // 🔥 DAILY WORD CARD
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F1C),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9F1C).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
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
                                dailyWord?.word ?? "Loading...",
                                style: GoogleFonts.instrumentSerif(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              if (dailyWord?.pronunciation != null && dailyWord!.pronunciation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    dailyWord!.pronunciation!,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (dailyWord != null) TTSService.speak(dailyWord!.word!);
                          },
                          icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      dailyWord?.dictionaryMeaning ?? "",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (dailyWord != null) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddWordScreen(prefilledWord: dailyWord!.word),
                              ),
                            );
                            if (result == true) loadWords();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Save to vault",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 🔹 VAULT
              Text(
                "Vault",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF2563EB).withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _vaultSearchQuery = val;
                          });
                        },
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search your vault...',
                          hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_vaultSearchQuery.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _vaultSearchQuery = '';
                          });
                          FocusScope.of(context).unfocus();
                        },
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (words.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "No words added yet.",
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final filteredWords = _vaultSearchQuery.isEmpty
                        ? words
                        : words.where((w) {
                            final word = (w['word'] as String? ?? '').toLowerCase();
                            return word.contains(_vaultSearchQuery.toLowerCase());
                          }).toList();
                          
                    if (filteredWords.isEmpty && _vaultSearchQuery.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "No matching words found.",
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    
                    return Column(
                      children: filteredWords.map((word) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WordDetailScreen(
                                word: WordEntry.fromMap(word),
                              ),
                            ),
                          );
                          if (result == true) loadWords();
                        },
                        child: Container(
                          width: double.infinity,
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
                              IconButton(
                                onPressed: () => TTSService.speak(word['word'] ?? ""),
                                icon: const Icon(Icons.volume_up_rounded, color: Colors.white24, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: word['word'] ?? ""));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${word['word']}" copied to clipboard'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF2563EB),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, color: Colors.white24, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}