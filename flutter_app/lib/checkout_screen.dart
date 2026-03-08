import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'main.dart';
import 'api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF9FAFB);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _white   = Color(0xFFFFFFFF);
  static const Color _red     = Color(0xFFEF4444);
  static const Color _green   = Color(0xFF10B981);
  static const Color _amber   = Color(0xFFD97706);

  final _notesCtrl = TextEditingController();

  bool _locating      = false;
  bool _validating    = false;
  bool _placing       = false;
  bool _locationSet   = false;
  bool _addressValid  = false;

  double? _lat, _lng;
  String _resolvedAddress = '';
  String _paymentMethod = 'cod'; // 'cod' only for now
  String _distanceText    = '';
  String _locationError   = '';

  // ── GET GPS LOCATION ──
  Future<void> _detectLocation() async {
    setState(() { _locating = true; _locationError = ''; _addressValid = false; _locationSet = false; });

    try {
      // Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _locationError = 'Location permission denied. Please enable in settings.'; });
        setState(() => _locating = false);
        return;
      }

      // Get position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _lat = pos.latitude;
      _lng = pos.longitude;

      // Reverse geocode to get readable address
      try {
        final placemarks = await placemarkFromCoordinates(_lat!, _lng!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.name, p.subLocality, p.locality, p.postalCode
          ].where((s) => s != null && s.isNotEmpty).toList();
          _resolvedAddress = parts.join(', ');
        }
      } catch (_) {
        _resolvedAddress = '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}';
      }

      setState(() => _locationSet = true);

      // Auto-validate distance
      await _validateDistance();

    } catch (e) {
      setState(() => _locationError = 'Could not get location. Please try again.');
    }
    setState(() => _locating = false);
  }

  // ── VALIDATE 3KM DISTANCE ──
  Future<void> _validateDistance() async {
    if (_lat == null || _lng == null) return;
    setState(() { _validating = true; _addressValid = false; });
    try {
      final res = await ApiService.validateCoordinates(_lat!, _lng!);
      setState(() {
        _addressValid = res['within_range'] == true;
        final dist = res['distance_km'];
        _distanceText = dist != null ? '${(dist as num).toStringAsFixed(2)} km from shop' : '';
        _locationError = _addressValid ? '' :
            'Sorry! Your location is $_distanceText away. We only deliver within 3km.';
      });
    } catch (e) {
      setState(() => _locationError = e.toString().replaceAll('Exception: ', ''));
    }
    setState(() => _validating = false);
  }

  // ── PLACE ORDER ──
  Future<void> _placeOrder(BuildContext context) async {
    if (!_addressValid) { _snack('Please detect your location first', isError: true); return; }
    final cart = context.read<CartProvider>();
    setState(() => _placing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId    = prefs.getInt('customer_id') ?? 1;
      final customerName  = prefs.getString('customer_name') ?? '';
      final customerEmail = prefs.getString('customer_email') ?? '';

      final items = cart.items.map((i) => {
        'product_id': i['id'],
        'name':       i['name'],
        'quantity':   i['quantity'],
        'price':      i['price'],
        'unit':       i['unit'],
      }).toList();

      final res = await ApiService.placeOrderWithBill({
        'customer_id':       customerId,
        'customer_name':     customerName,
        'customer_email':    customerEmail,
        'delivery_address':  _resolvedAddress,
        'delivery_lat':      _lat,
        'delivery_lng':      _lng,
        'notes':             _notesCtrl.text.trim(),
        'payment_method':    _paymentMethod,
        'items':             items,
        'total_amount':      cart.totalPrice,
      });

      cart.clear();
      if (mounted) _showSuccess(context, orderId: res['order_id']?.toString() ?? '');
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
    setState(() => _placing = false);
  }

  void _showSuccess(BuildContext context, {required String orderId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(color: _yellow, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _yellow.withOpacity(0.4), blurRadius: 20)]),
            child: Icon(Icons.check_rounded, color: _navy, size: 38)),
          const SizedBox(height: 18),
          Text('Order Confirmed! 🎉', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Order #$orderId', style: TextStyle(color: _grey, fontSize: 13)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.email_outlined, color: _green, size: 14),
            const SizedBox(width: 6),
            Text('PDF bill sent to your email!', style: TextStyle(color: _green,
                fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.money_rounded, color: _green, size: 14),
              const SizedBox(width: 6),
              Text('Pay cash on delivery', style: TextStyle(color: _green,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.access_time_rounded, color: _amber, size: 14),
              const SizedBox(width: 6),
              Text('Delivery in ~10 minutes', style: TextStyle(color: _amber,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: _navy,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Back to Shop', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ])),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? _white : _navy, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(
            color: isError ? _white : _navy, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? _red : _yellow,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      backgroundColor: _greyLt,
      appBar: AppBar(
        backgroundColor: _white,
        foregroundColor: _navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── LOCATION CARD ──
          _card(
            icon: Icons.location_on_rounded, iconColor: _red,
            title: 'Delivery Location',
            subtitle: 'We deliver within 3km of our shop',
            child: Column(children: [

              // Big detect button
              GestureDetector(
                onTap: _locating ? null : _detectLocation,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _locationSet
                        ? (_addressValid ? _green.withOpacity(0.06) : _red.withOpacity(0.06))
                        : _yellow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _locationSet
                          ? (_addressValid ? _green : _red)
                          : _yellow,
                      width: 1.5,
                    ),
                  ),
                  child: Column(children: [
                    // Icon circle
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: _locationSet
                            ? (_addressValid ? _green : _red)
                            : _yellow,
                        shape: BoxShape.circle,
                      ),
                      child: _locating
                          ? Padding(padding: const EdgeInsets.all(14),
                              child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                          : Icon(
                              _locationSet
                                  ? (_addressValid ? Icons.check_circle_rounded : Icons.location_off_rounded)
                                  : Icons.my_location_rounded,
                              color: _locationSet ? _white : _navy,
                              size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _locating ? 'Detecting your location...'
                          : _locationSet
                              ? (_addressValid ? 'Location Verified ✓' : 'Outside Delivery Zone')
                              : 'Tap to Detect My Location',
                      style: TextStyle(
                        color: _locationSet ? (_addressValid ? _green : _red) : _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locating ? 'Please wait...'
                          : _locationSet ? _resolvedAddress
                              : 'Uses your GPS to auto-detect address',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _grey, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              ),

              // Distance badge
              if (_distanceText.isNotEmpty && _addressValid) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.directions_bike_rounded, color: _green, size: 16),
                    const SizedBox(width: 8),
                    Text('$_distanceText — Within delivery zone!',
                        style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],

              // Error message
              if (_locationError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _red.withOpacity(0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, color: _red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_locationError,
                        style: TextStyle(color: _red, fontSize: 12, height: 1.4))),
                  ]),
                ),
              ],

              // Retry button
              if (_locationSet && !_addressValid) ...[
                const SizedBox(height: 10),
                SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: _navy,
                        side: BorderSide(color: _border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _detectLocation,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 14),

          // ── DELIVERY NOTES ──
          _card(
            icon: Icons.note_alt_outlined, iconColor: _amber,
            title: 'Delivery Notes',
            subtitle: 'Optional instructions',
            child: _inputField(controller: _notesCtrl,
                label: 'Notes (optional)',
                hint: 'e.g. Ring the bell twice, leave at door...',
                icon: Icons.edit_note_rounded, maxLines: 3),
          ),

          const SizedBox(height: 14),

          // ── ORDER SUMMARY ──
          _card(
            icon: Icons.receipt_long_rounded, iconColor: _amber,
            title: 'Order Summary',
            subtitle: '${cart.totalItems} item${cart.totalItems != 1 ? 's' : ''}',
            child: Column(children: [
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: _yellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.shopping_bag_outlined, color: _amber, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['name'], style: TextStyle(color: _navy,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${item['unit']} × ${item['quantity']}',
                        style: TextStyle(color: _grey, fontSize: 11)),
                  ])),
                  Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                      style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              )),
              Divider(color: _border),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Delivery', style: TextStyle(color: _grey, fontSize: 13)),
                Text('FREE', style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total', style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('₹${cart.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
            ]),
          ),

          const SizedBox(height: 14),

          // ── PAYMENT METHOD ──
          _card(
            icon: Icons.payment_rounded, iconColor: const Color(0xFF8B5CF6),
            title: 'Payment Method',
            subtitle: 'How will you pay?',
            child: Column(children: [
              _paymentTile(
                value: 'cod',
                icon: Icons.money_rounded,
                iconColor: _green,
                title: 'Cash on Delivery',
                subtitle: 'Pay when your order arrives',
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // ── PDF BILL NOTE ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _yellow.withOpacity(0.4)),
            ),
            child: Row(children: [
              Icon(Icons.picture_as_pdf_rounded, color: _amber, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PDF Bill will be emailed', style: TextStyle(color: _navy,
                    fontWeight: FontWeight.w700, fontSize: 13)),
                Text('A detailed invoice will be sent to your registered email.',
                    style: TextStyle(color: _grey, fontSize: 11, height: 1.4)),
              ])),
            ]),
          ),

          const SizedBox(height: 24),

          // ── PLACE ORDER BUTTON ──
          SizedBox(width: double.infinity, height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _addressValid ? _yellow : _border,
                foregroundColor: _addressValid ? _navy : _grey,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (_placing || !_addressValid) ? null : () => _placeOrder(context),
              child: _placing
                  ? SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: _navy, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text('Place Order · ₹${cart.totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
            ),
          ),
          if (!_addressValid) ...[
            const SizedBox(height: 8),
            Center(child: Text(
                _locationSet ? 'Location is outside delivery zone'
                    : 'Detect your location to place order',
                style: TextStyle(color: _grey, fontSize: 12))),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _card({required IconData icon, required Color iconColor,
      required String title, required String subtitle, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
            Text(subtitle, style: TextStyle(color: _grey, fontSize: 11)),
          ]),
        ])),
        Divider(height: 1, color: _border),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }

  Widget _inputField({required TextEditingController controller, required String label,
      required String hint, required IconData icon, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border)),
        child: TextField(
          controller: controller, maxLines: maxLines,
          style: TextStyle(color: _navy, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: _grey.withOpacity(0.6), fontSize: 13),
            prefixIcon: maxLines == 1 ? Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(icon, color: _grey, size: 16)) : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
                horizontal: maxLines > 1 ? 14 : 0, vertical: 13),
          ),
        ),
      ),
    ]);
  }

  Widget _paymentTile({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _green.withOpacity(0.06) : _greyLt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _green : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: _navy,
                fontWeight: FontWeight.w700, fontSize: 14)),
            Text(subtitle, style: TextStyle(color: _grey, fontSize: 11)),
          ])),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _green : Colors.transparent,
              border: Border.all(color: selected ? _green : _border, width: 2),
            ),
            child: selected
                ? Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ]),
      ),
    );
  }

}