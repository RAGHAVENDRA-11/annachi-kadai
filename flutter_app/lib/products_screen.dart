import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'api_service.dart';
import 'main.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _products = [];
  List _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await ApiService.getProducts();
    setState(() {
      _products = data;
      _filtered = data;
      _loading = false;
    });
  }

  void _search(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _products
          : _products
              .where((p) => p['name']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
    });
  }

  void _showToast(BuildContext context, String name) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
            Text('$name added to cart!',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(dynamic imageData, double size) {
    if (imageData != null && imageData.toString().isNotEmpty) {
      try {
        String base64Str = imageData.toString();
        if (base64Str.contains(',')) {
          base64Str = base64Str.split(',').last;
        }
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _placeholder(size),
        );
      } catch (e) {
        return _placeholder(size);
      }
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: const Icon(Icons.shopping_bag_outlined,
          size: 48, color: Color(0xFFDDDDDD)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // TOP BAR
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good morning! 🌅',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const Text('What do you need today?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search groceries...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PRODUCTS GRID
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
                : _filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No products found',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFFFF6B00),
                        onRefresh: loadProducts,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final p = _filtered[index];
                              final isLow = (p['stock_quantity'] as int) < 10;
                              final cartProv = context.watch<CartProvider>();
                              final qty = cartProv.getQuantity(p['id']);

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFF0F0F0), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // IMAGE AREA
                                    Stack(
                                      children: [
                                        Container(
                                          height: 120,
                                          width: double.infinity,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFAFAFA),
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(14)),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(14)),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: _buildProductImage(
                                                  p['image'], 100),
                                            ),
                                          ),
                                        ),
                                        // Low stock badge
                                        if (isLow)
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text('Low Stock',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                      ],
                                    ),

                                    // PRODUCT INFO
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 8, 10, 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(p['name'],
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                        color:
                                                            Color(0xFF1A1A2E)),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                                const SizedBox(height: 2),
                                                Text('1 ${p['unit']}',
                                                    style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 11)),
                                              ],
                                            ),

                                            // PRICE + ADD BUTTON
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text('₹${p['price']}',
                                                    style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF1A1A2E))),

                                                // ADD / QTY STEPPER
                                                qty == 0
                                                    ? GestureDetector(
                                                        onTap: () {
                                                          cart.addItem({
                                                            'id': p['id'],
                                                            'name': p['name'],
                                                            'price':
                                                                double.parse(
                                                                    p['price']
                                                                        .toString()),
                                                            'unit': p['unit'],
                                                          });
                                                          _showToast(context,
                                                              p['name']);
                                                        },
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                color: const Color(
                                                                    0xFFFF6B00)),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          child: const Text(
                                                              'ADD',
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0xFFFF6B00),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      12)),
                                                        ),
                                                      )
                                                    : Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFFFF6B00),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () =>
                                                                  cart.removeItem(
                                                                      p['id']),
                                                              child: const Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            4),
                                                                child: Icon(
                                                                    Icons
                                                                        .remove,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 14),
                                                              ),
                                                            ),
                                                            Text('$qty',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        13)),
                                                            GestureDetector(
                                                              onTap: () {
                                                                cart.addItem({
                                                                  'id': p['id'],
                                                                  'name':
                                                                      p['name'],
                                                                  'price': double
                                                                      .parse(p[
                                                                              'price']
                                                                          .toString()),
                                                                  'unit':
                                                                      p['unit'],
                                                                });
                                                              },
                                                              child: const Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            4),
                                                                child: Icon(
                                                                    Icons.add,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 14),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}