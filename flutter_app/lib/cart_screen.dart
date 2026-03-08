import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'api_service.dart';
import 'checkout_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _red     = Color(0xFFEF4444);
  static const Color _green   = Color(0xFF10B981);

  bool _placing = false;

  Future<void> _placeOrder(BuildContext context) async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;
    setState(() => _placing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('customer_id') ?? 1;
      final items = cart.items.map((i) => {
        'product_id': i['id'],
        'quantity': i['quantity'],
        'price': i['price'],
      }).toList();
      final res = await ApiService.placeOrder({
        'customer_id': customerId,
        'items': items,
        'total_amount': cart.totalPrice,
      });
      cart.clear();
      if (mounted) _showSuccess(context, res['order_id']?.toString() ?? res['id']?.toString() ?? '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
    setState(() => _placing = false);
  }

  void _showSuccess(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _border)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 72, height: 72,
              decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _yellow.withOpacity(0.4), blurRadius: 20)]),
              child: Icon(Icons.check_rounded, color: _navy, size: 38)),
            const SizedBox(height: 20),
            Text('Order Placed! 🎉', style: TextStyle(color: _navy, fontSize: 20,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Order #$orderId', style: TextStyle(color: _grey, fontSize: 14)),
            const SizedBox(height: 6),
            Text('We\'re preparing your order.\nExpect delivery in 10 minutes!',
                textAlign: TextAlign.center,
                style: TextStyle(color: _grey, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: _navy,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: const Text('Continue Shopping', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyLt,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Consumer<CartProvider>(
          builder: (_, cart, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1A1F36))),
            Text('${cart.totalItems} item${cart.totalItems != 1 ? 's' : ''}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.normal)),
          ]),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
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
                  child: Icon(Icons.shopping_cart_outlined, size: 48, color: const Color(0xFFD97706))),
              const SizedBox(height: 20),
              Text('Your cart is empty', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Add some products to get started', style: TextStyle(color: _grey, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: _navy,
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Browse Products', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]));
          }

          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...cart.items.map((item) => _cartItem(context, cart, item)),
                  const SizedBox(height: 16),
                  _billSummary(cart),
                ],
              ),
            ),

            // Place Order button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(color: _white,
                  border: Border(top: BorderSide(color: _border))),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _yellow, foregroundColor: _navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text('Checkout · ₹${cart.totalPrice.toStringAsFixed(0)}',
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
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          // Icon
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: _yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _yellow.withOpacity(0.3))),
              child: Icon(Icons.shopping_bag_outlined, color: const Color(0xFFD97706), size: 22)),
          const SizedBox(width: 12),

          // Name + unit
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'], style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('₹${item['price']} · ${item['unit']}',
                style: TextStyle(color: _grey, fontSize: 12)),
          ])),

          // Stepper
          Container(
            decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => cart.removeItem(item['id']),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.remove, color: _yellow, size: 14)),
              ),
              Text('${item['quantity']}', style: TextStyle(color: _yellow,
                  fontWeight: FontWeight.bold, fontSize: 14)),
              GestureDetector(
                onTap: () => cart.addItem(item),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.add, color: _yellow, size: 14)),
              ),
            ]),
          ),
          const SizedBox(width: 10),

          // Subtotal + delete
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => cart.deleteItem(item['id']),
              child: Container(padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.delete_outline_rounded, color: _red, size: 14)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _billSummary(CartProvider cart) {
    final subtotal = cart.totalPrice;
    return Container(
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(children: [
            Icon(Icons.receipt_outlined, color: _navy, size: 16),
            const SizedBox(width: 8),
            Text('Bill Summary', style: TextStyle(color: _navy,
                fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
        Divider(color: _border, height: 20),
        _billRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
        _billRow('Delivery', 'FREE', valueColor: _green),
        Divider(color: _border, height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
            Text('₹${subtotal.toStringAsFixed(2)}',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
        ),
      ]),
    );
  }

  Widget _billRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: _grey, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor ?? _navy,
            fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}