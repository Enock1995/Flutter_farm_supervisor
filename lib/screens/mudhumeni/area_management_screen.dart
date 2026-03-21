// lib/screens/mudhumeni/area_management_screen.dart
// Developed by Sir Enocks — Cor Technologies
// Mudhumeni: view-only list of farmers in their ward
// Admin: full hierarchy view of their jurisdiction

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';

const _green = Color(0xFF558B2F);

class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() =>
      _AreaManagementScreenState();
}

class _AreaManagementScreenState
    extends State<AreaManagementScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';

  late UserModel _me;

  @override
  void initState() {
    super.initState();
    _me = context.read<AuthProvider>().user!;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users =
        await DatabaseService().getUsersUnderAuthority(_me);
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  List<UserModel> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.phone.contains(q) ||
            u.ward.toLowerCase().contains(q) ||
            u.district.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_me.isMudhumeni ? 'My Ward Farmers' : 'Area Management',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _me.isMudhumeni
                  ? 'Ward: ${_me.ward}'
                  : _me.isDistrictAdmin
                      ? 'District: ${_me.district}'
                      : _me.isProvincialAdmin
                          ? 'Province: ${_me.province}'
                          : 'All Zimbabwe',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: 'Refresh'),
        ],
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            color: _green,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                _TopStat(
                    emoji: '👨‍🌾',
                    label: 'Farmers',
                    value: '${_users.where((u) => u.isFarmer).length}'),
                if (!_me.isMudhumeni) ...[
                  _TopStat(
                      emoji: '🌿',
                      label: 'Mudhumeni',
                      value:
                          '${_users.where((u) => u.isMudhumeni).length}'),
                  _TopStat(
                      emoji: '👥',
                      label: 'Total',
                      value: '${_users.length}'),
                ],
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, ward...',
                prefixIcon:
                    const Icon(Icons.search, color: _green),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _green))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline,
                                size: 64,
                                color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              _search.isNotEmpty
                                  ? 'No results for "$_search"'
                                  : _me.isMudhumeni
                                      ? 'No farmers in your ward yet'
                                      : 'No users in your area yet',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            if (_me.isMudhumeni && _search.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Farmers join your ward when they set '
                                  '"${_me.ward}" as their ward in the '
                                  'Mudhumeni Network section.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textHint),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              12, 0, 12, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _UserCard(user: _filtered[i], me: _me),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final UserModel me;
  const _UserCard({required this.user, required this.me});

  @override
  Widget build(BuildContext context) {
    final color = user.isFarmer
        ? const Color(0xFF4E342E)
        : user.isMudhumeni
            ? _green
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(user.phone,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${user.roleEmoji} ${user.roleLabel}',
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (user.ward.isNotEmpty)
                  _InfoChip(
                      Icons.location_on_outlined, user.ward),
                _InfoChip(Icons.map_outlined, user.district),
                _InfoChip(Icons.terrain_outlined, user.province),
                if (user.agroRegion.isNotEmpty)
                  _InfoChip(Icons.eco_outlined,
                      'Region ${user.agroRegion}'),
              ],
            ),
            // Mudhumeni: read-only, no action buttons
            // Admin: no delete from this screen (use admin panel)
            if (me.isMudhumeni) ...[
              const SizedBox(height: 8),
              Text(
                '👁️ View only — use Admin Panel to manage users',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _TopStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _TopStat(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}