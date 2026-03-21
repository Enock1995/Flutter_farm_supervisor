// lib/widgets/role_guard.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';

/// Inline widget that shows [child] only when the role condition is met.
/// Defaults to SizedBox.shrink() when condition fails (no UI shown).
///
/// Usage examples:
///   RoleGuard.mudhumeni(child: FloatingActionButton(...))
///   RoleGuard.admin(child: ElevatedButton(...))
///   RoleGuard(allowed: (auth) => auth.canResolveProblem, child: ...)
class RoleGuard extends StatelessWidget {
  final bool Function(AuthProvider auth) allowed;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowed,
    required this.child,
    this.fallback,
  });

  /// Show only to mudhumeni + admin.
  factory RoleGuard.mudhumeni({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) =>
      RoleGuard(
        key: key,
        allowed: (auth) => auth.isMudhumeni || auth.isAdmin,
        child: child,
        fallback: fallback,
      );

  /// Show only to admin.
  factory RoleGuard.admin({
    Key? key,
    required Widget child,
    Widget? fallback,
  }) =>
      RoleGuard(
        key: key,
        allowed: (auth) => auth.isAdmin,
        child: child,
        fallback: fallback,
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return allowed(auth) ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Badge shown next to Mudhumeni names in Q&A answers and community posts.
class MudhuneniBadge extends StatelessWidget {
  final bool show;
  const MudhuneniBadge({super.key, this.show = true});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF558B2F),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 10, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'Mudhumeni',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}