import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _white   = Color(0xFFFFFFFF);

  List _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadOrders(); }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('customer_id');
      if (customerId != null) {
        final data = await ApiService.getOrders(customerId);
        setState(() => _orders = data);
      }
    } catch (e) {
      debugPrint('Orders error: $e');
    }
    setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':  return const Color(0xFF10B981);
      case 'cancelled':  return const Color(0xFFEF4444);
      case 'pending':    return const Color(0xFFF59E0B);
      case 'processing': return const Color(0xFF3B82F6);
      default:           return _grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':  return Icons.check_circle_rounded;
      case 'cancelled':  return Icons.cancel_rounded;
      case 'pending':    return Icons.schedule_rounded;
      case 'processing': return Icons.sync_rounded;
      default:           return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyLt,
      body: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          color: _white,
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Orders', style: TextStyle(color: _navy, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('${_orders.length} order${_orders.length != 1 ? 's' : ''} placed',
                  style: TextStyle(color: _grey, fontSize: 13)),
            ])),
            IconButton(
              onPressed: _loadOrders,
              icon: Icon(Icons.refresh_rounded, color: _navy),
              tooltip: 'Refresh',
            ),
          ]),
        ),
        Container(height: 1, color: _border),

        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: _yellow, strokeWidth: 2.5))
              : _orders.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: _yellow, backgroundColor: _white,
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _orderCard(_orders[index]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _orderCard(dynamic order) {
    final status = (order['status'] ?? 'pending').toString();
    final statusColor = _statusColor(status);
    final total = double.tryParse(order['total_amount'].toString()) ?? 0.0;
    final orderId = order['id'] ?? order['order_id'];
    final date = order['created_at']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Order header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _yellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.receipt_long_rounded, color: const Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order #$orderId',
                  style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(date, style: TextStyle(color: _grey, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_statusIcon(status), color: statusColor, size: 12),
                const SizedBox(width: 4),
                Text(status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),

        Divider(height: 1, color: _border),

        // Total
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(children: [
            Icon(Icons.currency_rupee_rounded, color: _grey, size: 14),
            const SizedBox(width: 4),
            Text('Total Amount', style: TextStyle(color: _grey, fontSize: 13)),
            const Spacer(),
            Text('₹${total.toStringAsFixed(2)}',
                style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 90, height: 90,
          decoration: BoxDecoration(color: _yellow.withOpacity(0.1),
              shape: BoxShape.circle, border: Border.all(color: _yellow.withOpacity(0.3), width: 2)),
          child: Icon(Icons.receipt_long_outlined, color: const Color(0xFFD97706), size: 42)),
      const SizedBox(height: 20),
      Text('No orders yet', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Your order history will appear here', style: TextStyle(color: _grey, fontSize: 14)),
    ]));
  }
}