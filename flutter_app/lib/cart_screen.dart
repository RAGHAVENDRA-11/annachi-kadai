import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'api_service.dart';
import 'checkout_screen.dart';
import 'membership_provider.dart';

class CartScreen extends StatefulWidget {
  final bool embedded;
  const CartScreen({super.key, this.embedded = false});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _navy   = Color(0xFF1A1F36);
  static const Color _grey   = Color(0xFF6B7280);
  static const Color _greyLt = Color(0xFFF9FAFB);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _red    = Color(0xFFEF4444);
  static const Color _green  = Color(0xFF10B981);
  static const Color _amber  = Color(0xFFD97706);

  String _membershipType = '';

  @override
  void initState() { super.initState(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyLt,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        backgroundColor: _white,
        foregroundColor: _navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Consumer<CartProvider>(
          builder: (_, cart, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Cart',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _navy)),
            Text('${cart.totalItems} item${cart.totalItems != 1 ? 's' : ''}',
                style: const TextStyle(color: _grey, fontSize: 12, fontWeight: FontWeight.normal)),
          ]),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border)),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 100, height: 100,
                  decoration: BoxDecoration(
                      color: _yellow.withOpacity(0.1), shape: BoxShape.circle,
                      border: Border.all(color: _yellow.withOpacity(0.3), width: 2)),
                  child: const Icon(Icons.shopping_cart_outlined, size: 48, color: _amber)),
              const SizedBox(height: 20),
              const Text('Your cart is empty',
                  style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Add some products to get started',
                  style: TextStyle(color: _grey, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow, foregroundColor: _navy, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                onPressed: () { if (Navigator.canPop(context)) Navigator.pop(context); },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Browse Products', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]));
          }

          final subtotal      = cart.totalPrice;
          final mem           = context.watch<MembershipProvider>();
          final hasMembership = mem.hasMembership;
          final _membershipType = mem.membershipType;
          // Cart shows estimated delivery — actual free delivery needs card applied at checkout
          final deliveryNote  = hasMembership
              ? 'FREE (Apply card at checkout)'
              : subtotal >= 299 ? 'FREE' : '₹40';
          final deliveryCharge = subtotal >= 299 ? 0.0 : 40.0;
          final estimatedTotal = hasMembership
              ? subtotal  // exact total depends on card being applied at checkout
              : subtotal + deliveryCharge;

          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...cart.items.map((item) => _cartItem(context, cart, item)),
                  const SizedBox(height: 16),

                  // ── BILL SUMMARY ──
                  Container(
                    decoration: BoxDecoration(
                        color: _white, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04), blurRadius: 8,
                            offset: const Offset(0, 2))]),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Row(children: [
                          const Icon(Icons.receipt_outlined, color: _navy, size: 16),
                          const SizedBox(width: 8),
                          const Text('Bill Summary',
                              style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
                        ]),
                      ),
                      Divider(color: _border, height: 20),
                      _billRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
                      // Delivery row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Delivery', style: TextStyle(color: _grey, fontSize: 14)),
                          Row(children: [
                            if (hasMembership) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _navy.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _membershipType == 'diamond' ? '💎 Pass' : '⭐ Pass',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              hasMembership ? 'FREE*' : (subtotal >= 299 ? 'FREE' : '₹40'),
                              style: TextStyle(
                                  color: (hasMembership || subtotal >= 299) ? _green : _navy,
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          ]),
                        ]),
                      ),
                      // Delivery hint
                      if (!hasMembership && subtotal < 299)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _yellow.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _yellow.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              Icon(Icons.info_outline_rounded, color: _amber, size: 14),
                              const SizedBox(width: 6),
                              Expanded(child: Text(
                                'Add ₹${(299 - subtotal).toStringAsFixed(0)} more for free delivery!',
                                style: TextStyle(color: _amber, fontSize: 11),
                              )),
                            ]),
                          ),
                        ),
                      if (hasMembership)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                          child: Text(
                            '* Apply your membership card at checkout for free delivery',
                            style: TextStyle(color: _grey, fontSize: 11),
                          ),
                        ),
                      Divider(color: _border, height: 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Estimated Total',
                              style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('₹${estimatedTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
                        ]),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 8),

                  // Membership upsell (if no membership)
                  if (_membershipType.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1A1F36), Color(0xFF2D3561)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFFFFD60A), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(child: Text(
                          'Get free delivery on every order with Diamond or Gold Pass!',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        )),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white38, size: 20),
                      ]),
                    ),
                ],
              ),
            ),

            // ── CHECKOUT BUTTON ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                  color: _white, border: Border(top: BorderSide(color: _border))),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _yellow, foregroundColor: _navy, elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text('Proceed to Checkout · ₹${estimatedTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _cartItem(BuildContext context, CartProvider cart, Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: _white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6,
              offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _yellow.withOpacity(0.3))),
              child: const Icon(Icons.shopping_bag_outlined, color: _amber, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'],
                style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('₹${item['price']} · ${item['unit']}',
                style: const TextStyle(color: _grey, fontSize: 12)),
          ])),
          Container(
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => cart.removeItem(item['id']),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.remove, color: _yellow, size: 14)),
              ),
              Text('${item['quantity']}',
                  style: const TextStyle(color: _yellow, fontWeight: FontWeight.bold, fontSize: 14)),
              GestureDetector(
                onTap: () => cart.addItem(item),
                child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.add, color: _yellow, size: 14)),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => cart.deleteItem(item['id']),
              child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.delete_outline_rounded, color: _red, size: 14)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: _grey, fontSize: 14)),
        Text(value, style: TextStyle(
            color: valueColor ?? _navy, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}