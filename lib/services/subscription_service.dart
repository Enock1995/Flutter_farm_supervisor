// lib/services/subscription_service.dart
// Developed by Sir Enocks — Cor Technologies

import '../models/user_model.dart';

class SubscriptionService {
  static const int trialDays = 14;
  static const double priceGbp = 2.50;

  // Check if trial is still active
  static bool isTrialActive(UserModel user) {
    if (user.isSubscribed) return true;
    final expiry =
        user.registeredAt.add(const Duration(days: trialDays));
    return DateTime.now().isBefore(expiry);
  }

  // Days remaining in trial (0 if expired)
  static int trialDaysRemaining(UserModel user) {
    if (user.isSubscribed) return 999;
    final expiry =
        user.registeredAt.add(const Duration(days: trialDays));
    final remaining = expiry.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  // Has access = subscribed OR trial still active
  static bool hasAccess(UserModel user) {
    return user.isSubscribed || isTrialActive(user);
  }

  // Is soft-locked = trial expired AND not subscribed
  static bool isSoftLocked(UserModel user) {
    return !user.isSubscribed && !isTrialActive(user);
  }
}