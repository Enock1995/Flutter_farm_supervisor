// lib/screens/debug/debug_screen.dart
// TEMPORARY — DELETE BEFORE RELEASE
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('🔧 Debug — DELETE BEFORE RELEASE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('USER MODEL VALUES', [
              _row('user is null?', user == null ? '⛔ YES — not logged in' : '✅ NO'),
              if (user != null) ...[
                _row('user.phone', '"${user.phone}"'),
                _row('user.userId', '"${user.userId}"'),
                _row('user.role', '"${user.role}"'),
                _row('user.isSubscribed', '${user.isSubscribed}'),
                _row('user.isPremiumSubscribed', '${user.isPremiumSubscribed}'),
                _row('user.hasPremiumAccess', '${user.hasPremiumAccess}'),
              ],
            ]),

            const SizedBox(height: 20),

            _section('APP CONFIG VALUES', [
              _row('adminPhoneNumber', '"${AppConfig.adminPhoneNumber}"'),
            ]),

            const SizedBox(height: 20),

            if (user != null) _section('PHONE COMPARISON', [
              _row('user.phone == adminPhoneNumber',
                  user.phone == AppConfig.adminPhoneNumber
                      ? '✅ MATCH — phone fallback should work'
                      : '⛔ NO MATCH — this is likely your problem'),
              _row('Characters in user.phone', '${user.phone.length}'),
              _row('Characters in adminPhoneNumber', '${AppConfig.adminPhoneNumber.length}'),
            ]),

            const SizedBox(height: 20),

            _section('AUTH PROVIDER ROLE CHECKS', [
              _row('auth.isFarmer', '${auth.isFarmer}'),
              _row('auth.isMudhumeni', '${auth.isMudhumeni}'),
              _row('auth.isAdmin', auth.isAdmin ? '✅ TRUE' : '⛔ FALSE'),
              _row('auth.canAccessAdminPanel', '${auth.canAccessAdminPanel}'),
            ]),

            const SizedBox(height: 20),

            // Fix button — sets role to admin directly in DB
            _section('ONE-TAP FIX', []),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: user == null
                    ? null
                    : () async {
                        await context
                            .read<AuthProvider>()
                            .updateUserRole(user.userId, 'admin');
                        await context.read<AuthProvider>().refreshUser();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '✅ Role set to admin! Go back to dashboard.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('SET MY ROLE TO ADMIN NOW',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: user == null
                    ? null
                    : () async {
                        await context.read<AuthProvider>().refreshUser();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔄 User refreshed from DB.'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('REFRESH USER FROM DB'),
              ),
            ),

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: const Text(
                '⚠️ DELETE this file and its route from main.dart before release.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
        ...rows,
      ],
    );
  }

  Widget _row(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}