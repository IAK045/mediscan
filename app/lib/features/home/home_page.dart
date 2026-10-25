import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/mediscan_api.dart';

final apiProvider = Provider<MediScanApi>((ref) => MediScanApi());

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _nameController = TextEditingController();
  final _ocrController = TextEditingController();
  final _picker = ImagePicker();
  final _tts = FlutterTts();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _image;
  Map<String, dynamic>? _medicineData;
  Map<String, dynamic>? _aiData;
  String _language = 'en';
  String? _error;
  bool _scanning = false;
  bool _searching = false;
  bool _explaining = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ocrController.dispose();
    _recognizer.close();
    _tts.stop();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
  try {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _image = File(picked.path);
      _scanning = true;
      _error = null;
      _medicineData = null;
      _aiData = null;
      _ocrController.clear();
      _nameController.clear();
    });

    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(picked.path),
    );

    if (!mounted) return;

    _ocrController.text = recognized.text;
    final candidate = _guessMedicineName(recognized.text);

    setState(() {
      _scanning = false;
      if (candidate.isNotEmpty) {
        _nameController.text = candidate;
      }

      if (recognized.text.trim().isEmpty) {
        _error = 'No readable text found. Try a clearer, well-lit photo.';
      }
    });
  } catch (e, stackTrace) {
    debugPrint('OCR scan error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    setState(() {
      _scanning = false;
      _error =
          'Could not scan this image. Try another clear photo or enter the medicine name manually.';
    });
  }
}

  String _guessMedicineName(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.length >= 3 && line.length <= 45)
        .where((line) => !RegExp(
              r'^(batch|batch no|mfg|mfg date|expiry|exp|mrp|manufactured|marketed|composition|warning|dosage)\b',
              caseSensitive: false,
            ).hasMatch(line))
        .toList();
    return lines.isEmpty ? '' : lines.first;
  }

  Future<void> _search() async {
  final name = _nameController.text.trim();

  if (name.isEmpty) {
    setState(() {
      _error = 'Enter the medicine name or scan its packaging first.';
      _image = null;
      _medicineData = null;
      _aiData = null;
    });
    return;
  }

  FocusScope.of(context).unfocus();

  setState(() {
    _searching = true;
    _error = null;
    _image = null;
    _ocrController.clear();
    _medicineData = null;
    _aiData = null;
  });

  try {
    final result = await ref.read(apiProvider).searchMedicine(name);

    if (!mounted) return;

    setState(() {
      _medicineData = result;
      _searching = false;
    });
  } catch (e, stackTrace) {
    debugPrint('Medicine lookup error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!mounted) return;

    setState(() {
      _searching = false;
      _error =
          'Medicine lookup failed. Check your internet connection and try again.';
    });
  }
}

  Future<void> _explain() async {
    final name = _nameController.text.trim();
    final data = _medicineData;
    if (name.isEmpty || data == null) {
      setState(() => _error = 'Search for a medicine before requesting an AI explanation.');
      return;
    }
    setState(() {
      _explaining = true;
      _error = null;
    });
    try {
      final result = await ref.read(apiProvider).explainMedicine(
        medicineName: name,
        language: _language,
        sourceData: data,
        ocrText: _ocrController.text,
      );
      if (!mounted) return;
      setState(() {
        _aiData = result;
        _explaining = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _explaining = false;
        _error = 'AI explanation failed. Check the backend API key and connection. $e';
      });
    }
  }

  
Future<void> _speak(String text) async {
  try {
    if (text.trim().isEmpty) {
      debugPrint('TTS ERROR: No text to speak');
      return;
    }

    debugPrint('TTS: Starting playback');

    _tts.setStartHandler(() {
      debugPrint('TTS: Speech started');
    });

    _tts.setCompletionHandler(() {
      debugPrint('TTS: Speech completed');
    });

    _tts.setErrorHandler((message) {
      debugPrint('TTS ERROR: $message');
    });

    await _tts.stop();

    final language = _language == 'hi' ? 'hi-IN' : 'en-IN';
    final available = await _tts.isLanguageAvailable(language);
    debugPrint('TTS: Language available = $available');

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.46);

    final result = await _tts.speak(text);
    debugPrint('TTS: speak() result = $result');
  } catch (e, stackTrace) {
    debugPrint('TTS EXCEPTION: $e');
    debugPrint('$stackTrace');
  }
}


  String _value(Object? value) {
    if (value == null) return 'Not available in the retrieved source.';
    if (value is List) return value.where((e) => e != null).join('\n\n');
    final result = value.toString().trim();
    return result.isEmpty ? 'Not available in the retrieved source.' : result;
  }

  @override
  Widget build(BuildContext context) {
    final medicine = _medicineData;
    final ai = _aiData;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: Color(0xFF16845B), size: 30),
            SizedBox(width: 9),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Medi', style: TextStyle(color: Color(0xFF16845B), fontWeight: FontWeight.w800)),
              TextSpan(text: 'Scan', style: TextStyle(color: Color(0xFF2474D2), fontWeight: FontWeight.w800)),
              TextSpan(text: ' AI', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ])),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Stop voice',
            onPressed: () => _tts.stop(),
            icon: const Icon(Icons.volume_off_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5F7ED), Color(0xFFE9F2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Understand your medicine label', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF17231D))),
                  SizedBox(height: 8),
                  Text('Scan the pack, verify the extracted name, and review information from available sources.', style: TextStyle(height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1. Scan or enter medicine', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanning ? null : () => _scan(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _scanning ? null : () => _scan(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    if (_image != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_image!, height: 170, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    if (_scanning) const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        labelText: 'Medicine name',
                        hintText: 'e.g. paracetamol',
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _searching ? null : _search,
                        icon: _searching
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search),
                        label: Text(_searching ? 'Searching…' : 'Find medicine information'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_ocrController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2. Review OCR text', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('OCR can make mistakes. Correct the medicine name above before searching.'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ocrController,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(labelText: 'Text extracted from label'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1C3BF)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFF9D2D25))),
              ),
            ],
            if (medicine != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Retrieved medicine information', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _InfoRow('Matched name', _value(medicine['matched_name'])),
                      _InfoRow('Generic name', _value(medicine['generic_name'])),
                      _InfoRow('Brand name', _value(medicine['brand_name'])),
                      _InfoRow('Manufacturer', _value(medicine['manufacturer'])),
                      _InfoRow('Uses / indications', _value(medicine['uses'])),
                      _InfoRow('Warnings', _value(medicine['warnings'])),
                      _InfoRow('Side effects', _value(medicine['side_effects'])),
                      _InfoRow('Source status', _value(medicine['source_status'])),
                      if ((medicine['source_url'] ?? '').toString().isNotEmpty)
                        SelectableText('Source: ${medicine['source_url']}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                      const SizedBox(height: 8),
                      const Text('This source may not contain complete information for medicines marketed in India.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _language,
                        decoration: const InputDecoration(labelText: 'AI explanation language'),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                        ],
                        onChanged: (value) => setState(() => _language = value ?? 'en'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _explaining ? null : _explain,
                          icon: _explaining
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome),
                          label: Text(_explaining ? 'Preparing explanation…' : 'Explain with AI'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (ai != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF2474D2)),
                        SizedBox(width: 8),
                        Text('AI plain-language explanation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      _InfoRow('Summary', _value(ai['summary'])),
                      _InfoRow('What the source says it is used for', _value(ai['uses'])),
                      _InfoRow('Safety points', _value(ai['safety_points'])),
                      _InfoRow('Questions for a pharmacist', _value(ai['ask_a_pharmacist'])),
                      if ((ai['limitations'] ?? '').toString().isNotEmpty)
                        _InfoRow('Limitations', _value(ai['limitations'])),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _speak([
                            ai['summary'], ai['uses'], ai['safety_points'], ai['ask_a_pharmacist'], ai['limitations']
                          ].where((e) => e != null).join('. ')),
                          icon: const Icon(Icons.volume_up_outlined),
                          label: Text(_language == 'hi' ? 'Hindi mein sunen' : 'Listen'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('AI output may be inaccurate. Do not use it to determine dosage or replace professional advice.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0DEAD)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF8C6500)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Expiry dates and dosage are not verified by this app. Check the printed pack and official leaflet, and ask a pharmacist or doctor if anything is unclear.',
                      style: TextStyle(height: 1.4, color: Color(0xFF634B10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF33443A))),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}
