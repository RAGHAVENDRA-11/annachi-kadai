import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Annachi Kadai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthWrapper(),
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<Map> _items = [];
  List<Map> get items => _items;

  int get totalItems =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));
  double get totalPrice => _items.fold(
      0.0,
      (sum, item) =>
          sum + (item['price'] as double) * (item['quantity'] as int));

  void addItem(Map product) {
    final index = _items.indexWhere((i) => i['id'] == product['id']);
    if (index >= 0) {
      _items[index]['quantity'] = (_items[index]['quantity'] as int) + 1;
    } else {
      _items.add({...product, 'quantity': 1});
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    final index = _items.indexWhere((i) => i['id'] == productId);
    if (index != -1) {
      if ((_items[index]['quantity'] as int) > 1) {
        _items[index]['quantity'] = (_items[index]['quantity'] as int) - 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  int getQuantity(int productId) {
    final index = _items.indexWhere((i) => i['id'] == productId);
    if (index == -1) return 0;
    return _items[index]['quantity'] as int;
  }

  void deleteItem(int productId) {
    _items.removeWhere((i) => i['id'] == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('customer_email');
    setState(() {
      _loggedIn = email != null && email.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFF6B00),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text('Annachi Kadai',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    return _loggedIn ? const HomeScreen() : const LoginScreen();
  }
}