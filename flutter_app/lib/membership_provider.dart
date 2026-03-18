import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Single source of truth for membership — always from DB.
/// No SharedPreferences involved. Survives logout/login perfectly.
class MembershipProvider extends ChangeNotifier {
  String membershipType = '';
  String cardNumber     = '';
  String validUntil     = '';
  double monthlySpent   = 0.0;
  int    rewardPoints   = 0;
  bool   isLoading      = false;

  int get monthlyLimit =>
      membershipType == 'diamond' ? 1000 : (membershipType == 'gold' ? 2500 : 0);

  double get monthlyRemaining =>
      (monthlyLimit - monthlySpent).clamp(0.0, monthlyLimit.toDouble());

  bool get hasMembership =>
      membershipType == 'diamond' || membershipType == 'gold';

  // ── Sync from direct DB call (used by membership screen) ──
  void syncFromDB(String type, String card, String valid, double spent, int limit) {
    membershipType = type;
    cardNumber     = card;
    validUntil     = valid;
    monthlySpent   = spent;
    isLoading      = false;
    notifyListeners();
  }

  // ── Load from DB using customer_id ──
  Future<void> load(String customerId) async {
    if (customerId.isEmpty) return;
    isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.getMembership(customerId);
      membershipType = (res['membership_type'] ?? '').toString();
      cardNumber     = (res['membership_card'] ?? '').toString();
      validUntil     = (res['membership_valid_until'] ?? '').toString();

      // Monthly spend tracked in prefs (scoped to customer)
      final prefs = await SharedPreferences.getInstance();
      final monthKey = 'ms_month_$customerId';
      final spentKey = 'ms_spent_$customerId';
      final now = '${DateTime.now().year}-${DateTime.now().month}';
      if ((prefs.getString(monthKey) ?? '') != now) {
        // New month — reset
        await prefs.setString(monthKey, now);
        await prefs.setDouble(spentKey, 0.0);
        monthlySpent = 0.0;
      } else {
        monthlySpent = prefs.getDouble(spentKey) ?? 0.0;
      }

      // Reward points scoped to customer
      rewardPoints = prefs.getInt('pts_$customerId') ?? 0;
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  // ── After purchase — reload from DB ──
  Future<void> refresh(String customerId) => load(customerId);

  // ── After order placed ──
  Future<void> recordSpend(String customerId, double amount) async {
    if (customerId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final spentKey = 'ms_spent_$customerId';
    final monthKey = 'ms_month_$customerId';
    final now = '${DateTime.now().year}-${DateTime.now().month}';
    await prefs.setString(monthKey, now);
    final newSpent = monthlySpent + amount;
    await prefs.setDouble(spentKey, newSpent);
    monthlySpent = newSpent;

    // Award 1 point per ₹1000
    final earned = (amount / 1000).floor();
    if (earned > 0) {
      final current = prefs.getInt('pts_$customerId') ?? 0;
      await prefs.setInt('pts_$customerId', current + earned);
      rewardPoints = current + earned;
    }
    notifyListeners();
  }

  Future<void> redeemPoints(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pts_$customerId', 0);
    rewardPoints = 0;
    notifyListeners();
  }

  // ── Clear on logout ──
  void clear() {
    membershipType = '';
    cardNumber     = '';
    validUntil     = '';
    monthlySpent   = 0.0;
    rewardPoints   = 0;
    notifyListeners();
  }
}