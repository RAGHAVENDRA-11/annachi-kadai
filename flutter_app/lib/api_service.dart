import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // ── Change this to your PC's current WiFi IP ──
  static const String _pcIp = '172.16.49.120';

  static String get baseUrl {
    if (Platform.isAndroid || Platform.isIOS) return 'http://$_pcIp:8000/api';
    return 'http://127.0.0.1:8000/api'; // Windows / desktop
  }

  static Future<List> getProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products/'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<Map> placeOrder(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/place'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> loginCustomer(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/login'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> registerCustomer(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return jsonDecode(res.body);
  }

  static Future<List> getOrders(int customerId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/orders/customer/$customerId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<Map> loginSendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/login/send-otp'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Error');
    return data;
  }

  static Future<Map> loginVerifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/login/verify-otp'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Error');
    return data;
  }

  static Future<Map> registerSendOtp(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register/send-otp'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(body['detail'] ?? 'Error');
    return body;
  }

  static Future<Map> registerVerifyOtp(String email, String otp, String name, String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register/verify-otp'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'email': email, 'otp': otp, 'name': name, 'phone': phone}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Error');
    return data;
  }


  static Future<Map> validateAddress(String address) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/validate-address'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'address': address}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Validation failed');
    return data;
  }

  static Future<Map> validateCoordinates(double lat, double lng) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/validate-coordinates'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Validation failed');
    return data;
  }

  static Future<Map> placeOrderWithBill(Map orderData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/place-with-bill'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode(orderData),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Order failed');
    return data;
  }

  static Future<Map> processVoiceOrder(String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/voice-order'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'text': text}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Failed');
    return data;
  }

  static Future<Map> getMembership(String customerId) async {
    try {
      final url = Uri.parse(baseUrl + '/customers/membership/' + customerId);
      final res = await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'});
      print('[getMembership] status: ' + res.statusCode.toString() + ' body: ' + res.body);
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print('[getMembership] error: ' + e.toString());
    }
    return {'membership_type': '', 'membership_card': '', 'membership_valid_until': ''};
  }

  static Future<Map> purchaseMembership({
    required String customerId,
    required String type,
    required String cardNumber,
    required String validUntil,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/membership/purchase'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'customer_id': customerId, 'type': type,
          'card_number': cardNumber, 'valid_until': validUntil}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Failed');
    return data;
  }

  static Future<Map> updateProfile({
    required String customerId,
    required String name,
    required String phone,
    required String address,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/customers/$customerId'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'name': name, 'phone': phone, 'address': address}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Failed');
    return data;
  }

  static Future<Map> chatWithBot({
    required String message,
    required List<Map<String, String>> history,
    required String customerId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'message': message, 'history': history, 'customer_id': customerId}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Chat failed');
    return data;
  }


  static Future<List> getActiveDeliveryOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/delivery/active'),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );
    if (res.statusCode != 200) throw Exception('Failed');
    return jsonDecode(res.body);
  }

  static Future<List> getDeliveryHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/delivery/history'),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );
    if (res.statusCode != 200) throw Exception('Failed');
    return jsonDecode(res.body);
  }

  static Future<Map> updateOrderStatus(int orderId, String status) async {
    final res = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(res.body);
  }

  // ── DELIVERY PARTNER ──
  static Future<Map> deliveryPartnerLogin(String phone, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/delivery-partners/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Login failed');
    return data;
  }

  static Future<Map> deliveryPartnerRegister(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/delivery-partners/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final d = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(d['detail'] ?? 'Registration failed');
    return d;
  }

  static Future<Map> deliveryPartnerChangePassword(int partnerId, String oldPw, String newPw) async {
    final res = await http.put(
      Uri.parse('$baseUrl/delivery-partners/$partnerId/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'old_password': oldPw, 'new_password': newPw}),
    );
    final d = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(d['detail'] ?? 'Failed');
    return d;
  }

  static Future<List> getTodayOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/orders/delivery/active'));
    if (res.statusCode != 200) throw Exception('Failed');
    final all = List.from(jsonDecode(res.body));
    // Filter today only
    final today = DateTime.now();
    return all.where((o) {
      try {
        final dt = DateTime.parse(o['created_at']);
        return dt.year == today.year && dt.month == today.month && dt.day == today.day;
      } catch (_) { return true; }
    }).toList();
  }
}