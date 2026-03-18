import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF3F4F6);
  static const Color _green   = Color(0xFF10B981);
  static const Color _border  = Color(0xFFE5E7EB);

  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  String _customerId = '';

  final List<String> _suggestions = [
    '🛒 What products do you have?',
    '🥛 Do you have milk?',
    '⚡ How fast is delivery?',
    '🧾 Show me snacks',
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    _addBotMessage("Hi! 👋 I'm your Annachi Kadai assistant.\nAsk me anything — products, prices, or just say what you want to order!");
  }

  Future<void> _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _customerId = (prefs.get('customer_id') ?? '').toString());
  }

  void _addBotMessage(String text) {
    setState(() => _messages.add({'role': 'assistant', 'content': text, 'time': _now()}));
  }

  String _now() {
    final t = DateTime.now();
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  Future<void> _send([String? text]) async {
    final msg = (text ?? _ctrl.text).trim();
    if (msg.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': msg, 'time': _now()});
      _loading = true;
    });
    _scrollDown();

    try {
      // Build history (exclude greeting and cart messages)
      final history = _messages
          .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
          .map((m) => {'role': m['role'] as String, 'content': m['content'] as String})
          .toList();

      final res = await ApiService.chatWithBot(
        message: msg,
        history: history.length > 1 ? history.sublist(0, history.length - 1) : [],
        customerId: _customerId,
      );

      final reply = res['reply'] as String? ?? 'Sorry, something went wrong.';
      final cartAction = res['cart_action'] as Map?;

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply, 'time': _now()});
        _loading = false;
      });

      // Handle cart action
      if (cartAction != null && cartAction['items'] != null) {
        final items = cartAction['items'] as List;
        final cart = context.read<CartProvider>();
        for (final item in items) {
          final qty = (item['qty'] as int?) ?? 1;
          for (int i = 0; i < qty; i++) {
            cart.addItem({
              'id': item['id'],
              'name': item['name'],
              'price': double.parse(item['price'].toString()),
              'unit': item['unit'] ?? '',
            });
          }
        }
        // Show cart confirmation
        final names = items.map((i) => i['name']).join(', ');
        setState(() => _messages.add({
          'role': 'cart',
          'content': '🛒 Added to cart: $names',
          'time': _now(),
        }));
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Sorry, I couldn\'t connect. Please try again.', 'time': _now()});
        _loading = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose(); _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyLt,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded, color: _navy, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Annachi AI', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold, fontSize: 15)),
            Row(children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('Online', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ]),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () => setState(() {
              _messages.clear();
              _addBotMessage("Hi! 👋 I'm your Annachi Kadai assistant.\nAsk me anything — products, prices, or what you want to order!");
            }),
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length) return _typingIndicator();
              final m = _messages[i];
              if (m['role'] == 'cart') return _cartChip(m['content'] as String);
              return _bubble(m);
            },
          ),
        ),

        // Suggestions (show only at start)
        if (_messages.length <= 1)
          Container(
            color: _white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quick questions', style: TextStyle(color: _grey, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 6,
                children: _suggestions.map((s) => GestureDetector(
                  onTap: () => _send(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Text(s, style: TextStyle(color: _navy, fontSize: 12)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 4),
            ]),
          ),

        // Input
        Container(
          color: _white,
          padding: EdgeInsets.only(
            left: 12, right: 12, top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _greyLt,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: _navy, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    hintStyle: TextStyle(color: _grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _navy, shape: BoxShape.circle),
                child: Icon(Icons.send_rounded, color: _yellow, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final isUser = m['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.smart_toy_rounded, color: _navy, size: 16)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? _navy : _white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                        blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(m['content'] as String,
                      style: TextStyle(color: isUser ? _yellow : _navy,
                          fontSize: 14, height: 1.4)),
                ),
                const SizedBox(height: 3),
                Text(m['time'] as String,
                    style: TextStyle(color: _grey, fontSize: 10)),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 30, height: 30,
            decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.smart_toy_rounded, color: _navy, size: 16)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 3),
            _dot(1), const SizedBox(width: 3),
            _dot(2),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int i) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 600 + i * 200),
    builder: (_, v, __) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 7, height: 7,
      decoration: BoxDecoration(
        color: _loading ? _grey.withOpacity(0.4 + 0.6 * v) : _grey.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    ),
  );

  Widget _cartChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.3)),
        ),
        child: Text(text, style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
      )),
    );
  }
}