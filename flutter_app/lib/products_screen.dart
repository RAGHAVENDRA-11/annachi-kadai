import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String selectedCategory;
  const ProductsScreen({super.key, this.selectedCategory = 'All'});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _red     = Color(0xFFEF4444);

  List _products = [];
  List _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Timer? _refreshTimer;

  final Map<String, int> _catIds = {'Grocery': 1, 'Ice Cream': 2, 'Stationery': 3};

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh every 30 seconds to catch stock changes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductsScreen old) {
    super.didUpdateWidget(old);
    if (old.selectedCategory != widget.selectedCategory) _applyFilter(_searchCtrl.text);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final data = await ApiService.getProducts();
    if (mounted) {
      setState(() { _products = data; _loading = false; });
      _applyFilter(_searchCtrl.text);
    }
  }

  void _applyFilter(String q) {
    setState(() {
      var r = _products;
      if (widget.selectedCategory != 'All') {
        final id = _catIds[widget.selectedCategory];
        if (id != null) r = r.where((p) => p['category_id'] == id).toList();
      }
      if (q.isNotEmpty) r = r.where((p) => p['name'].toString().toLowerCase().contains(q.toLowerCase())).toList();
      _filtered = r;
    });
  }

  Widget _buildImage(dynamic data, double size) {
    if (data != null && data.toString().isNotEmpty) {
      try {
        String s = data.toString();
        if (s.contains(',')) s = s.split(',').last;
        final bytes = base64Decode(s);
        return Image.memory(bytes, fit: BoxFit.contain, width: size, height: size,
            errorBuilder: (_, __, ___) => _placeholder(size));
      } catch (_) { return _placeholder(size); }
    }
    return _placeholder(size);
  }

  Widget _placeholder(double s) => SizedBox(width: s, height: s,
      child: Icon(Icons.shopping_bag_outlined, size: 36, color: _border));

  void _toast(BuildContext ctx, String name) {
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      backgroundColor: _navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
      content: Row(children: [
        Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.check_rounded, color: _navy, size: 14)),
        const SizedBox(width: 12),
        Text('$name added!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Scaffold(
      backgroundColor: _greyLt,
      body: Column(children: [
        // TOP BAR
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          color: _white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _yellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _yellow.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bolt_rounded, color: const Color(0xFFD97706), size: 13),
                  const SizedBox(width: 4),
                  Text('10 min delivery', style: TextStyle(color: const Color(0xFFD97706),
                      fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              const Spacer(),
              if (_filtered.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border)),
                  child: Text('${_filtered.length} items',
                      style: TextStyle(color: _grey, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 10),
            Text(widget.selectedCategory == 'All' ? 'What do you need?' : widget.selectedCategory,
                style: TextStyle(color: _navy, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border)),
              child: TextField(
                controller: _searchCtrl, onChanged: _applyFilter,
                style: TextStyle(color: _navy, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: _grey.withOpacity(0.7), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: _grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ]),
        ),
        Container(height: 1, color: _border),

        // GRID
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2.5))
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inventory_2_outlined, size: 56, color: _grey.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(widget.selectedCategory == 'All' ? 'No products found'
                          : 'No ${widget.selectedCategory} items',
                          style: TextStyle(color: _grey, fontSize: 15)),
                    ]))
                  : RefreshIndicator(color: _yellow, backgroundColor: _white, onRefresh: _load,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, childAspectRatio: 0.78,
                              crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final p = _filtered[i];
                            final stockQty = (p['stock_quantity'] ?? 0) is int
                                ? (p['stock_quantity'] ?? 0) as int
                                : (p['stock_quantity'] ?? 0).toInt();
                            final isLow = stockQty > 0 && stockQty < 10;
                            final isOutOfStock = stockQty == 0;
                            final qty = context.watch<CartProvider>().getQuantity(p['id']);

                            void addToCart() {
                              if (isOutOfStock) return;
                              cart.addItem({
                                'id': p['id'], 'name': p['name'],
                                'price': double.parse(p['price'].toString()),
                                'unit': p['unit'],
                              });
                              _toast(context, p['name']);
                            }

                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: Map<String, dynamic>.from(p)),
                                ));
                                // Refresh stock when returning from detail
                                _load(silent: true);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isOutOfStock ? const Color(0xFFF3F4F6) : _white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: qty > 0 ? const Color(0xFFE6BE00) : _border,
                                      width: qty > 0 ? 2 : 1),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  // Image
                                  Stack(children: [
                                    Container(
                                      height: 110, width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? const Color(0xFFF3F4F6)
                                              : const Color(0xFFFFFBE6),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13))),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                        child: Padding(padding: const EdgeInsets.all(10),
                                            child: _buildImage(p['image'], 90)),
                                      ),
                                    ),
                                    if (isLow)
                                      Positioned(top: 6, left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Low Stock', style: TextStyle(color: Colors.white,
                                              fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    if (isOutOfStock)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.6),
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(13))),
                                          child: Center(child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: _red, borderRadius: BorderRadius.circular(6)),
                                            child: const Text('Out of Stock', style: TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                          )),
                                        ),
                                      ),
                                    if (qty > 0)
                                      Positioned(top: 6, right: 6,
                                        child: Container(
                                          width: 20, height: 20,
                                          decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle),
                                          child: Center(child: Text('$qty', style: TextStyle(
                                              color: _navy, fontSize: 10, fontWeight: FontWeight.bold))),
                                        ),
                                      ),
                                  ]),

                                  // Info + Button
                                  Expanded(child: Padding(
                                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(p['name'], style: TextStyle(fontWeight: FontWeight.w700,
                                              fontSize: 13, color: _navy),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 2),
                                          Text('1 ${p['unit']}', style: TextStyle(color: _grey, fontSize: 11)),
                                        ]),
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                          Text('₹${p['price']}', style: TextStyle(fontSize: 15,
                                              fontWeight: FontWeight.w800, color: _navy)),
                                          if (!isOutOfStock)
                                            qty == 0
                                            ? GestureDetector(
                                                onTap: addToCart,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                                  decoration: BoxDecoration(
                                                    color: _yellow,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text('ADD', style: TextStyle(color: _navy,
                                                      fontWeight: FontWeight.bold, fontSize: 12)),
                                                ),
                                              )
                                            : Container(
                                                decoration: BoxDecoration(color: _navy,
                                                    borderRadius: BorderRadius.circular(8)),
                                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                  GestureDetector(
                                                    onTap: () => context.read<CartProvider>().removeItem(p['id']),
                                                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                        child: Icon(Icons.remove, color: _yellow, size: 14)),
                                                  ),
                                                  Text('$qty', style: TextStyle(color: _yellow,
                                                      fontWeight: FontWeight.bold, fontSize: 13)),
                                                  GestureDetector(
                                                    onTap: () => context.read<CartProvider>().addItem(
                                                        {'id': p['id'], 'name': p['name'],
                                                          'price': double.parse(p['price'].toString()),
                                                          'unit': p['unit']}),
                                                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                        child: Icon(Icons.add, color: _yellow, size: 14)),
                                                  ),
                                                ]),
                                              ),
                                        ]),
                                      ],
                                    ),
                                  )),
                                ]),
                              ),
                            );
                          },
                        ),
                      )),
        ),
      ]),
    );
  }
}