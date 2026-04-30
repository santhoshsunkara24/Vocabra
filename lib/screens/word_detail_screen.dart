import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'add_word_screen.dart';
import '../services/tts_service.dart';

class WordDetailScreen extends StatelessWidget {
  final WordEntry word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white54),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: word.word ?? ""));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${word.word}" copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF2563EB),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddWordScreen(wordEntry: word),
                ),
              );
              if (result == true) {
                if (context.mounted) Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
            onPressed: () => _showDeleteDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          word.word ?? "",
                          style: GoogleFonts.instrumentSerif(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => TTSService.speak(word.word ?? ""),
                        icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF2563EB), size: 32),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  if (word.pronunciation != null && word.pronunciation!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        word.pronunciation!,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF2563EB).withOpacity(0.8),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Vaulted on ${_formatDate(word.dateAdded ?? DateTime.now())}',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Formal definition'),
                  const SizedBox(height: 12),
                  Text(
                    word.dictionaryMeaning ?? "No meaning available",
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 17,
                      height: 1.6,
                    ),
                  ),

                  // Tier 2: Simple Meaning
                  if (word.simpleMeaning != null && word.simpleMeaning!.isNotEmpty && word.simpleMeaning != "Not available") ...[
                    const SizedBox(height: 36),
                    _buildSectionHeader('Simple meaning'),
                    const SizedBox(height: 12),
                    Text(
                      word.simpleMeaning!,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 17,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Tier 3: Usage Example
                  if (word.usageExample != null && word.usageExample!.isNotEmpty && word.usageExample != "Not available") ...[
                    const SizedBox(height: 36),
                    _buildSectionHeader('Usage example'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Text(
                        word.usageExample!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontSize: 17,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFF2563EB).withOpacity(0.9),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Delete Entry?', style: GoogleFonts.instrumentSerif(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('This word will be removed from your Vocabra forever.', style: GoogleFonts.outfit(color: Colors.white70)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.deleteWord(word.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Exit detail screen with refresh flag
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
