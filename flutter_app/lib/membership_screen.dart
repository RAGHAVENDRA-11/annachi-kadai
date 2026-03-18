import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'api_service.dart';
import 'prefs_helper.dart';
import 'membership_provider.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});
  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  static const Color _yellow       = Color(0xFFFFD60A);
  static const Color _navy         = Color(0xFF1A1F36);
  static const Color _white        = Color(0xFFFFFFFF);
  static const Color _grey         = Color(0xFF6B7280);
  static const Color _greyLt       = Color(0xFFF9FAFB);
  static const Color _border       = Color(0xFFE5E7EB);
  static const Color _green        = Color(0xFF10B981);
  static const Color _red          = Color(0xFFEF4444);
  static const Color _diamond1     = Color(0xFF1A1F36);
  static const Color _diamond2     = Color(0xFF2D3561);
  static const Color _diamondAccent= Color(0xFF818CF8);
  static const Color _gold1        = Color(0xFFB45309);
  static const Color _gold2        = Color(0xFFD97706);
  static const Color _goldAccent   = Color(0xFFFFD60A);

  String _customerId   = '';
  String _membershipType = '';
  String _cardNumber   = '';
  String _memberName   = '';
  String _validUntil   = '';
  double _monthlySpent = 0.0;
  int    _monthlyLimit = 0;
  bool   _loading      = true;
  bool   _purchasing   = false;

  @override
  void initState() { super.initState(); _loadMembership(); }

  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMembership() async {
    final prefs = await SharedPreferences.getInstance();
    final cid   = (prefs.get('customer_id') ?? '').toString();
    _customerId = cid;

    if (cid.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Always fetch fresh from DB
      final res = await ApiService.getMembership(cid);
      print('[MembershipScreen] loaded: ' + res.toString());
      final type  = (res['membership_type'] ?? '').toString();
      final card  = (res['membership_card'] ?? '').toString();
      final valid = (res['membership_valid_until'] ?? '').toString();
      final limit = type == 'diamond' ? 1000 : (type == 'gold' ? 2500 : 0);

      // Monthly spend from prefs scoped to customer
      final spentKey = 'ms_spent_\$cid';
      final monthKey = 'ms_month_\$cid';
      final now = '\${DateTime.now().year}-\${DateTime.now().month}';
      double spent = 0.0;
      if ((prefs.getString(monthKey) ?? '') != now) {
        await prefs.setString(monthKey, now);
        await prefs.setDouble(spentKey, 0.0);
      } else {
        spent = prefs.getDouble(spentKey) ?? 0.0;
      }

      if (mounted) setState(() {
        _membershipType = type;
        _cardNumber     = card;
        _memberName     = prefs.getString('customer_name') ?? 'Member';
        _validUntil     = valid;
        _monthlyLimit   = limit;
        _monthlySpent   = spent;
        _loading        = false;
      });

      // Sync to provider
      if (mounted) context.read<MembershipProvider>().syncFromDB(type, card, valid, spent, limit);

    } catch (e) {
      print('[MembershipScreen] error: ' + e.toString());
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateCardNumber() {
    final r = Random();
    String num = '';
    for (int i = 0; i < 16; i++) {
      num += r.nextInt(10).toString();
      if (i == 3 || i == 7 || i == 11) num += ' ';
    }
    return num;
  }

  String _validUntilDate() {
    final d = DateTime.now().add(const Duration(days: 365));
    return '${d.month.toString().padLeft(2,'0')}/${d.year.toString().substring(2)}';
  }

  Future<void> _purchase(String type) async {
    final amount = type == 'diamond' ? 10000 : 26000;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Dialog(
      backgroundColor: _white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: type == 'diamond'
                ? [_diamond1, _diamond2] : [_gold1, _gold2]),
            shape: BoxShape.circle),
          child: Icon(type == 'diamond' ? Icons.diamond_rounded : Icons.star_rounded,
              color: type == 'diamond' ? _diamondAccent : _goldAccent, size: 28)),
        const SizedBox(height: 16),
        Text('Activate ${type == 'diamond' ? 'Diamond' : 'Gold'} Pass',
            style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Pay ₹$amount to activate your membership.\nFree delivery + monthly shopping limit for 12 months.',
            style: const TextStyle(color: _grey, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: _grey,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: _yellow,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Pay ₹$amount'),
          )),
        ]),
      ])),
    ));

    if (confirm != true) return;
    setState(() => _purchasing = true);
    try {
      final card  = _generateCardNumber();
      final valid = _validUntilDate();
      final res   = await ApiService.purchaseMembership(
        customerId: _customerId, type: type, cardNumber: card, validUntil: valid,
      );
      if (res['success'] == true) {
        // Reload directly from DB
        setState(() => _loading = true);
        await _loadMembership();
        if (mounted) _toast('${type == 'diamond' ? 'Diamond' : 'Gold'} Pass activated! 🎉', success: true);
      }
    } catch (e) {
      if (mounted) _toast('Purchase failed: $e', success: false);
    } finally {
      setState(() => _purchasing = false);
    }
  }

  void _toast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle : Icons.error, color: Colors.white, size: 18),
        const SizedBox(width: 8), Expanded(child: Text(msg)),
      ]),
      backgroundColor: success ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_monthlyLimit - _monthlySpent).clamp(0.0, _monthlyLimit.toDouble());
    final progress  = _monthlyLimit > 0 ? (_monthlySpent / _monthlyLimit).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: _greyLt,
      appBar: AppBar(
        backgroundColor: _navy, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Membership Plans',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                // ── ACTIVE CARD ──
                if (_membershipType.isNotEmpty) ...[
                  _ActiveCard(
                    type: _membershipType, cardNumber: _cardNumber,
                    memberName: _memberName, validUntil: _validUntil,
                  ),
                  const SizedBox(height: 16),

                  // ── MONTHLY LIMIT TRACKER ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('This Month\'s Usage',
                            style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: remaining < 200 ? _red.withOpacity(0.1) : _green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: remaining < 200 ? _red.withOpacity(0.3) : _green.withOpacity(0.3)),
                          ),
                          child: Text(
                            remaining <= 0 ? 'Limit Reached' : '₹${remaining.toStringAsFixed(0)} left',
                            style: TextStyle(
                                color: remaining < 200 ? _red : _green,
                                fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: _border,
                          color: progress > 0.85 ? _red : (progress > 0.6 ? _goldAccent : _green),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Spent', style: TextStyle(color: _grey, fontSize: 11)),
                          Text('₹${_monthlySpent.toStringAsFixed(0)}',
                              style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                        Column(children: [
                          const Text('Monthly Limit', style: TextStyle(color: _grey, fontSize: 11)),
                          Text('₹$_monthlyLimit',
                              style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Remaining', style: TextStyle(color: _grey, fontSize: 11)),
                          Text('₹${remaining.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: remaining < 200 ? _red : _green,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.refresh_rounded, color: _green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'Limit resets on 1st of every month. Valid for 12 months from activation.',
                            style: const TextStyle(color: _green, fontSize: 11),
                          )),
                        ]),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: _green, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(child: Text(
                        'Your card number is auto-applied at checkout. Free delivery on all orders!',
                        style: TextStyle(color: _green, fontSize: 12),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const Text('Your Plan',
                      style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                ],

                if (_membershipType.isEmpty) ...[
                  _headerBanner(),
                  const SizedBox(height: 16),
                ],

                // ── DIAMOND PLAN ──
                _PlanCard(
                  type: 'diamond', title: 'Diamond Pass',
                  subtitle: 'Premium membership for heavy shoppers',
                  totalAmount: 10000, monthlySaving: 1000, annualSaving: 2000,
                  features: [
                    'Shop up to ₹1,000/month using card',
                    'Annual savings of ₹2,000',
                    'Free delivery on ALL orders',
                    'Priority delivery',
                    'Exclusive diamond virtual card',
                    'Valid for 12 months',
                  ],
                  isActive: _membershipType == 'diamond',
                  isPurchasing: _purchasing,
                  onPurchase: () => _purchase('diamond'),
                ),

                const SizedBox(height: 16),

                // ── GOLD PLAN ──
                _PlanCard(
                  type: 'gold', title: 'Gold Pass',
                  subtitle: 'Best value for regular shoppers',
                  totalAmount: 26000, monthlySaving: 2500, annualSaving: 4000,
                  features: [
                    'Shop up to ₹2,500/month using card',
                    'Annual savings up to ₹3,000',
                    'Free delivery on ALL orders',
                    'Exclusive gold virtual card',
                    'Valid for 12 months',
                  ],
                  isActive: _membershipType == 'gold',
                  isPurchasing: _purchasing,
                  onPurchase: () => _purchase('gold'),
                ),

                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _headerBanner() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A1F36), Color(0xFF2D3561)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: _yellow, size: 28),
          const SizedBox(width: 10),
          const Text('Annachi Kadai Pass',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        const SizedBox(height: 8),
        const Text(
          'Get free delivery + monthly shopping limits.\nSave more every month for 12 months!',
          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}

// ── ACTIVE CARD WIDGET ──
class _ActiveCard extends StatelessWidget {
  final String type, cardNumber, memberName, validUntil;
  const _ActiveCard({required this.type, required this.cardNumber,
      required this.memberName, required this.validUntil});

  static const Color _diamond1      = Color(0xFF1A1F36);
  static const Color _diamond2      = Color(0xFF2D3561);
  static const Color _diamondAccent = Color(0xFF818CF8);
  static const Color _gold1         = Color(0xFFB45309);
  static const Color _gold2         = Color(0xFFD97706);
  static const Color _goldAccent    = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final isDiamond = type == 'diamond';
    final c1     = isDiamond ? _diamond1 : _gold1;
    final c2     = isDiamond ? _diamond2 : _gold2;
    final accent = isDiamond ? _diamondAccent : _goldAccent;

    return Container(
      width: double.infinity, height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c1.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(right: -30, top: -30,
          child: Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05)))),
        Positioned(right: 30, bottom: -40,
          child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05)))),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(isDiamond ? Icons.diamond_rounded : Icons.star_rounded, color: accent, size: 24),
                const SizedBox(width: 8),
                Text(isDiamond ? 'DIAMOND PASS' : 'GOLD PASS',
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold,
                        fontSize: 13, letterSpacing: 2)),
              ]),
              Container(width: 40, height: 30,
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: accent.withOpacity(0.5))),
                  child: Center(child: Icon(Icons.credit_card, color: accent, size: 16))),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: cardNumber.replaceAll(' ', '')));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Card number copied!'),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Row(children: [
                Text(cardNumber, style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w600, letterSpacing: 2)),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, color: Colors.white38, size: 16),
              ]),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CARD HOLDER', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                Text(memberName.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('VALID THRU', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                Text(validUntil,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── PLAN CARD WIDGET ──
class _PlanCard extends StatelessWidget {
  final String type, title, subtitle;
  final int totalAmount, monthlySaving, annualSaving;
  final List<String> features;
  final bool isActive, isPurchasing;
  final VoidCallback onPurchase;

  static const Color _navy         = Color(0xFF1A1F36);
  static const Color _white        = Color(0xFFFFFFFF);
  static const Color _grey         = Color(0xFF6B7280);
  static const Color _border       = Color(0xFFE5E7EB);
  static const Color _green        = Color(0xFF10B981);
  static const Color _diamond1     = Color(0xFF1A1F36);
  static const Color _diamond2     = Color(0xFF2D3561);
  static const Color _diamondAccent= Color(0xFF818CF8);
  static const Color _gold1        = Color(0xFFB45309);
  static const Color _gold2        = Color(0xFFD97706);
  static const Color _goldAccent   = Color(0xFFFFD60A);

  const _PlanCard({required this.type, required this.title, required this.subtitle,
      required this.totalAmount, required this.monthlySaving, required this.annualSaving,
      required this.features, required this.isActive, required this.isPurchasing,
      required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final isDiamond = type == 'diamond';
    final c1     = isDiamond ? _diamond1 : _gold1;
    final c2     = isDiamond ? _diamond2 : _gold2;
    final accent = isDiamond ? _diamondAccent : _goldAccent;

    return Container(
      decoration: BoxDecoration(
        color: _white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? c1 : _border, width: isActive ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c1, c2],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(isDiamond ? Icons.diamond_rounded : Icons.star_rounded,
                    color: accent, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(20)),
                child: const Text('Active', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
          ]),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _stat('₹$totalAmount', 'Total Cost', c1),
            _divider(),
            _stat('₹$monthlySaving', 'Monthly Limit', c1),
            _divider(),
            _stat('₹$annualSaving', 'Annual Saving', _green),
          ]),
        ),

        Container(height: 1, color: _border),

        // Features
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 20, height: 20,
                  decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: _green, size: 13)),
              const SizedBox(width: 10),
              Text(f, style: const TextStyle(color: _navy, fontSize: 13)),
            ]),
          )).toList()),
        ),

        // Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: isActive
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: _green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _green.withOpacity(0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded, color: _green, size: 18),
                    const SizedBox(width: 8),
                    Text('$title is Active',
                        style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                )
              : GestureDetector(
                  onTap: isPurchasing ? null : onPurchase,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c1, c2]),
                        borderRadius: BorderRadius.circular(12)),
                    child: isPurchasing
                        ? const Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(isDiamond ? Icons.diamond_rounded : Icons.star_rounded,
                                color: accent, size: 18),
                            const SizedBox(width: 8),
                            Text('Get $title for ₹$totalAmount',
                                style: TextStyle(color: accent,
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ]),
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _stat(String val, String label, Color color) => Expanded(child: Column(children: [
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: _grey, fontSize: 10), textAlign: TextAlign.center),
  ]));

  Widget _divider() => Container(width: 1, height: 36, color: _border);
}