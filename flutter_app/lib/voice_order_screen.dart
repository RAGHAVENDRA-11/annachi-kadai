import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'main.dart';
import 'api_service.dart';

class VoiceOrderScreen extends StatefulWidget {
  const VoiceOrderScreen({super.key});
  @override
  State<VoiceOrderScreen> createState() => _VoiceOrderScreenState();
}

class _VoiceOrderScreenState extends State<VoiceOrderScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _green   = Color(0xFF10B981);
  static const Color _red     = Color(0xFFEF4444);

  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textCtrl = TextEditingController();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _loading = false;
  String _spokenText = '';
  List<Map<String, dynamic>> _matchedItems = [];
  String _message = '';
  bool _isError = false;

  // Detect if voice is supported (Android/iOS only)
  bool get _isVoiceSupported => !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    if (_isVoiceSupported) _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    setState(() { _isListening = true; _spokenText = ''; _matchedItems = []; _message = ''; });
    await _speech.listen(
      onResult: (result) {
        setState(() => _spokenText = result.recognizedWords);
        if (result.finalResult && _spokenText.isNotEmpty) {
          _stopListening();
          _processOrder(_spokenText);
        }
      },
      listenFor: const Duration(seconds: 10),
      localeId: 'en_IN',
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processOrder(String text) async {
    if (text.trim().isEmpty) return;
    setState(() { _loading = true; _message = ''; _matchedItems = []; });
    try {
      final result = await ApiService.processVoiceOrder(text);
      setState(() {
        _matchedItems = List<Map<String, dynamic>>.from(result['matched_items'] ?? []);
        _message = result['message'] ?? '';
        _isError = false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Could not process order. Try again.';
        _isError = true;
        _loading = false;
      });
    }
  }

  void _addAllToCart() {
    final cart = context.read<CartProvider>();
    for (final item in _matchedItems) {
      cart.addItem({
        'id': item['id'],
        'name': item['name'],
        'price': double.parse(item['price'].toString()),
        'unit': item['unit'] ?? 'pcs',
      });
    }
    setState(() {
      _matchedItems = [];
      _spokenText = '';
      _textCtrl.clear();
      _message = '${_matchedItems.length} items added to cart!';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_rounded, color: _yellow),
        const SizedBox(width: 10),
        const Text('Items added to cart!', style: TextStyle(color: Colors.white)),
      ]),
      backgroundColor: _navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _speech.stop();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyLt,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.mic_rounded, color: _navy, size: 24),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Voice Order', style: TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: _navy)),
              Text(_isVoiceSupported ? 'Speak or type your order' : 'Type your order below',
                  style: TextStyle(color: _grey, fontSize: 13)),
            ]),
          ]),

          const SizedBox(height: 28),

          // Input Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              // Text input
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    onChanged: (v) => setState(() => _spokenText = v),
                    onSubmitted: (v) { if (v.isNotEmpty) _processOrder(v); },
                    decoration: InputDecoration(
                      hintText: 'e.g. "2 milk 1 rice 3 eggs"',
                      hintStyle: TextStyle(color: _grey, fontSize: 13),
                      prefixIcon: Icon(Icons.edit_rounded, color: _grey, size: 20),
                      filled: true,
                      fillColor: _greyLt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _yellow, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Search button
                GestureDetector(
                  onTap: () {
                    final text = _textCtrl.text.trim();
                    if (text.isNotEmpty) _processOrder(text);
                  },
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.search_rounded, color: _navy, size: 22),
                  ),
                ),
              ]),

              // Voice button (mobile only)
              if (_isVoiceSupported) ...[
                const SizedBox(height: 16),
                const Row(children: [
                  Expanded(child: Divider()), SizedBox(width: 10),
                  Text('or', style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 10), Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? _red : _yellow,
                      boxShadow: [BoxShadow(
                        color: (_isListening ? _red : _yellow).withOpacity(0.4),
                        blurRadius: _isListening ? 20 : 10,
                        spreadRadius: _isListening ? 4 : 0,
                      )],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? _white : _navy, size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(_isListening ? 'Listening...' : 'Tap to speak',
                    style: TextStyle(color: _isListening ? _red : _grey,
                        fontWeight: FontWeight.w600)),
              ],

              // Spoken text preview
              if (_spokenText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _yellow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _yellow.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.format_quote_rounded, color: _yellow, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('"$_spokenText"',
                        style: TextStyle(color: _navy, fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic))),
                  ]),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // Loading
          if (_loading)
            Center(child: Column(children: [
              CircularProgressIndicator(color: _yellow),
              const SizedBox(height: 12),
              Text('Finding products...', style: TextStyle(color: _grey)),
            ])),

          // Matched items
          if (_matchedItems.isNotEmpty) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${_matchedItems.length} items found',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _navy)),
              GestureDetector(
                onTap: _addAllToCart,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_shopping_cart_rounded, color: _navy, size: 18),
                    const SizedBox(width: 6),
                    Text('Add All to Cart', style: TextStyle(color: _navy,
                        fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ..._matchedItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: _green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: _navy)),
                  Text('₹${item['price']} · 1 ${item['unit'] ?? 'pcs'}',
                      style: TextStyle(color: _grey, fontSize: 12)),
                ])),
                GestureDetector(
                  onTap: () {
                    context.read<CartProvider>().addItem({
                      'id': item['id'],
                      'name': item['name'],
                      'price': double.parse(item['price'].toString()),
                      'unit': item['unit'] ?? 'pcs',
                    });
                    setState(() => _matchedItems.remove(item));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${item['name']} added!',
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: _navy,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(8)),
                    child: Text('ADD', style: TextStyle(color: _navy,
                        fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ]),
            )),
          ],

          // Error / empty message
          if (_message.isNotEmpty && _matchedItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isError ? _red.withOpacity(0.08) : _green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isError
                    ? _red.withOpacity(0.3) : _green.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(_isError ? Icons.error_outline : Icons.info_outline,
                    color: _isError ? _red : _green),
                const SizedBox(width: 10),
                Expanded(child: Text(_message,
                    style: TextStyle(color: _isError ? _red : _green,
                        fontWeight: FontWeight.w600))),
              ]),
            ),

          const SizedBox(height: 20),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.lightbulb_outline_rounded, color: _yellow, size: 18),
                const SizedBox(width: 8),
                Text('Tips', style: TextStyle(fontWeight: FontWeight.w700,
                    color: _navy, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              _tip('Say or type product names clearly'),
              _tip('Include quantity: "2 milk", "3 eggs"'),
              _tip('Multiple items: "1 bread 2 butter 1 sugar"'),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(width: 4, height: 4,
          decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: _grey, fontSize: 12)),
    ]),
  );
}