import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://127.0.0.1:8000/api';
// Use 10.0.2.2 for Android emulator
// Use your PC IP like 192.168.1.x:8000 for real device

class ApiService {
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

  static Future<Map> registerCustomer(Map data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/customers/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }
}