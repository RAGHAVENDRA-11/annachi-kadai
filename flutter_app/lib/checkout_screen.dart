import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'main.dart';
import 'api_service.dart';
import 'home_screen.dart';
import 'prefs_helper.dart';
import 'membership_provider.dart';
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
  String _membershipCard = '';
  String _membershipType = '';
  bool _useMembership = false;
  bool _usePoints = false;
  int _rewardPoints = 0; // 1 point = ₹1
  String _distanceText    = '';
  String _locationError   = '';
  final _addressCtrl      = TextEditingController(); // manual delivery address
  int _monthlyLimit       = 0;   // max spend per month for membership
  double _monthlySpent    = 0.0; // spent this month
  double _monthlyRemaining = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    // Membership loaded from MembershipProvider (DB-backed, no prefs)
    final prefs = await SharedPreferences.getInstance();
    final cid = (prefs.get('customer_id') ?? '').toString();
    final mem = context.read<MembershipProvider>();
    if (mem.membershipType.isEmpty && cid.isNotEmpty) {
      await mem.load(cid);
    }
    if (mounted) setState(() {
      _membershipType   = mem.membershipType;
      _membershipCard   = mem.cardNumber;
      _rewardPoints     = mem.rewardPoints;
      _monthlyLimit     = mem.monthlyLimit;
      _monthlySpent     = mem.monthlySpent;
      _monthlyRemaining = mem.monthlyRemaining;
    });
  }

  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

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
      _addressCtrl.text = _resolvedAddress; // pre-fill editable address
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

    // Check monthly limit for members
    if (_membershipType.isNotEmpty && _monthlyLimit > 0) {
      final orderTotal = cart.totalPrice;
      if (_monthlySpent + orderTotal > _monthlyLimit) {
        final remaining = (_monthlyLimit - _monthlySpent).clamp(0.0, _monthlyLimit.toDouble());
        _snack('Monthly limit exceeded! You have ₹${remaining.toStringAsFixed(0)} remaining this month.', isError: true);
        return;
      }
    }

    setState(() => _placing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId    = int.tryParse((prefs.get('customer_id') ?? '').toString()) ?? 1;
      final customerName  = prefs.getString('customer_name') ?? '';
      final customerEmail = prefs.getString('customer_email') ?? '';
      // (membership already loaded in initState)

      final hasMembership = _useMembership && (_membershipType == 'diamond' || _membershipType == 'gold');
      final delivery = (cart.totalPrice >= 299 || hasMembership) ? 0.0 : 40.0;
      final ptsDiscount = (_usePoints && _rewardPoints > 0 && cart.totalPrice >= 1000)
          ? _rewardPoints.toDouble().clamp(0.0, cart.totalPrice * 0.5) : 0.0;
      final grandTotal = cart.totalPrice + delivery - ptsDiscount;

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
        'delivery_address':  _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim() : _resolvedAddress,
        'delivery_lat':      _lat,
        'delivery_lng':      _lng,
        'notes':             _notesCtrl.text.trim(),
        'payment_method':    _paymentMethod,
        'items':             items,
        'total_amount':      grandTotal,
      });

      cart.clear();

      // ── Track spend + points via MembershipProvider ──
      final mem = context.read<MembershipProvider>();
      await mem.recordSpend(customerId.toString(), grandTotal);
      if (_usePoints && _rewardPoints > 0) {
        await mem.redeemPoints(customerId.toString());
      }

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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
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

          // ── DELIVERY ADDRESS (editable after location verified) ──
          if (_addressValid)
            _card(
              icon: Icons.home_rounded, iconColor: _green,
              title: 'Delivery Address',
              subtitle: 'Confirm or edit your address',
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: _navy, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Door no, Street, Landmark, Area...',
                    hintStyle: TextStyle(color: _grey, fontSize: 12),
                    filled: true,
                    fillColor: _greyLt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _green, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    prefixIcon: const Icon(Icons.edit_location_alt_rounded,
                        color: _green, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: _grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(
                    'GPS detected your location. Add door no / landmark for faster delivery.',
                    style: TextStyle(color: _grey, fontSize: 11),
                  )),
                ]),
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
          Builder(builder: (context) {
            final cart = context.watch<CartProvider>();
            final subtotal = cart.totalPrice;
            final hasMembership = _useMembership && (_membershipType == 'diamond' || _membershipType == 'gold');
            final deliveryCharge = (subtotal >= 299 || hasMembership) ? 0.0 : 40.0;
            final pointsDiscount = (_usePoints && _rewardPoints > 0 && subtotal >= 1000)
                ? _rewardPoints.toDouble().clamp(0, subtotal * 0.5) : 0.0;
            final grandTotal = subtotal + deliveryCharge - pointsDiscount;

            return _card(
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
                      Text(item['name'], style: const TextStyle(color: _navy,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${item['unit']} × ${item['quantity']}',
                          style: const TextStyle(color: _grey, fontSize: 11)),
                    ])),
                    Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                        style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                )),
                const Divider(),
                // Subtotal
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Subtotal', style: TextStyle(color: _grey, fontSize: 13)),
                  Text('₹${subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(color: _navy, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                // Delivery
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    const Text('Delivery', style: TextStyle(color: _grey, fontSize: 13)),
                    if (deliveryCharge == 0 && hasMembership) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F36).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_membershipType == 'diamond' ? '💎 Pass' : '⭐ Pass',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ] else if (deliveryCharge == 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Above ₹299', style: TextStyle(
                            color: _green, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                  deliveryCharge == 0
                      ? const Text('FREE', style: TextStyle(
                          color: _green, fontWeight: FontWeight.w700))
                      : Text('₹${deliveryCharge.toStringAsFixed(0)}',
                          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
                if (deliveryCharge > 0) ...[
                  const SizedBox(height: 4),
                  Container(
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
                        'Add ₹${(299 - subtotal).toStringAsFixed(0)} more for free delivery, or apply your membership card.',
                        style: TextStyle(color: _amber, fontSize: 11),
                      )),
                    ]),
                  ),
                ],
                // Points discount row
                if (_usePoints && pointsDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      const Text('Points Redeemed', style: TextStyle(color: _grey, fontSize: 13)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('${pointsDiscount.toInt()} pts',
                            style: const TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    Text('- ₹${pointsDiscount.toStringAsFixed(0)}',
                        style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ],
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
                ]),
              ]),
            );
          }),

          const SizedBox(height: 14),

          // ── REDEEM POINTS ──
          if (_rewardPoints > 0) ...[
            const SizedBox(height: 14),
            Builder(builder: (context) {
              final cart = context.watch<CartProvider>();
              final eligible = cart.totalPrice >= 1000;
              return _card(
                icon: Icons.stars_rounded, iconColor: const Color(0xFFD97706),
                title: 'Reward Points',
                subtitle: 'You have $_rewardPoints points = ₹$_rewardPoints',
                child: GestureDetector(
                  onTap: eligible ? () => setState(() => _usePoints = !_usePoints) : null,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: !eligible
                          ? _greyLt
                          : _usePoints ? _green.withOpacity(0.08) : _greyLt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: !eligible
                              ? _border
                              : _usePoints ? _green.withOpacity(0.4) : _border),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: !eligible
                              ? _border.withOpacity(0.5)
                              : _usePoints ? _green.withOpacity(0.15) : _border.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.toll_rounded,
                            color: !eligible ? _grey : (_usePoints ? _green : _grey), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Redeem $_rewardPoints Points',
                            style: TextStyle(
                                color: eligible ? _navy : _grey,
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          !eligible
                              ? 'Available for orders above ₹1,000'
                              : (_usePoints
                                  ? '✓ Saving ₹$_rewardPoints on this order'
                                  : 'Tap to use your reward points'),
                          style: TextStyle(
                              color: !eligible ? _grey : (_usePoints ? _green : _grey),
                              fontSize: 11)),
                      ])),
                      Container(width: 24, height: 24,
                        decoration: BoxDecoration(
                            color: !eligible ? _border : (_usePoints ? _green : _border),
                            shape: BoxShape.circle),
                        child: Icon(
                            !eligible ? Icons.lock_rounded : (_usePoints ? Icons.check : Icons.add),
                            color: Colors.white, size: 14),
                      ),
                    ]),
                  ),
                ),
              );
            }),
          ],
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

          // ── MEMBERSHIP CARD ──
          if (_membershipCard.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Monthly limit banner
            if (_monthlyLimit > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _membershipType == 'diamond'
                      ? const Color(0xFF1A1F36).withOpacity(0.06)
                      : const Color(0xFFD97706).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _membershipType == 'diamond'
                      ? const Color(0xFF818CF8).withOpacity(0.3)
                      : const Color(0xFFD97706).withOpacity(0.3)),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Icon(_membershipType == 'diamond'
                          ? Icons.diamond_rounded : Icons.star_rounded,
                          color: _membershipType == 'diamond'
                              ? const Color(0xFF818CF8) : const Color(0xFFD97706),
                          size: 16),
                      const SizedBox(width: 6),
                      Text('${_membershipType == 'diamond' ? 'Diamond' : 'Gold'} Pass — Monthly Limit',
                          style: const TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 12)),
                    ]),
                    Text('₹${_monthlyRemaining.toStringAsFixed(0)} left',
                        style: TextStyle(
                            color: _monthlyRemaining < 200 ? _red : _green,
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _monthlyLimit > 0 ? (_monthlyRemaining / _monthlyLimit).clamp(0.0, 1.0) : 0.0,
                      minHeight: 6,
                      backgroundColor: _border,
                      color: _monthlyRemaining < 200 ? _red : _green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Spent: ₹${_monthlySpent.toStringAsFixed(0)}',
                        style: const TextStyle(color: _grey, fontSize: 11)),
                    Text('Limit: ₹$_monthlyLimit/month',
                        style: const TextStyle(color: _grey, fontSize: 11)),
                  ]),
                ]),
              ),
            _card(
              icon: Icons.workspace_premium_rounded, iconColor: const Color(0xFF818CF8),
              title: 'Membership Card',
              subtitle: 'Apply your ${_membershipType == 'diamond' ? 'Diamond' : 'Gold'} Pass',
              child: GestureDetector(
                onTap: () => setState(() => _useMembership = !_useMembership),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _membershipType == 'diamond'
                          ? [const Color(0xFF1A1F36), const Color(0xFF2D3561)]
                          : [const Color(0xFFB45309), const Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(_membershipType == 'diamond'
                        ? Icons.diamond_rounded : Icons.star_rounded,
                        color: _membershipType == 'diamond'
                            ? const Color(0xFF818CF8) : _yellow, size: 24),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_membershipCard,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(_useMembership ? '✓ Card applied' : 'Tap to apply card',
                          style: TextStyle(
                              color: _useMembership ? _green : Colors.white54,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ])),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: _useMembership ? _green : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_useMembership ? Icons.check : Icons.add,
                          color: Colors.white, size: 14),
                    ),
                  ]),
                ),
              ),
            ),
          ], // end membership block

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
                  : Builder(builder: (ctx) {
                      final c = ctx.watch<CartProvider>();
                      final hasMembership = _useMembership && (_membershipType == 'diamond' || _membershipType == 'gold');
                      final delivery = (c.totalPrice >= 299 || hasMembership) ? 0.0 : 40.0;
                      final pts = (_usePoints && _rewardPoints > 0 && c.totalPrice >= 1000)
                          ? _rewardPoints.toDouble().clamp(0, c.totalPrice * 0.5) : 0.0;
                      final grand = c.totalPrice + delivery - pts;
                      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: 10),
                        Text('Place Order · ₹${grand.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ]);
                    }),
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