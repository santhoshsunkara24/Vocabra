import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<String>> processImage(InputImage inputImage) async {
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    if (recognizedText.text.isEmpty) return [];

    // Extract words, strip punctuation, and filter noise
    final words = recognizedText.text
        .split(RegExp(r'[\s\n\r\t]+')) // Split by whitespace/newlines
        .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), '').trim()) // Remove punctuation
        .where((w) => w.length > 2) // Filter very short tokens/noise
        .where((w) => !RegExp(r'^\d+$').hasMatch(w)) // Filter purely numeric strings
        .toSet() // Remove duplicates
        .toList();

    words.sort(); // Consistent ordering
    return words;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
