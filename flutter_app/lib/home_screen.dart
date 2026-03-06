import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'voice_order_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _customerName = '';
  String _customerEmail = '';
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    loadCustomer();
  }

  Future<void> loadCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customerName = prefs.getString('customer_name') ?? 'Customer';
      _customerEmail = prefs.getString('customer_email') ?? '';
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFF6B00),
              child: Text(
                _initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_customerName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  Text(_customerEmail,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        content: const Text('Do you want to logout from Annachi Kadai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String get _initials {
    if (_customerName.isEmpty) return 'U';
    final parts = _customerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _customerName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // ── SIDEBAR ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _sidebarExpanded ? 220 : 64,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              children: [
                // Brand header
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.store, color: Colors.white, size: 26),
                      if (_sidebarExpanded) ...[
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Annachi Kadai',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ] else
                        const Spacer(),
                      IconButton(
                        onPressed: () => setState(
                            () => _sidebarExpanded = !_sidebarExpanded),
                        icon: Icon(
                          _sidebarExpanded
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Nav: Shop
                _NavTile(
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store,
                  label: 'Shop',
                  isActive: _selectedIndex == 0,
                  expanded: _sidebarExpanded,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),

                // Nav: Voice Order
                _NavTile(
                  icon: Icons.mic_none,
                  activeIcon: Icons.mic,
                  label: 'Voice Order',
                  isActive: _selectedIndex == 1,
                  expanded: _sidebarExpanded,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),

                const Spacer(),

                // ── CUSTOMER PROFILE (tap to logout) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Material(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showLogoutDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFFFF6B00),
                              child: Text(
                                _initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                            if (_sidebarExpanded) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _customerName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _customerEmail,
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.logout,
                                  color: Colors.white38, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── MAIN CONTENT ──
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    ProductsScreen(),
                    VoiceOrderScreen(),
                  ],
                ),

                // Floating Cart Button
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B00).withOpacity(0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_rounded,
                              color: Colors.white, size: 22),
                          if (cart.totalItems > 0) ...[
                            const SizedBox(width: 10),
                            Text(
                                '${cart.totalItems} item${cart.totalItems > 1 ? 's' : ''}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                                width: 1,
                                height: 16,
                                color: Colors.white38),
                            const SizedBox(width: 8),
                            Text(
                                '₹${cart.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFF6B00).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(
                    color: const Color(0xFFFF6B00).withOpacity(0.3))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFFFF6B00) : Colors.white54,
                size: 22,
              ),
              if (expanded) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFFF6B00)
                          : Colors.white70,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}