import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'voice_order_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _yellow   = Color(0xFFFFD60A);
  static const Color _navy     = Color(0xFF1A1F36);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _grey     = Color(0xFF6B7280);
  static const Color _greyLt   = Color(0xFFF9FAFB);
  static const Color _border   = Color(0xFFE5E7EB);
  static const Color _sidebar  = Color(0xFF1A1F36);

  int _selectedIndex = 0;
  String _customerName = '';
  String _customerEmail = '';
  bool _sidebarExpanded = true;
  String _selectedCategory = 'All';

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
    setState(() {
      _customerName  = prefs.getString('customer_name') ?? 'Customer';
      _customerEmail = prefs.getString('customer_email') ?? '';
    });
  }

  String get _initials {
    if (_customerName.isEmpty) return 'U';
    final parts = _customerName.trim().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : _customerName[0].toUpperCase();
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: _white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border)),
      child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 28, backgroundColor: _yellow,
            child: Text(_initials, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 14),
        Text(_customerName, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(_customerEmail, style: TextStyle(color: _grey, fontSize: 12)),
        const SizedBox(height: 20),
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
            style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: _navy,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () async {
              Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: _greyLt,
      body: Row(children: [
        // ── SIDEBAR ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _sidebarExpanded ? 220 : 64,
          decoration: BoxDecoration(
            color: _sidebar,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
          ),
          child: Column(children: [
            // Brand
            Container(
              height: 64,
              color: _yellow,
              child: Row(children: [
                const SizedBox(width: 14),
                const Icon(Icons.storefront_rounded, color: _navy, size: 26),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Annachi Kadai',
                      style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis)),
                ],
                const Spacer(),
                SizedBox(width: 32, height: 32,
                    child: IconButton(padding: EdgeInsets.zero,
                        onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                        icon: Icon(_sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                            color: _navy, size: 20))),
                const SizedBox(width: 4),
              ]),
            ),

            const SizedBox(height: 12),

            _NavTile(icon: Icons.store_outlined, activeIcon: Icons.store_rounded,
                label: 'Shop', isActive: _selectedIndex == 0, expanded: _sidebarExpanded,
                onTap: () => setState(() => _selectedIndex = 0)),
            _NavTile(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded,
                label: 'My Orders', isActive: _selectedIndex == 1, expanded: _sidebarExpanded,
                onTap: () => setState(() => _selectedIndex = 1)),
            _NavTile(icon: Icons.mic_none_rounded, activeIcon: Icons.mic_rounded,
                label: 'Voice Order', isActive: _selectedIndex == 2, expanded: _sidebarExpanded,
                onTap: () => setState(() => _selectedIndex = 2)),

            // Categories
            if (_selectedIndex == 0) ...[
              const SizedBox(height: 16),
              if (_sidebarExpanded)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(children: [
                    Container(width: 3, height: 12,
                        decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text('CATEGORIES', style: TextStyle(color: Colors.white38, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                  ]),
                ),
              const SizedBox(height: 4),
              ..._categories.map((cat) => _CategoryTile(
                    icon: cat['icon'] as IconData,
                    label: cat['name'] as String,
                    isActive: _selectedCategory == cat['name'],
                    expanded: _sidebarExpanded,
                    onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  )),
            ],

            const Spacer(),

            // Profile
            Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                child: InkWell(borderRadius: BorderRadius.circular(12), onTap: _showLogoutDialog,
                  child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: _yellow,
                        child: Text(_initials, style: TextStyle(color: _navy,
                            fontWeight: FontWeight.bold, fontSize: 12))),
                    if (_sidebarExpanded) ...[
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, children: [
                        Text(_customerName, style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text(_customerEmail, style: const TextStyle(color: Colors.white38, fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      ])),
                      const Icon(Icons.logout_rounded, color: Colors.white38, size: 16),
                    ],
                  ])),
                ),
              ),
            ),
          ]),
        ),

        // ── MAIN CONTENT ──
        Expanded(
          child: Stack(children: [
            if (_selectedIndex == 0)
              ProductsScreen(key: ValueKey(_selectedCategory), selectedCategory: _selectedCategory)
            else if (_selectedIndex == 1)
              const OrdersScreen()
            else
              const VoiceOrderScreen(),

            // Cart FAB
            if (_selectedIndex == 0)
              Positioned(bottom: 24, right: 24,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: _yellow,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: _yellow.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.shopping_cart_rounded, color: _navy, size: 22),
                      if (cart.totalItems > 0) ...[
                        const SizedBox(width: 10),
                        Text('${cart.totalItems} item${cart.totalItems > 1 ? 's' : ''}',
                            style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 16, color: _navy.withOpacity(0.3)),
                        const SizedBox(width: 8),
                        Text('₹${cart.totalPrice.toStringAsFixed(0)}',
                            style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive, expanded;
  final VoidCallback onTap;
  static const _yellow = Color(0xFFFFD60A);

  const _NavTile({required this.icon, required this.activeIcon, required this.label,
      required this.isActive, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? _yellow.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? _yellow.withOpacity(0.4) : Colors.transparent),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? _yellow : Colors.white54, size: 22),
            if (expanded) ...[
              const SizedBox(width: 12),
              Flexible(child: Text(label, style: TextStyle(
                color: isActive ? _yellow : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14), overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive, expanded;
  final VoidCallback onTap;
  static const _yellow    = Color(0xFFFFD60A);
  static const _navyLight = Color(0xFF2A3150);

  const _CategoryTile({required this.icon, required this.label,
      required this.isActive, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? _yellow.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(
                    color: isActive ? _yellow : _navyLight,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 15,
                    color: isActive ? const Color(0xFF1A1F36) : Colors.white54)),
            if (expanded) ...[
              const SizedBox(width: 10),
              Flexible(child: Text(label, style: TextStyle(
                color: isActive ? _yellow : Colors.white60,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13), overflow: TextOverflow.ellipsis)),
              if (isActive) Container(width: 5, height: 5, margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(color: _yellow, shape: BoxShape.circle)),
            ],
          ]),
        ),
      ),
    );
  }
}