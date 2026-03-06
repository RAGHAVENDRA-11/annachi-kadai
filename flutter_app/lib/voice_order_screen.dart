import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class VoiceOrderScreen extends StatefulWidget {
  const VoiceOrderScreen({super.key});

  @override
  State<VoiceOrderScreen> createState() => _VoiceOrderScreenState();
}

class _VoiceOrderScreenState extends State<VoiceOrderScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _transcript = '';
  List<Map> _detected = [];

  final Map<String, String> productMap = {
    'paal': 'Milk', 'milk': 'Milk',
    'arisi': 'Rice', 'rice': 'Rice',
    'takkali': 'Tomato', 'tomato': 'Tomato',
    'vengayam': 'Onion', 'onion': 'Onion',
    'bread': 'Bread', 'egg': 'Eggs', 'eggs': 'Eggs',
    'sugar': 'Sugar', 'sarkarai': 'Sugar',
    'oil': 'Oil', 'ennai': 'Oil',
  };

  final Map<String, int> qtyMap = {
    'oru': 1, 'one': 1, 'a': 1,
    'rendu': 2, 'two': 2,
    'moonu': 3, 'three': 3,
    'naalu': 4, 'four': 4,
    'aindhu': 5, 'five': 5,
  };

  void _parseTranscript(String text) {
    final words = text.toLowerCase().split(' ');
    final List<Map> found = [];
    for (int i = 0; i < words.length; i++) {
      int qty = qtyMap[words[i]] ?? 1;
      String word = i + 1 < words.length ? words[i + 1] : words[i];
      if (productMap.containsKey(word)) {
        found.add({'name': productMap[word], 'qty': qty});
        i++;
      } else if (productMap.containsKey(words[i])) {
        found.add({'name': productMap[words[i]], 'qty': 1});
      }
    }
    setState(() => _detected = found);
  }

  Future<void> _startListening() async {
  // Check if speech is available
  bool available = await _speech.initialize(
    onError: (error) {
      setState(() {
        _isListening = false;
        _transcript = 'Voice not supported on this platform';
      });
    },
  );
  
  if (!available) {
    setState(() {
      _transcript = 'Voice ordering not supported on Windows.\nPlease use Android/iOS app.';
    });
    return;
  }

  setState(() {
    _isListening = true;
    _transcript = '';
    _detected = [];
  });
  _speech.listen(
    localeId: 'en_IN',
    onResult: (result) {
      setState(() => _transcript = result.recognizedWords);
      if (result.finalResult) {
        setState(() => _isListening = false);
        _parseTranscript(_transcript);
      }
    },
  );
}

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎙️ Voice Order',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('Tap the mic and say your order',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const Text('e.g. "Two milk one rice"',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isListening ? 120 : 100,
                height: _isListening ? 120 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? Colors.red
                      : const Color(0xFFFF6B00),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : const Color(0xFFFF6B00))
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isListening ? 'Listening...' : 'Tap to speak',
              style: TextStyle(
                  fontSize: 16,
                  color: _isListening ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
            if (_transcript.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('You said: "$_transcript"',
                    style: const TextStyle(fontSize: 15)),
              ),
            ],
            if (_detected.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Detected Items:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._detected.map((item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.check_circle,
                          color: Colors.green),
                      title: Text(item['name']),
                      trailing: Text('Qty: ${item['qty']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add All to Cart',
                      style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    for (var item in _detected) {
                      for (int i = 0; i < (item['qty'] as int); i++) {
                        cart.addItem({
                          'id': _detected.indexOf(item),
                          'name': item['name'],
                          'price': 50.0,
                          'unit': 'piece',
                        });
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Items added to cart!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {
                      _detected = [];
                      _transcript = '';
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}