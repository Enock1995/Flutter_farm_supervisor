// lib/config/app_config.example.dart
// ✅  THIS FILE IS SAFE TO COMMIT — it contains no real credentials
// Copy this file to app_config.dart and fill in your real values
// Developed by Sir Enocks — Cor Technologies

class AppConfig {
  // ── Paynow Zimbabwe Credentials ───────────────────────
  // Get these from your Paynow merchant dashboard
  static const String paynowIntegrationId  = 'YOUR_PAYNOW_INTEGRATION_ID';
  static const String paynowIntegrationKey = 'YOUR_PAYNOW_INTEGRATION_KEY';

  // ── Paynow URLs ───────────────────────────────────────
  static const String paynowResultUrl = 'https://yourdomain.com/payment/result';
  static const String paynowReturnUrl = 'https://yourdomain.com/payment/return';

  // ── Subscription Price ────────────────────────────────
  static const double subscriptionAmountUSD = 2.99;

  // ── App Environment ───────────────────────────────────
  static const bool isProduction = false;
}