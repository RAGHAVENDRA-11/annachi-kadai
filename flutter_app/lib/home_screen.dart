import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'login_screen.dart';
import 'api_service.dart';
import 'chat_screen.dart';
import 'membership_screen.dart';
import 'voice_screen.dart';
import 'prefs_helper.dart';
import 'membership_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _green   = Color(0xFF10B981);
  static const Color _red     = Color(0xFFEF4444);

  int _selectedIndex = 0;
  String _selectedCategory = 'All';

  // Profile fields
  String _customerName    = '';
  String _customerEmail   = '';
  String _customerId      = '';
  String _customerPhone   = '';
  String _customerAddress = '';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All',        'icon': Icons.grid_view_rounded},
    {'name': 'Grocery',    'icon': Icons.shopping_basket_outlined},
    {'name': 'Ice Cream',  'icon': Icons.icecream_outlined},
    {'name': 'Stationery', 'icon': Icons.edit_outlined},
  ];

  @override
  void initState() { super.initState(); _loadCustomer(); }

  Future<void> _loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    await PrefsHelper.init(); // ensure membership keys scoped to this customer
    setState(() {
      _customerName    = prefs.getString('customer_name')    ?? 'Customer';
      _customerEmail   = prefs.getString('customer_email')   ?? '';
      _customerId      = (prefs.get('customer_id') ?? '').toString();
      _customerPhone   = prefs.getString('customer_phone')   ?? '';
      _customerAddress = prefs.getString('customer_address') ?? '';
    });
  }

  String get _initials {
    if (_customerName.isEmpty) return 'U';
    final parts = _customerName.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : _customerName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final pages = [
      ProductsScreen(key: ValueKey(_selectedCategory), selectedCategory: _selectedCategory),
      const OrdersScreen(),
      const CartScreen(embedded: true),
      _ProfileScreen(
        customerId: _customerId,
        name: _customerName,
        email: _customerEmail,
        phone: _customerPhone,
        address: _customerAddress,
        initials: _initials,
        onUpdated: _loadCustomer,
      ),
    ];

    return Scaffold(
      backgroundColor: _greyLt,
      body: Column(children: [
        // ── TOP BAR ──
        Container(
          color: _navy,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16, right: 16, bottom: 10,
          ),
          child: Row(children: [
            // Logo
            Container(width: 32, height: 32,
                decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storefront_rounded, color: _navy, size: 20)),
            const SizedBox(width: 10),
            const Text('Annachi Kadai',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            // 10-min badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt, color: _green, size: 13),
                const SizedBox(width: 3),
                Text('10 min', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 10),
            // Cart icon
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: Stack(children: [
                Icon(Icons.shopping_cart_rounded, color: Colors.white70, size: 26),
                if (cart.totalItems > 0)
                  Positioned(top: 0, right: 0,
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle),
                      child: Center(child: Text('${cart.totalItems}',
                          style: TextStyle(color: _navy, fontSize: 9, fontWeight: FontWeight.bold))),
                    )),
              ]),
            ),
          ]),
        ),

        // ── CATEGORY BAR (only on Shop tab) ──
        if (_selectedIndex == 0)
          Container(
            color: _white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _categories.map((cat) {
                  final active = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? _navy : _greyLt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? _navy : _border),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(cat['icon'] as IconData, size: 14,
                            color: active ? _yellow : _grey),
                        const SizedBox(width: 5),
                        Text(cat['name'] as String,
                            style: TextStyle(
                              color: active ? _yellow : _grey,
                              fontWeight: active ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            )),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // ── CONTENT ──
        Expanded(child: pages[_selectedIndex]),
      ]),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChatScreen())),
        backgroundColor: _navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.smart_toy_rounded, color: _yellow, size: 26),
      ),
      // ── BOTTOM NAV ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: [
              _BottomNavItem(
                icon: Icons.store_outlined, activeIcon: Icons.store_rounded,
                label: 'Shop', isActive: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _BottomNavItem(
                icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,
                label: 'Orders', isActive: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              // ── VOICE CENTRE BUTTON (opens as modal) ──
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const VoiceScreen(),
                      )),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _navy,
                        border: Border.all(color: _yellow, width: 2.5),
                        boxShadow: [BoxShadow(
                            color: _yellow.withOpacity(0.35), blurRadius: 12)],
                      ),
                      child: const Icon(Icons.mic_rounded, color: _yellow, size: 26),
                    ),
                    const SizedBox(height: 2),
                    const Text('Voice',
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w600, color: _navy)),
                  ]),
                ),
              ),
              _BottomNavItem(
                icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded,
                label: 'Cart', isActive: _selectedIndex == 2,
                badge: cart.totalItems > 0 ? '${cart.totalItems}' : null,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _BottomNavItem(
                icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,
                label: 'Profile', isActive: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── BOTTOM NAV ITEM ──
class _BottomNavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String? badge;
  static const _yellow = Color(0xFFFFD60A);
  static const _navy   = Color(0xFF1A1F36);
  static const _grey   = Color(0xFF6B7280);

  const _BottomNavItem({required this.icon, required this.activeIcon,
      required this.label, required this.isActive, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? _navy : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isActive ? activeIcon : icon,
                  color: isActive ? _yellow : _grey, size: 22),
            ),
            if (badge != null)
              Positioned(top: -2, right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle),
                  child: Text(badge!,
                      style: TextStyle(color: _navy, fontSize: 8, fontWeight: FontWeight.bold)),
                )),
          ]),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
            color: isActive ? _navy : _grey,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )),
        ]),
      ),
    );
  }
}

// ── PROFILE SCREEN ──
class _ProfileScreen extends StatefulWidget {
  final String customerId, name, email, phone, address, initials;
  final VoidCallback onUpdated;

  const _ProfileScreen({required this.customerId, required this.name,
      required this.email, required this.phone, required this.address,
      required this.initials, required this.onUpdated});

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _green   = Color(0xFF10B981);
  static const Color _red     = Color(0xFFEF4444);

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _editing = false;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.name);
    _phoneCtrl   = TextEditingController(text: widget.phone);
    _addressCtrl = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.updateProfile(
        customerId: widget.customerId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customer_name',    _nameCtrl.text.trim());
        await prefs.setString('customer_phone',   _phoneCtrl.text.trim());
        await prefs.setString('customer_address', _addressCtrl.text.trim());
        widget.onUpdated();
        setState(() => _editing = false);
        if (mounted) _toast('Profile updated!', success: true);
      } else {
        if (mounted) _toast('Failed to update profile', success: false);
      }
    } catch (e) {
      if (mounted) _toast('Error: $e', success: false);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _toast(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(success ? Icons.check_circle : Icons.error, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: success ? _green : _red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: _white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 28, backgroundColor: _yellow,
            child: Text(widget.initials, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 14),
        Text(widget.name, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(widget.email, style: TextStyle(color: _grey, fontSize: 12)),
        const SizedBox(height: 16),
        Text('Sign out of Annachi Kadai?', style: TextStyle(color: _grey, fontSize: 14)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: _grey,
                side: BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: _white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () async {
              Navigator.pop(ctx);
              context.read<MembershipProvider>().clear();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ])),
    ));
  }

  Widget _field(String label, TextEditingController ctrl, {IconData? icon, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _grey, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        enabled: _editing,
        maxLines: maxLines,
        style: TextStyle(color: _navy, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, size: 18, color: _editing ? _navy : _grey) : null,
          filled: true,
          fillColor: _editing ? _white : _greyLt,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _editing ? _navy.withOpacity(0.3) : _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _yellow, width: 2)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border)),
        ),
      ),
      const SizedBox(height: 14),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── PROFILE CARD ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F36), Color(0xFF2A3150)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            CircleAvatar(
              radius: 36, backgroundColor: _yellow,
              child: Text(widget.initials,
                  style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 24)),
            ),
            const SizedBox(height: 12),
            Text(widget.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(widget.email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _green.withOpacity(0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_user_rounded, color: _green, size: 13),
                const SizedBox(width: 5),
                Text('Verified Customer', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── EDIT DETAILS ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: _white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Personal Details',
                  style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_editing) {
                    _saveProfile();
                  } else {
                    setState(() => _editing = true);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _editing ? _green : _navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _saving
                      ? SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_editing ? Icons.check_rounded : Icons.edit_rounded,
                              color: _editing ? _white : _yellow, size: 15),
                          const SizedBox(width: 5),
                          Text(_editing ? 'Save' : 'Edit',
                              style: TextStyle(color: _editing ? _white : _yellow,
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ]),
                ),
              ),
              if (_editing) ...[ 
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _editing = false;
                      _nameCtrl.text    = widget.name;
                      _phoneCtrl.text   = widget.phone;
                      _addressCtrl.text = widget.address;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: _greyLt, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border)),
                    child: Text('Cancel', style: TextStyle(color: _grey, fontSize: 13)),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 18),

            // Email (read only always)
            Text('Email', style: TextStyle(color: _grey, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border)),
              child: Row(children: [
                Icon(Icons.email_outlined, size: 18, color: _grey),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.email,
                    style: TextStyle(color: _grey, fontSize: 14))),
                Icon(Icons.lock_outline_rounded, size: 14, color: _grey),
              ]),
            ),
            const SizedBox(height: 14),

            _field('Full Name', _nameCtrl, icon: Icons.person_outline_rounded),
            _field('Phone Number', _phoneCtrl, icon: Icons.phone_outlined),
            _field('Delivery Address', _addressCtrl, icon: Icons.location_on_outlined, maxLines: 2),
          ]),
        ),

        const SizedBox(height: 16),

        // ── ORDER HISTORY SHORTCUT ──
        GestureDetector(
          onTap: () {
            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
            homeState?.setState(() => homeState._selectedIndex = 1);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border)),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_long_rounded, color: _yellow, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Order History', style: TextStyle(color: _navy,
                    fontWeight: FontWeight.bold, fontSize: 14)),
                Text('View all your past orders', style: TextStyle(color: _grey, fontSize: 12)),
              ])),
              Icon(Icons.chevron_right_rounded, color: _grey),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // ── MEMBERSHIP ──
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MembershipScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1F36), Color(0xFF2D3561)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD60A), size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Annachi Kadai Pass',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const Text('Diamond & Gold membership plans',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ]),
          ),
        ),

        const SizedBox(height: 12),
        // ── LOGOUT ──
        GestureDetector(
          onTap: _showLogoutDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _red.withOpacity(0.2))),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: _red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.logout_rounded, color: _red, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Logout', style: TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Sign out of your account', style: TextStyle(color: _red.withOpacity(0.6), fontSize: 12)),
              ])),
              Icon(Icons.chevron_right_rounded, color: _red.withOpacity(0.5)),
            ]),
          ),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }
}