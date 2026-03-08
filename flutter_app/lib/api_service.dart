import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Windows desktop: 127.0.0.1 | Android emulator: 10.0.2.2 | Real device: 172.16.202.186
  static const String baseUrl = 'http://127.0.0.1:8000/api';

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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> loginCustomer(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> registerCustomer(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Error');
    return data;
  }

  static Future<Map> loginVerifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/login/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Error');
    return data;
  }

  static Future<Map> registerSendOtp(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(body['detail'] ?? 'Error');
    return body;
  }

  static Future<Map> registerVerifyOtp(String email, String otp, String name, String phone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'name': name, 'phone': phone}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Error');
    return data;
  }


  static Future<Map> validateAddress(String address) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/validate-address'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'address': address}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Validation failed');
    return data;
  }

  static Future<Map> validateCoordinates(double lat, double lng) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/validate-coordinates'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Validation failed');
    return data;
  }

  static Future<Map> placeOrderWithBill(Map orderData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/place-with-bill'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200) throw Exception(data['detail'] ?? 'Order failed');
    return data;
  }

}