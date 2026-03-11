// lib/services/subscription_service.dart
// Developed by Sir Enocks — Cor Technologies

import '../models/user_model.dart';

class SubscriptionService {
  // ── Trial ─────────────────────────────────────────────
  static const int trialDays = 14;

  // ── Base plan ($2.99 one-time) ────────────────────────
  // Unlocks 15 core modules forever
  static const double basePriceUsd = 2.99;

  // ── Premium plan ($1.99 / 60 days) ───────────────────
  // Unlocks all premium/AI/advanced modules
  static const double premiumPriceUsd = 1.99;
  static const int premiumDurationDays = 60;

  // ── TRIAL ─────────────────────────────────────────────

  static bool isTrialActive(UserModel user) {
    if (user.isSubscribed) return true;
    final expiry =
        user.registeredAt.add(const Duration(days: trialDays));
    return DateTime.now().isBefore(expiry);
  }

  static int trialDaysRemaining(UserModel user) {
    if (user.isSubscribed) return 999;
    final expiry =
        user.registeredAt.add(const Duration(days: trialDays));
    final remaining = expiry.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  // ── BASE ACCESS (core 15 modules) ────────────────────

  // Has base access = subscribed OR trial still active
  static bool hasAccess(UserModel user) {
    return user.isSubscribed || isTrialActive(user);
  }

  // Soft-locked from core modules = trial expired AND not base-subscribed
  static bool isSoftLocked(UserModel user) {
    return !user.isSubscribed && !isTrialActive(user);
  }

  // ── PREMIUM ACCESS (AI + advanced modules) ───────────

  // Has premium access = premium subscribed AND not expired
  // During trial, premium is also accessible for free
  static bool hasPremiumAccess(UserModel user) {
    if (isTrialActive(user)) return true; // free during trial
    return user.hasPremiumAccess;
  }

  // Is premium locked = base subscribed but premium expired/never subscribed
  static bool isPremiumLocked(UserModel user) {
    if (isTrialActive(user)) return false;
    return !user.hasPremiumAccess;
  }

  // Days until premium expires
  static int premiumDaysRemaining(UserModel user) {
    if (isTrialActive(user)) return trialDaysRemaining(user);
    return user.premiumDaysRemaining;
  }
}