import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'add_word_screen.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  XFile? _image;
  List<String> _detectedWords = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _image = picked;
          _isProcessing = true;
        });
        _processImage(picked);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _processImage(XFile picked) async {
    final inputImage = InputImage.fromFilePath(picked.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    // Split into individual words for easier selection
    // Cleaning: removing special characters and splitting by whitespace
    final words = recognizedText.text
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2) // Filter very short strings
        .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), '')) // Remove punctuation
        .toSet() // Remove duplicates
        .toList();

    setState(() {
      _detectedWords = words;
      _isProcessing = false;
    });
  }

  void _onWordTapped(String word) async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddWordScreen(prefilledWord: word),
      ),
    );
    
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Scan Word"),
        leading: const BackButton(color: Colors.white),
      ),
      body: PopScope(
        onPopInvoked: (didPop) => FocusScope.of(context).unfocus(),
        child: _image == null ? _buildPickUI() : _buildScanResults(),
      ),
    );
  }

  Widget _buildPickUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_rounded, size: 80, color: AppTheme.accentBlue.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            "Point at a word in a book or screen",
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_a_photo_rounded),
            label: Text("Open Camera", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    return Column(
      children: [
        // Image Preview
        Container(
          height: 250,
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(File(_image!.path)),
              fit: BoxFit.cover,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                "Detected text",
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : _detectedWords.isEmpty
                  ? const Center(child: Text("No text detected. Try again.", style: TextStyle(color: Colors.white54)))
                  : SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _detectedWords.map((word) {
                          return GestureDetector(
                            onTap: () => _onWordTapped(word),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                              ),
                              child: Text(
                                word,
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
        ),

        Container(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => setState(() => _image = null),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Scan Another", style: GoogleFonts.outfit(color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}