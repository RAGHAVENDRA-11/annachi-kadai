import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

const String regBaseUrl = 'http://localhost:8000/api';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _loading = false;
  String _message = '';
  bool _isError = false;

  Future<void> register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      setState(() {
        _message = 'Please fill name, email and phone';
        _isError = true;
      });
      return;
    }

    if (_phoneController.text.trim().length != 10) {
      setState(() {
        _message = 'Phone number must be 10 digits';
        _isError = true;
      });
      return;
    }

    setState(() { _loading = true; _message = ''; });

    final res = await http.post(
      Uri.parse('$regBaseUrl/customers/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': 0.0,
        'longitude': 0.0,
      }),
    );

    final data = jsonDecode(res.body);
    setState(() { _loading = false; });

    if (res.statusCode == 200) {
      setState(() {
        _message = '✅ Registered successfully! Please login.';
        _isError = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } else {
      setState(() {
        _message = data['detail'] ?? 'Registration failed. Try again.';
        _isError = true;
      });
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
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.store_mall_directory_rounded,
                      color: Colors.white, size: 60),
                ),
                const SizedBox(height: 24),
                const Text('Join Annachi Kadai',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Create your account and start ordering fresh groceries from your neighborhood store.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white54, fontSize: 14, height: 1.7),
                  ),
                ),
                const SizedBox(height: 48),
                _featureRow(Icons.flash_on_rounded, '10-minute delivery'),
                const SizedBox(height: 14),
                _featureRow(Icons.mic_rounded, 'Voice ordering in Tamil'),
                const SizedBox(height: 14),
                _featureRow(Icons.auto_awesome_rounded, 'AI recommendations'),
                const SizedBox(height: 14),
                _featureRow(Icons.lock_outline_rounded, 'Secure OTP login'),
              ],
            ),
          ),

          // Right Panel
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Account',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 6),
                      const Text('Fill in your details to get started',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 32),

                      _buildLabel('Full Name *'),
                      const SizedBox(height: 8),
                      _buildField(_nameController, 'Enter your full name',
                          Icons.person_outline),
                      const SizedBox(height: 18),

                      _buildLabel('Email Address *'),
                      const SizedBox(height: 8),
                      _buildField(_emailController, 'Enter your email',
                          Icons.email_outlined,
                          type: TextInputType.emailAddress),
                      const SizedBox(height: 18),

                      _buildLabel('Phone Number *'),
                      const SizedBox(height: 8),
                      _buildField(_phoneController, '10-digit mobile number',
                          Icons.phone_outlined,
                          type: TextInputType.phone, maxLen: 10),
                      const SizedBox(height: 18),

                      _buildLabel('Delivery Address'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: _inputDec('Enter your delivery address',
                            Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 24),

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
                                color:
                                    _isError ? Colors.red : Colors.green,
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
                          onPressed: _loading ? null : register,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen())),
                            child: const Text('Login',
                                style: TextStyle(
                                    color: Color(0xFFFF6B00),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1A1A2E)));

  Widget _buildField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType type = TextInputType.text, int? maxLen}) =>
      TextField(
        controller: controller,
        keyboardType: type,
        maxLength: maxLen,
        decoration: _inputDec(hint, icon),
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
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
        counterText: '',
      );

  Widget _featureRow(IconData icon, String text) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFFFF6B00), size: 16),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      );
}