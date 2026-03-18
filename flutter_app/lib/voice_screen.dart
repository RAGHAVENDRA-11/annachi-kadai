import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'api_service.dart';
import 'main.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with TickerProviderStateMixin {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _navy   = Color(0xFF1A1F36);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _grey   = Color(0xFF6B7280);
  static const Color _greyLt = Color(0xFFF9FAFB);
  static const Color _green  = Color(0xFF10B981);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _amber  = Color(0xFFD97706);

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening   = false;
  bool _isAvailable   = false;
  bool _isProcessing  = false;
  String _spokenText  = '';
  String _statusText  = 'Tap the mic and speak';
  List<Map> _matched  = [];
  List<Map> _allProducts = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initSpeech();
    _loadProducts();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) {
        if (mounted) setState(() {
          _statusText = 'Mic error — try again';
          _isListening = false;
        });
      },
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _isListening = false);
          if (_spokenText.isNotEmpty) _processVoice(_spokenText);
        }
      },
    );
    if (mounted) setState(() => _isAvailable = ok);
  }

  Future<void> _loadProducts() async {
    final data = await ApiService.getProducts();
    if (mounted) setState(() => _allProducts = List<Map>.from(data));
  }

  Future<void> _startListening() async {
    if (!_isAvailable) {
      setState(() => _statusText = 'Mic not available on this device');
      return;
    }
    setState(() {
      _spokenText = '';
      _matched    = [];
      _statusText = 'Listening... speak now';
      _isListening = true;
    });
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _spokenText = r.recognizedWords);
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 2),
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    if (_spokenText.isNotEmpty) _processVoice(_spokenText);
  }

  // ── Number word map (English + Tamil transliteration) ──
  static const Map<String, int> _numWords = {
    'one':1, 'two':2, 'three':3, 'four':4, 'five':5,
    'six':6, 'seven':7, 'eight':8, 'nine':9, 'ten':10,
    'oru':1, 'onnu':1, 'rendu':2, 'irandu':2, 'moonu':3,
    'naalu':4, 'anju':5, 'aaru':6, 'ezhu':7, 'ettu':8,
    'ombodhu':9, 'pathu':10, 'ek':1, 'do':2, 'teen':3,
    'char':4, 'paanch':5,
  };

  void _processVoice(String text) {
    if (!mounted) return;
    setState(() { _isProcessing = true; _statusText = 'Finding products...'; });

    final lower = text.toLowerCase().trim();
    final matched = <Map>[];

    // Extract leading number if any
    int globalQty = 1;
    for (final e in _numWords.entries) {
      if (lower.startsWith(e.key) || lower.contains(' ${e.key} ') || lower.contains(' ${e.key}')) {
        globalQty = e.value; break;
      }
    }
    final digitMatch = RegExp(r'^(\d+)').firstMatch(lower);
    if (digitMatch != null) globalQty = int.tryParse(digitMatch.group(1)!) ?? 1;

    for (final p in _allProducts) {
      final name  = (p['name'] as String).toLowerCase();
      final words = name.split(RegExp(r'\s+'));
      final stock = (p['stock_quantity'] ?? 0);
      final inStock = stock is int ? stock > 0 : (stock as num) > 0;

      bool found = false;
      // Match full name or any meaningful word (>2 chars)
      if (lower.contains(name)) {
        found = true;
      } else {
        for (final w in words) {
          if (w.length > 2 && lower.contains(w)) { found = true; break; }
        }
      }

      if (found) {
        // Per-product quantity detection
        int qty = globalQty;
        for (final e in _numWords.entries) {
          final pattern = RegExp(r'(\b' + e.key + r'\b).*' + words.first);
          final m = pattern.firstMatch(lower);
          if (m != null) { qty = e.value; break; }
        }
        final dMatch = RegExp(r'(\d+)\s*' + RegExp.escape(words.first)).firstMatch(lower);
        if (dMatch != null) qty = int.tryParse(dMatch.group(1)!) ?? qty;

        matched.add(Map.from(p)..['_qty'] = qty..['_inStock'] = inStock);
      }
    }

    if (mounted) setState(() {
      _matched     = matched;
      _isProcessing = false;
      _statusText  = matched.isEmpty
          ? 'Nothing found — try again'
          : '${matched.length} item${matched.length > 1 ? "s" : ""} found!';
    });
  }

  void _addToCart(Map product, {int? overrideQty}) {
    final qty  = overrideQty ?? (product['_qty'] as int? ?? 1);
    final cart = context.read<CartProvider>();
    final price = double.tryParse(product['price'].toString()) ?? 0.0;
    for (int i = 0; i < qty; i++) {
      cart.addItem({
        'id': product['id'], 'name': product['name'],
        'price': price, 'unit': product['unit'],
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text('${product['name']} ×$qty added to cart!'),
      ]),
      backgroundColor: _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    ));
    if (mounted) setState(() => _matched.removeWhere((p) => p['id'] == product['id']));
  }

  void _addAll() {
    for (final p in List.from(_matched)) _addToCart(p);
    if (mounted) setState(() {
      _matched = []; _spokenText = ''; _statusText = 'All added! 🎉 Say more or tap mic';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(child: Text('Voice Order',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 18))),
              if (_matched.isNotEmpty)
                GestureDetector(
                  onTap: _addAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: _yellow, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Add All',
                        style: TextStyle(color: _navy,
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
            ]),
          ),

          // ── MIC ZONE ──
          Expanded(
            flex: _matched.isEmpty ? 3 : 2,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Status
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(_statusText, key: ValueKey(_statusText),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _isListening ? _yellow : Colors.white60,
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 30),

              // Mic button
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => SizedBox(
                    width: 160, height: 160,
                    child: Stack(alignment: Alignment.center, children: [
                      if (_isListening) ...[
                        Container(
                          width: 160 * _pulseAnim.value,
                          height: 160 * _pulseAnim.value,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _yellow.withOpacity(0.07)),
                        ),
                        Container(
                          width: 130 * _pulseAnim.value,
                          height: 130 * _pulseAnim.value,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _yellow.withOpacity(0.12)),
                        ),
                      ],
                      Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening ? _yellow : Colors.white.withOpacity(0.12),
                          border: Border.all(
                              color: _isListening ? _yellow : Colors.white30, width: 2),
                          boxShadow: _isListening
                              ? [BoxShadow(color: _yellow.withOpacity(0.5), blurRadius: 28)]
                              : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: _isListening ? _navy : Colors.white,
                          size: 42,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Spoken text bubble
              if (_spokenText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12)),
                  child: Text('"$_spokenText"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontStyle: FontStyle.italic)),
                ),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(color: _yellow, strokeWidth: 2),
                ),

              // Hints when idle
              if (!_isListening && _spokenText.isEmpty && !_isProcessing) ...[
                const SizedBox(height: 20),
                Text('Try saying:', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 10),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
                  _hint('"2 Lays chips"'),
                  _hint('"Rendu Pepsi"'),
                  _hint('"Moonu bites"'),
                  _hint('"Oru Maggi"'),
                ]),
              ],
            ]),
          ),

          // ── RESULTS PANEL ──
          if (_matched.isNotEmpty || (_spokenText.isNotEmpty && !_isProcessing && !_isListening))
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: _greyLt,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: _matched.isEmpty
                    ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off_rounded, size: 44, color: _grey.withOpacity(0.5)),
                        const SizedBox(height: 10),
                        const Text('No products matched',
                            style: TextStyle(color: _navy,
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Try: "Lays", "Rendu Pepsi", "Moonu bites"',
                            style: TextStyle(color: _grey, fontSize: 12)),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _startListening,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                                color: _navy,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.mic_rounded, color: _yellow, size: 18),
                              SizedBox(width: 8),
                              Text('Try Again',
                                  style: TextStyle(color: _yellow,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                      ])
                    : Column(children: [
                        // Handle + header
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 36, height: 4,
                          decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${_matched.length} suggestion${_matched.length > 1 ? "s" : ""}',
                                  style: const TextStyle(color: _navy,
                                      fontWeight: FontWeight.bold, fontSize: 14)),
                              if (_matched.length > 1)
                                GestureDetector(
                                  onTap: _addAll,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: _navy,
                                        borderRadius: BorderRadius.circular(16)),
                                    child: const Text('Add All',
                                        style: TextStyle(color: _yellow,
                                            fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: _matched.length,
                            itemBuilder: (_, i) => _productCard(i),
                          ),
                        ),
                      ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _productCard(int i) {
    final p     = _matched[i];
    final qty   = p['_qty'] as int? ?? 1;
    final price = double.tryParse(p['price'].toString()) ?? 0.0;
    final inStock = p['_inStock'] as bool? ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
              color: _yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.shopping_bag_outlined, color: _amber, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['name'],
              style: const TextStyle(color: _navy,
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text('₹${price.toStringAsFixed(0)} · ${p['unit']}',
              style: const TextStyle(color: _grey, fontSize: 11)),
          if (!inStock)
            const Text('Out of stock',
                style: TextStyle(color: Colors.red, fontSize: 10)),
        ])),
        if (inStock) ...[
          // Qty stepper
          Row(children: [
            _stepBtn(Icons.remove, () {
              if (qty > 1) setState(() => _matched[i]['_qty'] = qty - 1);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('$qty',
                  style: const TextStyle(color: _navy,
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            _stepBtn(Icons.add, () {
              setState(() => _matched[i]['_qty'] = qty + 1);
            }, filled: true),
          ]),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _addToCart(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                  color: _navy, borderRadius: BorderRadius.circular(10)),
              child: const Text('ADD',
                  style: TextStyle(color: _yellow,
                      fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Out of\nStock',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, {bool filled = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: filled ? _navy : _greyLt,
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: _border),
          ),
          child: Icon(icon, size: 14, color: filled ? _yellow : _navy),
        ),
      );

  Widget _hint(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12)),
    child: Text(t,
        style: const TextStyle(color: Colors.white54, fontSize: 11)),
  );
}