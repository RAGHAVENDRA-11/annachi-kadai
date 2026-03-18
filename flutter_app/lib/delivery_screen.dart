import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'api_service.dart';
import 'login_screen.dart';

// ══════════════════════════════════════════════════
//  COLORS
// ══════════════════════════════════════════════════
const _dYellow = Color(0xFFFFD60A);
const _dNavy   = Color(0xFF1A1F36);
const _dWhite  = Color(0xFFFFFFFF);
const _dGrey   = Color(0xFF6B7280);
const _dGreyLt = Color(0xFFF9FAFB);
const _dBorder = Color(0xFFE5E7EB);
const _dGreen  = Color(0xFF10B981);
const _dRed    = Color(0xFFEF4444);
const _dAmber  = Color(0xFFD97706);
const _dBlue   = Color(0xFF3B82F6);
const _dPurple = Color(0xFF8B5CF6);

// ══════════════════════════════════════════════════
//  DELIVERY LOGIN SCREEN
// ══════════════════════════════════════════════════
class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});
  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Enter phone and password');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await ApiService.deliveryPartnerLogin(phone, pass);
      final partner = res['partner'] as Map;
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => DeliveryMainScreen(partner: Map<String, dynamic>.from(partner)),
        ));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              // Logo
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(
                  color: _dYellow, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _dYellow.withOpacity(0.4), blurRadius: 24)],
                ),
                child: const Icon(Icons.delivery_dining_rounded, color: _dNavy, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Delivery Partner',
                  style: TextStyle(color: _dWhite,
                      fontWeight: FontWeight.bold, fontSize: 26)),
              const SizedBox(height: 4),
              const Text('Annachi Kadai · Delivery App',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 40),

              _field(_phoneCtrl, 'Phone Number', Icons.phone_rounded,
                  inputType: TextInputType.phone),
              const SizedBox(height: 14),
              _passField(),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _dRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _dRed.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: _dRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error,
                        style: const TextStyle(color: _dRed, fontSize: 12))),
                  ]),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _dYellow, foregroundColor: _dNavy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _dNavy))
                      : const Text('Login',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              // Register link
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("New partner? ",
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const DeliveryRegisterScreen())),
                  child: const Text('Register here',
                      style: TextStyle(color: _dYellow,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ]),

              const SizedBox(height: 28),

              // ── SWITCH TO CUSTOMER PORTAL ──
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.06),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_rounded,
                          color: Colors.white60, size: 18),
                      SizedBox(width: 8),
                      Text('Switch to Customer Portal',
                          style: TextStyle(color: Colors.white60,
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? inputType}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white12, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: TextField(
          controller: ctrl, keyboardType: inputType,
          style: const TextStyle(color: _dWhite),
          decoration: InputDecoration(
            labelText: label, labelStyle: const TextStyle(color: Colors.white54),
            prefixIcon: Icon(icon, color: Colors.white38, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      );

  Widget _passField() => Container(
    decoration: BoxDecoration(
      color: Colors.white12, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white24),
    ),
    child: TextField(
      controller: _passCtrl, obscureText: _obscure,
      style: const TextStyle(color: _dWhite),
      onSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: 'Password', labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white38, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white38, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════
//  DELIVERY REGISTER SCREEN
// ══════════════════════════════════════════════════
class DeliveryRegisterScreen extends StatefulWidget {
  const DeliveryRegisterScreen({super.key});
  @override
  State<DeliveryRegisterScreen> createState() => _DeliveryRegisterScreenState();
}

class _DeliveryRegisterScreenState extends State<DeliveryRegisterScreen> {
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _error = '';

  Future<void> _register() async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    final conf  = _confirmCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Name, phone and password are required');
      return;
    }
    if (pass != conf) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _loading = true; _error = ''; });
    try {
      await ApiService.deliveryPartnerRegister({
        'name': name, 'phone': phone,
        'email': _emailCtrl.text.trim(),
        'vehicle_no': _vehicleCtrl.text.trim(),
        'password': pass,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registered! Please login.'),
          backgroundColor: _dGreen,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dNavy,
      appBar: AppBar(
        backgroundColor: _dNavy, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _dWhite, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Partner Registration',
            style: TextStyle(color: _dWhite, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Join Annachi Kadai',
              style: TextStyle(color: _dWhite,
                  fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 4),
          const Text('Create your delivery partner account',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 28),

          _label('Full Name *'),
          _field(_nameCtrl, 'Your full name', Icons.person_rounded),
          const SizedBox(height: 14),

          _label('Phone Number *'),
          _field(_phoneCtrl, '10-digit mobile number', Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 14),

          _label('Email (optional)'),
          _field(_emailCtrl, 'your@email.com', Icons.email_rounded,
              type: TextInputType.emailAddress),
          const SizedBox(height: 14),

          _label('Vehicle Number (optional)'),
          _field(_vehicleCtrl, 'e.g. TN 37 AB 1234', Icons.two_wheeler_rounded),
          const SizedBox(height: 14),

          _label('Password *'),
          _passFieldR(_passCtrl, 'Min 6 characters'),
          const SizedBox(height: 14),

          _label('Confirm Password *'),
          _passFieldR(_confirmCtrl, 'Re-enter password'),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _dRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _dRed.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: _dRed, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error,
                    style: const TextStyle(color: _dRed, fontSize: 12))),
              ]),
            ),
          ],

          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _dYellow, foregroundColor: _dNavy,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _dNavy))
                  : const Text('Create Account',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(
        color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? type}) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white12, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: TextField(
          controller: ctrl, keyboardType: type,
          style: const TextStyle(color: _dWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.white38, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );

  Widget _passFieldR(TextEditingController ctrl, String hint) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white12, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: TextField(
          controller: ctrl, obscureText: _obscure,
          style: const TextStyle(color: _dWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white38, size: 18),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38, size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════
//  MAIN SCREEN WITH BOTTOM NAV
// ══════════════════════════════════════════════════
class DeliveryMainScreen extends StatefulWidget {
  final Map<String, dynamic> partner;
  const DeliveryMainScreen({super.key, required this.partner});
  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DeliveryHomeTab(partner: widget.partner),
      DeliveryOrdersTab(),
      DeliveryProfileTab(
        partner: widget.partner,
        onLogout: () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DeliveryLoginScreen())),
      ),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _dWhite,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: [
              _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
              _navItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders', 1),
              _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 2),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int idx) {
    final active = _tab == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? _dNavy.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(active ? activeIcon : icon,
              color: active ? _dNavy : _dGrey, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
              fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? _dNavy : _dGrey)),
        ]),
      ),
    ));
  }
}

// ══════════════════════════════════════════════════
//  HOME TAB — today's active orders only
// ══════════════════════════════════════════════════
class DeliveryHomeTab extends StatefulWidget {
  final Map<String, dynamic> partner;
  const DeliveryHomeTab({super.key, required this.partner});
  @override
  State<DeliveryHomeTab> createState() => _DeliveryHomeTabState();
}

class _DeliveryHomeTabState extends State<DeliveryHomeTab> {
  List _orders = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final data = await ApiService.getTodayOrders();
      if (mounted) setState(() { _orders = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    try {
      await ApiService.updateOrderStatus(orderId, status);
      _snack('Order #$orderId → ${_statusLabel(status)}', success: true);
      _load(silent: true);
    } catch (_) {
      _snack('Failed to update', success: false);
    }
  }

  void _snack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle : Icons.error, color: _dWhite, size: 16),
        const SizedBox(width: 8), Text(msg),
      ]),
      backgroundColor: success ? _dGreen : _dRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    // Try Google Maps first, fallback to geo: uri
    final gMaps  = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving');
    final fallback = Uri.parse('geo:0,0?q=$encoded');
    if (await canLaunchUrl(gMaps)) {
      await launchUrl(gMaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.day}/${today.month}/${today.year}';

    return Scaffold(
      backgroundColor: _dGreyLt,
      appBar: AppBar(
        backgroundColor: _dNavy, elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(width: 36, height: 36,
              decoration: const BoxDecoration(color: _dYellow, shape: BoxShape.circle),
              child: const Icon(Icons.delivery_dining_rounded, color: _dNavy, size: 20)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hi, ${widget.partner['name']?.split(' ').first ?? 'Partner'}!',
                style: const TextStyle(color: _dWhite,
                    fontWeight: FontWeight.bold, fontSize: 15)),
            Text("Today's Orders · $dateStr",
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _dWhite),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _dNavy))
          : _orders.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load, color: _dYellow,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) => _orderCard(_orders[i]),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_outline_rounded, size: 64,
          color: _dGreen.withOpacity(0.4)),
      const SizedBox(height: 14),
      const Text("No active orders today", style: TextStyle(
          color: _dNavy, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 6),
      Text("Pull to refresh", style: TextStyle(color: _dGrey, fontSize: 13)),
    ],
  ));

  Widget _orderCard(Map o) {
    final status   = (o['status'] ?? 'pending') as String;
    final orderId  = o['id'] as int;
    final address  = o['delivery_address'] ?? 'Address not provided';
    final custName = o['customer_name'] ?? 'Customer';
    final phone    = o['customer_phone'] ?? '';
    final items    = List.from(o['items'] ?? []);
    final total    = o['total_amount'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _dWhite, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor(status).withOpacity(0.35), width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(children: [
        // ── ORDER HEADER ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 11),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(_statusIcon(status),
                    color: _statusColor(status), size: 19)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$orderId · ₹$total',
                  style: const TextStyle(color: _dNavy,
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_formatTime(o['created_at'] ?? ''),
                  style: const TextStyle(color: _dGrey, fontSize: 11)),
            ])),
            Row(children: [
              _statusChip(status),
              const SizedBox(width: 6),
              _OrderTimer(createdAt: o['created_at'] ?? ''),
            ]),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Customer
            Row(children: [
              const Icon(Icons.person_rounded, size: 14, color: _dGrey),
              const SizedBox(width: 6),
              Text(custName, style: const TextStyle(
                  color: _dNavy, fontWeight: FontWeight.w600, fontSize: 13)),
              if (phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _dGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _dGreen.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.call_rounded, size: 12, color: _dGreen),
                      const SizedBox(width: 4),
                      Text(phone, style: const TextStyle(
                          color: _dGreen, fontWeight: FontWeight.w600, fontSize: 11)),
                    ]),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 10),

            // Address + Map button
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: _dBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _dBlue.withOpacity(0.2))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_rounded, color: _dBlue, size: 15),
                const SizedBox(width: 8),
                Expanded(child: Text(address,
                    style: const TextStyle(color: _dNavy, fontSize: 12, height: 1.4))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openMaps(address),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: _dBlue, borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.map_rounded, color: _dWhite, size: 13),
                      SizedBox(width: 4),
                      Text('Navigate', style: TextStyle(
                          color: _dWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),

            // Items
            ...items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(children: [
                Container(width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: _dAmber, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text('${item['name']} × ${item['quantity']}',
                    style: const TextStyle(color: _dNavy, fontSize: 12))),
                Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                    style: const TextStyle(color: _dAmber,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            )),
            if (items.length > 3)
              Text('+${items.length - 3} more',
                  style: const TextStyle(color: _dGrey, fontSize: 11)),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action buttons
            _actionButtons(orderId, status),
          ]),
        ),
      ]),
    );
  }

  Widget _actionButtons(int orderId, String status) {
    switch (status) {
      case 'pending':
        return _btnRow([
          _btn('Confirm', Icons.check_circle_rounded, _dGreen,
              () => _updateStatus(orderId, 'confirmed')),
          _btn('Cancel', Icons.cancel_rounded, _dRed,
              () => _updateStatus(orderId, 'cancelled'), outline: true),
        ]);
      case 'confirmed':
        return _btn('Start Processing', Icons.inventory_2_rounded, _dAmber,
            () => _updateStatus(orderId, 'processing'), full: true);
      case 'processing':
        return _btn('Out for Delivery 🛵', Icons.delivery_dining_rounded, _dBlue,
            () => _updateStatus(orderId, 'on_the_way'), full: true);
      case 'on_the_way':
        return _btn('Mark Delivered ✅', Icons.where_to_vote_rounded, _dGreen,
            () => _confirmDelivered(orderId), full: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmDelivered(int orderId) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Mark Order #$orderId as delivered?\nEnsure the customer received the items.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _dGreen, foregroundColor: _dWhite),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes, Delivered'),
        ),
      ],
    ));
    if (ok == true) _updateStatus(orderId, 'delivered');
  }

  Widget _btnRow(List<Widget> btns) => Row(
      children: btns.asMap().entries.map((e) => Expanded(
          child: Padding(padding: EdgeInsets.only(right: e.key < btns.length - 1 ? 8 : 0),
              child: e.value))).toList());

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap,
      {bool outline = false, bool full = false}) {
    Widget w = GestureDetector(
      onTap: onTap,
      child: Container(
        width: full ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10),
          border: outline ? Border.all(color: color) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: outline ? color : _dWhite),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: outline ? color : _dWhite,
              fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
      ),
    );
    return w;
  }
}

// ══════════════════════════════════════════════════
//  ORDERS TAB — all order history
// ══════════════════════════════════════════════════
class DeliveryOrdersTab extends StatefulWidget {
  const DeliveryOrdersTab({super.key});
  @override
  State<DeliveryOrdersTab> createState() => _DeliveryOrdersTabState();
}

class _DeliveryOrdersTabState extends State<DeliveryOrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _active = [], _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await ApiService.getActiveDeliveryOrders();
      final h = await ApiService.getDeliveryHistory();
      if (mounted) setState(() { _active = a; _history = h; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dGreyLt,
      appBar: AppBar(
        backgroundColor: _dNavy, elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Order History',
            style: TextStyle(color: _dWhite, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: _dWhite),
              onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _dYellow, labelColor: _dYellow,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Active (${_active.length})'),
            Tab(text: 'Delivered (${_history.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _dNavy))
          : TabBarView(controller: _tabs, children: [
              _list(_active, active: true),
              _list(_history, active: false),
            ]),
    );
  }

  Widget _list(List orders, {required bool active}) {
    if (orders.isEmpty) return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(active ? Icons.inbox_rounded : Icons.history_rounded,
              size: 56, color: _dGrey.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(active ? 'No active orders' : 'No deliveries yet',
              style: const TextStyle(color: _dNavy,
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ]));

    return RefreshIndicator(
      onRefresh: _load, color: _dYellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _historyTile(orders[i]),
      ),
    );
  }

  Widget _historyTile(Map o) {
    final status = (o['status'] ?? 'pending') as String;
    final items  = List.from(o['items'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _dWhite, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _dBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                shape: BoxShape.circle),
            child: Icon(_statusIcon(status),
                color: _statusColor(status), size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Order #${o['id']}',
                style: const TextStyle(color: _dNavy,
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 8),
            _statusChip(status),
          ]),
          const SizedBox(height: 3),
          Text('${items.length} items · ₹${o['total_amount']}',
              style: const TextStyle(color: _dGrey, fontSize: 12)),
          if ((o['delivery_address'] ?? '').isNotEmpty)
            Text(o['delivery_address'],
                style: const TextStyle(color: _dGrey, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Text(_formatTime(o['created_at'] ?? ''),
            style: const TextStyle(color: _dGrey, fontSize: 11)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
//  PROFILE TAB
// ══════════════════════════════════════════════════
class DeliveryProfileTab extends StatefulWidget {
  final Map<String, dynamic> partner;
  final VoidCallback onLogout;
  const DeliveryProfileTab({super.key, required this.partner, required this.onLogout});
  @override
  State<DeliveryProfileTab> createState() => _DeliveryProfileTabState();
}

class _DeliveryProfileTabState extends State<DeliveryProfileTab> {
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confPwCtrl = TextEditingController();
  bool _changingPw = false;
  bool _pwLoading = false;
  String _pwError = '';
  bool _obscure = true;

  Future<void> _changePassword() async {
    final old = _oldPwCtrl.text.trim();
    final nw  = _newPwCtrl.text.trim();
    final conf = _confPwCtrl.text.trim();
    if (old.isEmpty || nw.isEmpty) {
      setState(() => _pwError = 'Fill all fields'); return;
    }
    if (nw != conf) {
      setState(() => _pwError = 'Passwords do not match'); return;
    }
    if (nw.length < 6) {
      setState(() => _pwError = 'Min 6 characters'); return;
    }
    setState(() { _pwLoading = true; _pwError = ''; });
    try {
      await ApiService.deliveryPartnerChangePassword(
          widget.partner['id'], old, nw);
      _oldPwCtrl.clear(); _newPwCtrl.clear(); _confPwCtrl.clear();
      setState(() { _changingPw = false; _pwLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed successfully!'),
        backgroundColor: _dGreen,
      ));
    } catch (e) {
      setState(() {
        _pwError = e.toString().replaceAll('Exception: ', '');
        _pwLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partner;
    return Scaffold(
      backgroundColor: _dGreyLt,
      appBar: AppBar(
        backgroundColor: _dNavy, elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(color: _dWhite, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── AVATAR ──
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_dNavy, Color(0xFF2D3561)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _dNavy.withOpacity(0.3), blurRadius: 16)],
            ),
            child: Center(
              child: Text(
                (p['name'] ?? 'D').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: _dYellow,
                    fontWeight: FontWeight.bold, fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(p['name'] ?? '',
              style: const TextStyle(color: _dNavy,
                  fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: _dGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _dGreen.withOpacity(0.3))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: _dGreen, size: 8),
              SizedBox(width: 6),
              Text('Active Partner', style: TextStyle(
                  color: _dGreen, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ),

          const SizedBox(height: 24),

          // ── DETAILS CARD ──
          _card(children: [
            const _SectionTitle('Partner Details'),
            _infoRow(Icons.phone_rounded, 'Phone', p['phone'] ?? '-'),
            _infoRow(Icons.email_rounded, 'Email', p['email'] ?? '-'),
            _infoRow(Icons.two_wheeler_rounded, 'Vehicle', p['vehicle_no'] ?? '-'),
            _infoRow(Icons.badge_rounded, 'Partner ID', '#${p['id']}'),
          ]),

          const SizedBox(height: 14),

          // ── CHANGE PASSWORD ──
          _card(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const _SectionTitle('Change Password'),
              GestureDetector(
                onTap: () => setState(() {
                  _changingPw = !_changingPw;
                  _pwError = '';
                }),
                child: Text(_changingPw ? 'Cancel' : 'Change',
                    style: const TextStyle(color: _dBlue,
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ]),
            if (_changingPw) ...[
              const SizedBox(height: 14),
              _pwField(_oldPwCtrl, 'Current Password'),
              const SizedBox(height: 10),
              _pwField(_newPwCtrl, 'New Password'),
              const SizedBox(height: 10),
              _pwField(_confPwCtrl, 'Confirm New Password'),
              if (_pwError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_pwError, style: const TextStyle(color: _dRed, fontSize: 12)),
              ],
              const SizedBox(height: 14),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _dNavy, foregroundColor: _dYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _pwLoading ? null : _changePassword,
                  child: _pwLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _dYellow))
                      : const Text('Update Password',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ]),

          const SizedBox(height: 14),

          // ── LOGOUT ──
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _dRed, foregroundColor: _dWhite),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onLogout();
                  },
                  child: const Text('Logout'),
                ),
              ],
            )),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _dRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _dRed.withOpacity(0.25)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout_rounded, color: _dRed, size: 20),
                SizedBox(width: 10),
                Text('Logout', style: TextStyle(
                    color: _dRed, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: _dWhite, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _dBorder),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _pwField(TextEditingController ctrl, String label) =>
      Container(
        decoration: BoxDecoration(
            color: _dGreyLt, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _dBorder)),
        child: TextField(
          controller: ctrl, obscureText: _obscure,
          style: const TextStyle(fontSize: 13, color: _dNavy),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _dGrey, fontSize: 12),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: _dGrey),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: _dGrey),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════
//  SHARED HELPERS
// ══════════════════════════════════════════════════
Widget _infoRow(IconData icon, String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(children: [
    Container(width: 32, height: 32,
        decoration: BoxDecoration(
            color: _dNavy.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _dNavy, size: 16)),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _dGrey, fontSize: 11)),
      Text(value, style: const TextStyle(
          color: _dNavy, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  ]),
);

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(
        color: _dNavy, fontWeight: FontWeight.bold, fontSize: 14)),
  );
}

Widget _statusChip(String status) {
  final label = status == 'on_the_way' ? 'On the Way'
      : status[0].toUpperCase() + status.substring(1);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status).withOpacity(0.3))),
    child: Text(label, style: TextStyle(
        color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

Color _statusColor(String s) {
  switch (s) {
    case 'pending':    return _dAmber;
    case 'confirmed':  return _dBlue;
    case 'processing': return _dPurple;
    case 'on_the_way': return const Color(0xFF0EA5E9);
    case 'delivered':  return _dGreen;
    case 'cancelled':  return _dRed;
    default:           return _dGrey;
  }
}

IconData _statusIcon(String s) {
  switch (s) {
    case 'pending':    return Icons.access_time_rounded;
    case 'confirmed':  return Icons.check_circle_rounded;
    case 'processing': return Icons.inventory_2_rounded;
    case 'on_the_way': return Icons.delivery_dining_rounded;
    case 'delivered':  return Icons.where_to_vote_rounded;
    case 'cancelled':  return Icons.cancel_rounded;
    default:           return Icons.help_outline_rounded;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'on_the_way': return 'On the Way 🛵';
    case 'processing': return 'Processing 📦';
    case 'confirmed':  return 'Confirmed ✓';
    case 'pending':    return 'Pending';
    case 'delivered':  return 'Delivered ✅';
    case 'cancelled':  return 'Cancelled';
    default:           return s;
  }
}

String _formatTime(String raw) {
  try {
    final dt = DateTime.parse(raw);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}';
  } catch (_) { return raw; }
}

// ── ORDER TIMER WIDGET ──
class _OrderTimer extends StatefulWidget {
  final String createdAt;
  const _OrderTimer({required this.createdAt});
  @override
  State<_OrderTimer> createState() => _OrderTimerState();
}

class _OrderTimerState extends State<_OrderTimer> {
  late Timer _t;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    try {
      final dt = DateTime.parse(widget.createdAt);
      if (mounted) setState(() => _elapsed = DateTime.now().difference(dt));
    } catch (_) {}
  }

  @override
  void dispose() { _t.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final m = _elapsed.inMinutes;
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final c = m >= 15 ? _dRed : (m >= 8 ? _dAmber : _dGreen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.timer_rounded, size: 11, color: c),
        const SizedBox(width: 3),
        Text('$m:$s', style: TextStyle(
            color: c, fontWeight: FontWeight.bold, fontSize: 11)),
      ]),
    );
  }
}