import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'main.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _navy   = Color(0xFF1A1F36);
  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _grey   = Color(0xFF6B7280);
  static const Color _greyLt = Color(0xFFF9FAFB);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _green  = Color(0xFF10B981);
  static const Color _red    = Color(0xFFEF4444);

  Widget _buildImage(dynamic image, double size) {
    if (image != null && image.toString().isNotEmpty) {
      try {
        final src = image.toString();
        final bytes = base64Decode(src.contains(',') ? src.split(',').last : src);
        return Image.memory(bytes, width: size, height: size, fit: BoxFit.contain);
      } catch (_) {}
    }
    return Icon(Icons.shopping_bag_outlined, size: size * 0.5, color: _grey);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final p = product;
    final stockRaw = p['stock_quantity'];
    final stockQty = stockRaw == null ? 0 : (stockRaw is int ? stockRaw : (stockRaw as num).toInt());
    final isOutOfStock = stockQty == 0;
    final isLow = stockQty > 0 && stockQty < 10;
    final qty = cart.getQuantity(p['id']);
    final price = double.tryParse(p['price'].toString()) ?? 0.0;
    final categoryNames = {1: 'Grocery', 2: 'Ice Cream', 3: 'Stationery'};
    final categoryName = categoryNames[p['category_id']] ?? 'General';

    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBE6),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: _navy, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(alignment: Alignment.topRight, children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: _navy),
              onPressed: () => Navigator.pop(context),
            ),
            if (cart.totalItems > 0)
              Positioned(top: 8, right: 8,
                child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: _yellow, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(children: [
        // ── IMAGE AREA ──
        Container(
          width: double.infinity, height: 240,
          color: const Color(0xFFFFFBE6),
          child: Stack(children: [
            Center(child: _buildImage(p['image'], 190)),
            Positioned(bottom: 12, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _navy.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(categoryName, style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
            if (isLow)
              Positioned(bottom: 12, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(20)),
                  child: Text('Only $stockQty left!', style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            if (isOutOfStock)
              Positioned.fill(child: Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(child: Text('OUT OF STOCK',
                    style: TextStyle(color: _red, fontWeight: FontWeight.bold,
                        fontSize: 18, letterSpacing: 2))),
              )),
          ]),
        ),

        // ── DETAILS ──
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(p['name'] ?? '',
                  style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 22))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOutOfStock ? _red.withOpacity(0.1) : _green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isOutOfStock ? _red.withOpacity(0.3) : _green.withOpacity(0.3)),
                ),
                child: Text(isOutOfStock ? 'Out of Stock' : 'In Stock',
                    style: TextStyle(color: isOutOfStock ? _red : _green,
                        fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ]),

            const SizedBox(height: 6),
            Text('1 ${p['unit'] ?? ''}', style: const TextStyle(color: _grey, fontSize: 14)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            Row(children: [
              Text('₹${p['price']}', style: const TextStyle(
                  color: _navy, fontWeight: FontWeight.w800, fontSize: 30)),
              const SizedBox(width: 8),
              Text('per ${p['unit'] ?? 'unit'}', style: const TextStyle(color: _grey, fontSize: 13)),
            ]),

            const SizedBox(height: 20),

            Row(children: [
              _infoCard(Icons.bolt_rounded, '10 min', 'Delivery', _green),
              const SizedBox(width: 10),
              _infoCard(Icons.inventory_2_outlined, '$stockQty', 'In Stock', _navy),
              const SizedBox(width: 10),
              _infoCard(Icons.verified_outlined, 'Fresh', 'Quality', _yellow),
            ]),

            const SizedBox(height: 20),
            const Text('About this product',
                style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _greyLt,
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: Text(
                'Fresh ${p['name']} available at Annachi Kadai. '
                'Sold per ${p['unit']} at ₹${p['price']}. '
                'Get it delivered in 10 minutes!',
                style: const TextStyle(color: _grey, fontSize: 13, height: 1.6),
              ),
            ),

            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.delivery_dining_rounded, color: _green, size: 26),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Free Delivery', style: TextStyle(
                      color: _navy, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Text('Delivered in 10 minutes',
                      style: TextStyle(color: _grey, fontSize: 12)),
                ]),
              ]),
            ),
          ]),
        )),
      ]),

      // ── BOTTOM BAR ──
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: _white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, -3))]),
        child: isOutOfStock
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: _greyLt,
                    borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                child: const Center(child: Text('Out of Stock',
                    style: TextStyle(color: _grey, fontWeight: FontWeight.bold, fontSize: 16))),
              )
            : qty == 0
                ? GestureDetector(
                    onTap: () {
                      context.read<CartProvider>().addItem({
                        'id': p['id'], 'name': p['name'], 'price': price, 'unit': p['unit'],
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('${p['name']} added to cart!'),
                        ]),
                        backgroundColor: _green, behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                        duration: const Duration(seconds: 2),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(14)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.shopping_cart_rounded, color: _yellow, size: 20),
                        SizedBox(width: 10),
                        Text('Add to Cart', style: TextStyle(
                            color: _yellow, fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                    ),
                  )
                : Row(children: [
                    Container(
                      decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(14)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        GestureDetector(
                          onTap: () => context.read<CartProvider>().removeItem(p['id']),
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Icon(Icons.remove, color: _yellow, size: 20)),
                        ),
                        Text('$qty', style: const TextStyle(
                            color: _yellow, fontWeight: FontWeight.bold, fontSize: 18)),
                        GestureDetector(
                          onTap: () => context.read<CartProvider>().addItem({
                            'id': p['id'], 'name': p['name'], 'price': price, 'unit': p['unit'],
                          }),
                          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Icon(Icons.add, color: _yellow, size: 20)),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: _greyLt,
                          borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                      child: Column(children: [
                        Text('₹${(price * qty).toStringAsFixed(0)}',
                            style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 20)),
                        const Text('Total', style: TextStyle(color: _grey, fontSize: 11)),
                      ]),
                    )),
                  ]),
      ),
    );
  }

  Widget _infoCard(IconData icon, String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 11),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: _grey, fontSize: 10)),
      ]),
    ));
  }
}