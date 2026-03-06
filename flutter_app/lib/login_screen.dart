import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';

const String baseUrl = 'http://localhost:8000/api';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String _message = '';
  bool _isError = false;

  Future<void> sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() { _message = 'Please enter your email'; _isError = true; });
      return;
    }
    setState(() { _loading = true; _message = ''; });
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _emailController.text.trim()}),
    );
    final data = jsonDecode(res.body);
    setState(() {
      _loading = false;
      _otpSent = data['success'];
      _message = data['message'];
      _isError = !data['success'];
    });
  }

  Future<void> verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() { _message = 'Please enter the OTP'; _isError = true; });
      return;
    }
    setState(() { _loading = true; _message = ''; });
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'otp': _otpController.text.trim(),
      }),
    );
    final data = jsonDecode(res.body);
    setState(() { _loading = false; _message = data['message']; _isError = !data['success']; });

    if (data['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_email', data['customer']['email'] ?? '');
      await prefs.setInt('customer_id', data['customer']['id']);
      await prefs.setString('customer_name', data['customer']['name'] ?? '');
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Panel
          Container(
            width: 420,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B00), Color(0xFFFF9A3C)],
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_mall_directory_rounded,
                    color: Colors.white, size: 80),
                SizedBox(height: 20),
                Text('Annachi Kadai',
                    style: TextStyle(color: Colors.white,
                        fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Your neighborhood grocery store,\nnow at your fingertips.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                  ),
                ),
                SizedBox(height: 40),
                _FeatureRow(icon: Icons.flash_on, text: '10-minute delivery'),
                SizedBox(height: 12),
                _FeatureRow(icon: Icons.mic, text: 'Voice ordering in Tamil'),
                SizedBox(height: 12),
                _FeatureRow(icon: Icons.auto_awesome, text: 'AI-powered recommendations'),
              ],
            ),
          ),

          // Right Panel
          Expanded(
            child: Center(
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back 👋',
                        style: TextStyle(fontSize: 28,
                            fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent
                          ? 'Enter the OTP sent to your email'
                          : 'Sign in to continue shopping',
                      style: const TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const SizedBox(height: 36),

                    // Email
                    _buildLabel('Email Address'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      enabled: !_otpSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                          'Enter your email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 20),

                    if (_otpSent) ...[
                      _buildLabel('OTP Code'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold),
                        decoration: _inputDecoration(
                            '• • • • • •', Icons.lock_outline),
                      ),
                      Row(
                        children: [
                          const Text('Didn\'t receive? ',
                              style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _message = '';
                            }),
                            child: const Text('Resend OTP',
                                style: TextStyle(
                                    color: Color(0xFFFF6B00),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_message.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _isError
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _isError
                                  ? Colors.red.shade200
                                  : Colors.green.shade200),
                        ),
                        child: Row(children: [
                          Icon(
                              _isError
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: _isError ? Colors.red : Colors.green,
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_message,
                                  style: TextStyle(
                                      color: _isError
                                          ? Colors.red.shade700
                                          : Colors.green.shade700))),
                        ]),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _loading
                            ? null
                            : (_otpSent ? verifyOtp : sendOtp),
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _otpSent ? 'Verify & Login' : 'Send OTP',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ]),

                    const SizedBox(height: 20),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New customer? ',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          child: const Text('Create Account',
                              style: TextStyle(
                                  color: Color(0xFFFF6B00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600,
          fontSize: 14, color: Color(0xFF1A1A2E)));

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B00), size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFF6B00), width: 2)),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}