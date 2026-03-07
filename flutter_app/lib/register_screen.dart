import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  static const Color _yellow  = Color(0xFFFFD60A);
  static const Color _yellowDk= Color(0xFFE6BE00);
  static const Color _navy    = Color(0xFF1A1F36);
  static const Color _grey    = Color(0xFF6B7280);
  static const Color _greyLt  = Color(0xFFF3F4F6);
  static const Color _border  = Color(0xFFE5E7EB);
  static const Color _white   = Color(0xFFFFFFFF);

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _otpSent = false;
  int _resendTimer = 0;

  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose(); _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendTimer = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendTimer--);
      return _resendTimer > 0;
    });
  }

  Future<void> _sendOtp() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      _snack('Name and email are required', isError: true); return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.registerSendOtp({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      setState(() => _otpSent = true);
      _startTimer();
      _snack('OTP sent to your email!');
      Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _otpFocus[0].requestFocus(); });
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) { _snack('Enter all 6 digits', isError: true); return; }
    setState(() => _loading = true);
    try {
      final res = await ApiService.registerVerifyOtp(
          _emailCtrl.text.trim(), otp, _nameCtrl.text.trim(), _phoneCtrl.text.trim());
      if (res.containsKey('id')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('customer_id', res['id']);
        await prefs.setString('customer_name', res['name'] ?? '');
        await prefs.setString('customer_email', res['email'] ?? '');
        if (mounted) Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
      } else {
        _snack(res['detail'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
    setState(() => _loading = false);
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? _white : _navy, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(color: isError ? _white : _navy, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isError ? const Color(0xFFEF4444) : _yellow,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    return Scaffold(
      backgroundColor: _white,
      body: FadeTransition(opacity: _fade,
          child: isWide ? _wide() : _narrow()),
    );
  }

  Widget _wide() {
    return Row(children: [
      Expanded(flex: 5, child: Container(
        color: _yellow,
        child: Stack(children: [
          Positioned(bottom: -60, left: -60, child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.06)))),
          Positioned(top: -40, right: -40, child: Container(width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.04)))),
          Center(child: Padding(padding: const EdgeInsets.all(52),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.storefront_rounded, color: _yellow, size: 34)),
                const SizedBox(height: 28),
                const Text('Join\nAnnachi Kadai', style: TextStyle(color: _navy,
                    fontSize: 42, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1)),
                const SizedBox(height: 12),
                Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text('Create your account and\nstart shopping in 30 seconds.',
                    style: TextStyle(color: _navy.withOpacity(0.7), fontSize: 16, height: 1.6)),
                const SizedBox(height: 44),
                ...[('🎁', 'Free delivery on first order'), ('⚡', '10-minute delivery'), ('🔒', 'Secure OTP login')]
                    .map((f) => Padding(padding: const EdgeInsets.only(bottom: 14),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: _navy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(f.$1, style: const TextStyle(fontSize: 16)))),
                    const SizedBox(width: 12),
                    Text(f.$2, style: TextStyle(color: _navy.withOpacity(0.8),
                        fontSize: 15, fontWeight: FontWeight.w500)),
                  ]),
                )),
              ],
            ),
          )),
        ]),
      )),
      Expanded(flex: 4, child: Container(
        color: _white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 60),
          child: Align(alignment: Alignment.topCenter,
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360),
                child: _form())),
        ),
      )),
    ]);
  }

  Widget _narrow() {
    return SafeArea(child: Column(children: [
      Container(color: _yellow, padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(children: [
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: _navy, size: 16))),
          const SizedBox(width: 14),
          Text('Create Account', style: TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: _form(),
      )),
    ]));
  }

  Widget _form() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim,
          child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(anim),
              child: child)),
      child: _otpSent ? _otpStep(key: const ValueKey('otp')) : _detailsStep(key: const ValueKey('details')),
    );
  }

  Widget _detailsStep({Key? key}) {
    return Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Create account', style: TextStyle(color: _navy, fontSize: 26,
          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      Text('Fill in your details to get started', style: TextStyle(color: _grey, fontSize: 14)),
      const SizedBox(height: 28),
      _label('Full Name *'), const SizedBox(height: 8),
      _input(controller: _nameCtrl, hint: 'Your full name', icon: Icons.person_outline_rounded),
      const SizedBox(height: 16),
      _label('Email Address *'), const SizedBox(height: 8),
      _input(controller: _emailCtrl, hint: 'name@example.com',
          icon: Icons.alternate_email_rounded, type: TextInputType.emailAddress),
      const SizedBox(height: 16),
      _label('Phone (optional)'), const SizedBox(height: 8),
      _input(controller: _phoneCtrl, hint: '+91 98765 43210',
          icon: Icons.phone_outlined, type: TextInputType.phone),
      const SizedBox(height: 28),
      _btn(label: 'Send Verification Code', icon: Icons.send_rounded, onTap: _sendOtp, loading: _loading),
      const SizedBox(height: 20),
      Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Already have an account? ', style: TextStyle(color: _grey, fontSize: 13)),
        GestureDetector(onTap: () => Navigator.pop(context),
            child: const Text('Sign in', style: TextStyle(color: Color(0xFFD97706),
                fontWeight: FontWeight.w700, fontSize: 13))),
      ])),
    ]);
  }

  Widget _otpStep({Key? key}) {
    return Column(key: key, crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => setState(() { _otpSent = false; for (final c in _otpCtrls) c.clear(); }),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border)),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: _grey, size: 14)),
          const SizedBox(width: 8),
          Text('Edit details', style: TextStyle(color: _grey, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 24),
      Text('Verify your email 📬', style: TextStyle(color: _navy, fontSize: 26,
          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      RichText(text: TextSpan(style: TextStyle(color: _grey, fontSize: 13, height: 1.5), children: [
        const TextSpan(text: 'We sent a 6-digit code to\n'),
        TextSpan(text: _emailCtrl.text, style: TextStyle(color: _navy, fontWeight: FontWeight.w600)),
      ])),
      const SizedBox(height: 28),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _label('6-digit code'),
        _resendTimer > 0
            ? Text('Resend in ${_resendTimer}s', style: TextStyle(color: _grey, fontSize: 12))
            : GestureDetector(onTap: _sendOtp,
            child: const Text('Resend OTP', style: TextStyle(color: Color(0xFFD97706),
                fontWeight: FontWeight.w600, fontSize: 12))),
      ]),
      const SizedBox(height: 10),
      Row(children: List.generate(6, (i) {
        final filled = _otpCtrls[i].text.isNotEmpty;
        return Expanded(child: Container(
          height: 54,
          margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
          decoration: BoxDecoration(
            color: filled ? const Color(0xFFFFFBE6) : _greyLt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: filled ? _yellowDk : _border, width: filled ? 2 : 1),
          ),
          child: TextField(
            controller: _otpCtrls[i], focusNode: _otpFocus[i],
            textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
            style: TextStyle(color: _navy, fontSize: 22, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(counterText: '', border: InputBorder.none, contentPadding: EdgeInsets.zero),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              setState(() {});
              if (val.isNotEmpty && i < 5) _otpFocus[i + 1].requestFocus();
              if (val.isEmpty && i > 0) _otpFocus[i - 1].requestFocus();
              if (_otpCtrls.every((c) => c.text.isNotEmpty)) _verifyOtp();
            },
          ),
        ));
      })),
      const SizedBox(height: 24),
      _btn(label: 'Verify & Create Account', icon: Icons.verified_rounded, onTap: _verifyOtp, loading: _loading),
    ]);
  }

  Widget _label(String t) => Text(t, style: TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _input({required TextEditingController controller, required String hint,
      required IconData icon, TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(color: _greyLt, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border)),
      child: TextField(
        controller: controller, keyboardType: type,
        style: TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: _grey.withOpacity(0.7), fontSize: 14),
          prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(icon, color: _grey, size: 18)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _btn({required String label, required IconData icon,
      required VoidCallback onTap, required bool loading}) {
    return SizedBox(width: double.infinity, height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: _yellow, foregroundColor: _navy,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Color(0xFF1A1F36), strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 18), const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
      ),
    );
  }
}