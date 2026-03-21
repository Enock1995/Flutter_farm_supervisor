// lib/screens/admin/admin_panel_screen.dart
// Developed by Sir Enocks — Cor Technologies
// Hierarchy: national_admin → provincial_admin → district_admin → mudhumeni → farmer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/mudhumeni_database_service.dart';
import '../../services/database_service.dart';
import '../../models/mudhumeni_model.dart';
import '../../models/user_model.dart';
import '../../config/app_config.dart';

// Role colours
const _kNational   = Color(0xFF1B5E20);
const _kProvincial = Color(0xFF1565C0);
const _kDistrict   = Color(0xFF6A1B9A);
const _kMudhumeni  = Color(0xFF558B2F);
const _kFarmer     = Color(0xFF4E342E);

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Data
  List<MudhumeniProfile> _pendingMudhumeni = [];
  List<UserModel> _managedUsers = [];
  bool _loading = true;

  late UserModel _me;

  @override
  void initState() {
    super.initState();
    _me = context.read<AuthProvider>().user!;
    // Tab count depends on role
    _tabs = TabController(length: _tabCount, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int get _tabCount {
    if (_me.isNationalAdmin) return 4; // Pending | Authorities | All Users | Appoint
    if (_me.isProvincialAdmin) return 3; // Pending | District Admins | Mudhumeni
    return 2; // Pending | Mudhumeni
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load pending mudhumeni registrations (filtered by area)
      final all = await MudhumeniDatabaseService.getAllMudhumeniProfiles();
      final pending = all.where((p) {
        if (p.status != 'pending') return false;
        if (_me.isNationalAdmin) return true;
        if (_me.isProvincialAdmin) return p.district.isNotEmpty;
        if (_me.isDistrictAdmin) return p.district == _me.district;
        return false;
      }).toList();

      // Load users under this authority's jurisdiction
      final users = await DatabaseService().getUsersUnderAuthority(_me);

      setState(() {
        _pendingMudhumeni = pending;
        _managedUsers = users;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    final views = _buildViews();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Panel',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_me.roleLabel,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: _tabCount > 3,
          tabs: tabs,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: views),
    );
  }

  List<Widget> _buildTabs() {
    final pendingCount = _pendingMudhumeni.length;
    if (_me.isNationalAdmin) {
      return [
        Tab(text: 'Pending ($pendingCount)'),
        const Tab(text: 'Authorities'),
        const Tab(text: 'All Users'),
        const Tab(text: '+ Appoint'),
      ];
    }
    if (_me.isProvincialAdmin) {
      return [
        Tab(text: 'Pending ($pendingCount)'),
        const Tab(text: 'District Admins'),
        const Tab(text: 'Mudhumeni'),
      ];
    }
    // district_admin
    return [
      Tab(text: 'Pending ($pendingCount)'),
      const Tab(text: 'Mudhumeni'),
    ];
  }

  List<Widget> _buildViews() {
    if (_me.isNationalAdmin) {
      return [
        _PendingTab(profiles: _pendingMudhumeni, me: _me, onAction: _load),
        _AuthoritiesTab(users: _managedUsers, me: _me, onAction: _load),
        _AllUsersTab(users: _managedUsers, me: _me, onAction: _load),
        _AppointTab(me: _me, onAppointed: _load),
      ];
    }
    if (_me.isProvincialAdmin) {
      final districtAdmins = _managedUsers
          .where((u) => u.isDistrictAdmin)
          .toList();
      final mudhumeni = _managedUsers
          .where((u) => u.isMudhumeni)
          .toList();
      return [
        _PendingTab(profiles: _pendingMudhumeni, me: _me, onAction: _load),
        _UserListTab(
          users: districtAdmins,
          label: 'District Admins',
          color: _kDistrict,
          me: _me,
          onAction: _load,
        ),
        _UserListTab(
          users: mudhumeni,
          label: 'Mudhumeni Officers',
          color: _kMudhumeni,
          me: _me,
          onAction: _load,
        ),
      ];
    }
    // district_admin
    final mudhumeni = _managedUsers.where((u) => u.isMudhumeni).toList();
    return [
      _PendingTab(profiles: _pendingMudhumeni, me: _me, onAction: _load),
      _UserListTab(
        users: mudhumeni,
        label: 'Mudhumeni Officers',
        color: _kMudhumeni,
        me: _me,
        onAction: _load,
      ),
    ];
  }
}

// =============================================================================
// PENDING TAB — Mudhumeni applications awaiting approval
// =============================================================================
class _PendingTab extends StatelessWidget {
  final List<MudhumeniProfile> profiles;
  final UserModel me;
  final VoidCallback onAction;
  const _PendingTab(
      {required this.profiles, required this.me, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return _empty(Icons.inbox_outlined, 'No pending applications',
          'New Mudhumeni registrations will appear here.');
    }
    return RefreshIndicator(
      onRefresh: () async => onAction(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        itemBuilder: (_, i) => _PendingCard(
          profile: profiles[i],
          me: me,
          onAction: onAction,
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final MudhumeniProfile profile;
  final UserModel me;
  final VoidCallback onAction;
  const _PendingCard(
      {required this.profile, required this.me, required this.onAction});

  Future<void> _approve(BuildContext context) async {
    final confirmed = await _confirm(context, 'Approve Mudhumeni',
        'Approve ${profile.fullName} as a verified extension officer?',
        confirmLabel: 'Approve', confirmColor: AppColors.success);
    if (!confirmed || !context.mounted) return;

    await MudhumeniDatabaseService.updateProfileStatus(
        profile.id!, 'verified');
    await context
        .read<AuthProvider>()
        .updateUserRole(profile.userId, 'mudhumeni');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${profile.fullName} approved ✅'),
          backgroundColor: AppColors.success));
    }
    onAction();
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await _reasonDialog(context, 'Reject Application',
        '${profile.fullName}\'s Mudhumeni application');
    if (reason == null || !context.mounted) return;

    await MudhumeniDatabaseService.updateProfileStatus(
        profile.id!, 'rejected');
    // Send notification
    await _sendNotification(
      context,
      targetUserId: profile.userId,
      title: 'Mudhumeni Application Rejected',
      message:
          'Your Mudhumeni extension officer application has been rejected.',
      reason: reason,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${profile.fullName}\'s application rejected'),
          backgroundColor: AppColors.error));
    }
    onAction();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _kMudhumeni.withOpacity(0.15),
                  child: const Icon(Icons.person, color: _kMudhumeni),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.bold)),
                      Text('ID: ${profile.userId}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textHint)),
                    ],
                  ),
                ),
                _StatusChip('Pending', AppColors.warning),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),
            _infoRow(Icons.badge_outlined, 'Employee ID', profile.employeeId),
            _infoRow(Icons.location_on_outlined, 'Ward', profile.ward),
            _infoRow(Icons.map_outlined, 'District', profile.district),
            _infoRow(Icons.terrain_outlined, 'District', profile.district),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error)),
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white),
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textHint),
            const SizedBox(width: 6),
            Text('$label: ',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            Expanded(
              child: Text(value,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

// =============================================================================
// AUTHORITIES TAB — national_admin sees all admin-level users
// =============================================================================
class _AuthoritiesTab extends StatelessWidget {
  final List<UserModel> users;
  final UserModel me;
  final VoidCallback onAction;
  const _AuthoritiesTab(
      {required this.users, required this.me, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final authorities = users
        .where((u) => u.isAdmin || u.isMudhumeni)
        .toList();

    if (authorities.isEmpty) {
      return _empty(Icons.supervisor_account_outlined,
          'No authorities appointed yet',
          'Use the Appoint tab to add Provincial or District admins.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: authorities.length,
      itemBuilder: (_, i) => _AuthorityCard(
        user: authorities[i],
        me: me,
        onAction: onAction,
      ),
    );
  }
}

class _AuthorityCard extends StatelessWidget {
  final UserModel user;
  final UserModel me;
  final VoidCallback onAction;
  const _AuthorityCard(
      {required this.user, required this.me, required this.onAction});

  Color get _roleColor {
    if (user.isNationalAdmin)   return _kNational;
    if (user.isProvincialAdmin) return _kProvincial;
    if (user.isDistrictAdmin)   return _kDistrict;
    if (user.isMudhumeni)       return _kMudhumeni;
    return _kFarmer;
  }

  @override
  Widget build(BuildContext context) {
    final canManage = me.canManageUser(user);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _roleColor.withOpacity(0.12),
              child: Text(user.roleEmoji,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '${user.roleLabel}  •  ${user.province}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  Text(user.district,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            if (canManage)
              _ActionMenu(user: user, me: me, onAction: onAction),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ALL USERS TAB — national_admin sees all farmers too
// =============================================================================
class _AllUsersTab extends StatelessWidget {
  final List<UserModel> users;
  final UserModel me;
  final VoidCallback onAction;
  const _AllUsersTab(
      {required this.users, required this.me, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final farmers = users.where((u) => u.isFarmer).toList();
    if (farmers.isEmpty) {
      return _empty(
          Icons.people_outline, 'No farmers found', 'Farmers will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: farmers.length,
      itemBuilder: (_, i) => _FarmerCard(
          user: farmers[i], me: me, onAction: onAction),
    );
  }
}

// =============================================================================
// USER LIST TAB — reusable filtered list for provincial/district admins
// =============================================================================
class _UserListTab extends StatelessWidget {
  final List<UserModel> users;
  final String label;
  final Color color;
  final UserModel me;
  final VoidCallback onAction;
  const _UserListTab({
    required this.users,
    required this.label,
    required this.color,
    required this.me,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _empty(Icons.people_outline, 'No $label found', '');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (_, i) => _AuthorityCard(
          user: users[i], me: me, onAction: onAction),
    );
  }
}

// =============================================================================
// APPOINT TAB — national_admin can appoint new authorities
// =============================================================================
class _AppointTab extends StatefulWidget {
  final UserModel me;
  final VoidCallback onAppointed;
  const _AppointTab({required this.me, required this.onAppointed});

  @override
  State<_AppointTab> createState() => _AppointTabState();
}

class _AppointTabState extends State<_AppointTab> {
  final _phoneCtrl = TextEditingController();
  String _targetRole = 'provincial_admin';
  UserModel? _foundUser;
  bool _searching = false;
  String? _searchError;

  static const _appointableRoles = [
    ('provincial_admin', '🏢 Provincial Admin'),
    ('district_admin',   '🏬 District Admin'),
    ('mudhumeni',        '🌿 Mudhumeni Officer'),
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _searching = true; _searchError = null; _foundUser = null; });
    final user = await DatabaseService().getUserByPhone(phone);
    setState(() {
      _searching = false;
      if (user == null) {
        _searchError = 'No user found with that phone number.';
      } else if (user.userId == widget.me.userId) {
        _searchError = 'You cannot appoint yourself.';
      } else {
        _foundUser = user;
      }
    });
  }

  Future<void> _appoint(BuildContext context) async {
    if (_foundUser == null) return;

    final confirmed = await _confirm(
      context,
      'Appoint ${_foundUser!.fullName}',
      'Appoint ${_foundUser!.fullName} as ${_roleLabel(_targetRole)}?',
      confirmLabel: 'Appoint',
      confirmColor: _kNational,
    );
    if (!confirmed || !context.mounted) return;

    await context
        .read<AuthProvider>()
        .updateUserRole(_foundUser!.userId, _targetRole);

    // Notify the appointed user
    await DatabaseService().insertRoleNotification(RoleNotification(
      id: 'rn_${DateTime.now().millisecondsSinceEpoch}',
      userId: _foundUser!.userId,
      title: 'You have been appointed!',
      message:
          'You have been appointed as ${_roleLabel(_targetRole)} '
          'by ${widget.me.fullName}.',
      reason: 'Authority appointment',
      fromRole: widget.me.normalizedRole,
      fromName: widget.me.fullName,
      createdAt: DateTime.now(),
    ));

    setState(() { _foundUser = null; _phoneCtrl.clear(); });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointed successfully ✅'),
          backgroundColor: AppColors.success));
    }
    widget.onAppointed();
  }

  String _roleLabel(String role) {
    return _appointableRoles
            .firstWhere((r) => r.$1 == role,
                orElse: () => (role, role))
            .$2;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kNational.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kNational.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Appoint existing users to authority roles. '
                    'Search by their registered phone number.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: _kNational),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Role selector
          Text('Role to Appoint', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          ..._appointableRoles.map((r) => RadioListTile<String>(
                value: r.$1,
                groupValue: _targetRole,
                title: Text(r.$2, style: AppTextStyles.body),
                activeColor: _kNational,
                onChanged: (v) => setState(() => _targetRole = v!),
              )),

          const SizedBox(height: 16),

          // Phone search
          Text('Find User by Phone', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g. 0771234567',
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: _kNational),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _searching ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNational,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Search'),
              ),
            ],
          ),

          if (_searchError != null) ...[
            const SizedBox(height: 10),
            Text(_searchError!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error)),
          ],

          if (_foundUser != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppColors.success.withOpacity(0.12),
                        child: Text(
                          _foundUser!.fullName.isNotEmpty
                              ? _foundUser!.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_foundUser!.fullName,
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Text(
                              '${_foundUser!.roleLabel}  •  ${_foundUser!.district}',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _appoint(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNational,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.how_to_reg_outlined),
                      label: Text(
                          'Appoint as ${_roleLabel(_targetRole)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// =============================================================================
// FARMER CARD — used in All Users tab
// =============================================================================
class _FarmerCard extends StatelessWidget {
  final UserModel user;
  final UserModel me;
  final VoidCallback onAction;
  const _FarmerCard(
      {required this.user, required this.me, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _kFarmer.withOpacity(0.10),
          child: const Text('👨‍🌾', style: TextStyle(fontSize: 18)),
        ),
        title: Text(user.fullName,
            style: AppTextStyles.body
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${user.district}  •  Ward: ${user.ward.isNotEmpty ? user.ward : '—'}',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
        ),
        trailing: me.canManageUser(user)
            ? _ActionMenu(user: user, me: me, onAction: onAction)
            : null,
      ),
    );
  }
}

// =============================================================================
// ACTION MENU — 3-dot menu for demote / delete with reason
// =============================================================================
class _ActionMenu extends StatelessWidget {
  final UserModel user;
  final UserModel me;
  final VoidCallback onAction;
  const _ActionMenu(
      {required this.user, required this.me, required this.onAction});

  Future<void> _demote(BuildContext context) async {
    // Determine the next lower role
    final newRole = _nextLowerRole(user.normalizedRole);
    if (newRole == null) return;

    final reason = await _reasonDialog(
        context, 'Demote ${user.fullName}', 'Reason for demotion');
    if (reason == null || !context.mounted) return;

    await context.read<AuthProvider>().updateUserRole(user.userId, newRole);

    // Send notification
    await DatabaseService().insertRoleNotification(RoleNotification(
      id: 'rn_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.userId,
      title: 'Role Changed',
      message:
          'Your role has been changed from ${user.roleLabel} '
          'to ${_roleLabelFor(newRole)} by ${me.fullName}.',
      reason: reason,
      fromRole: me.normalizedRole,
      fromName: me.fullName,
      createdAt: DateTime.now(),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} demoted to ${_roleLabelFor(newRole)}'),
          backgroundColor: AppColors.warning));
    }
    onAction();
  }

  Future<void> _delete(BuildContext context) async {
    final reason = await _reasonDialog(
        context, 'Remove ${user.fullName}',
        'This will permanently remove the user. State a reason:');
    if (reason == null || !context.mounted) return;

    // Final confirmation
    final confirmed = await _confirm(
      context,
      'Confirm Removal',
      'Permanently remove ${user.fullName}? This cannot be undone.',
      confirmLabel: 'Remove',
      confirmColor: AppColors.error,
    );
    if (!confirmed || !context.mounted) return;

    // Send notification before deletion
    await DatabaseService().insertRoleNotification(RoleNotification(
      id: 'rn_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.userId,
      title: 'Account Removed',
      message:
          'Your account has been removed from AgricAssist ZW '
          'by ${me.fullName} (${me.roleLabel}).',
      reason: reason,
      fromRole: me.normalizedRole,
      fromName: me.fullName,
      createdAt: DateTime.now(),
    ));

    // If mudhumeni, also update profile status
    if (user.isMudhumeni) {
      try {
        final profiles =
            await MudhumeniDatabaseService.getAllMudhumeniProfiles();
        final profile = profiles
            .where((p) => p.userId == user.userId)
            .firstOrNull;
        if (profile?.id != null) {
          await MudhumeniDatabaseService.updateProfileStatus(
              profile!.id!, 'rejected');
        }
      } catch (_) {}
    }

    await context.read<AuthProvider>().deleteUserById(user.userId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${user.fullName} removed'),
          backgroundColor: AppColors.error));
    }
    onAction();
  }

  String? _nextLowerRole(String role) {
    switch (role) {
      case 'national_admin':   return 'provincial_admin';
      case 'provincial_admin': return 'district_admin';
      case 'district_admin':   return 'mudhumeni';
      case 'mudhumeni':        return 'farmer';
      default:                 return null;
    }
  }

  String _roleLabelFor(String role) {
    switch (role) {
      case 'national_admin':   return 'National Admin';
      case 'provincial_admin': return 'Provincial Admin';
      case 'district_admin':   return 'District Admin';
      case 'mudhumeni':        return 'Mudhumeni';
      default:                 return 'Farmer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDemote = _nextLowerRole(user.normalizedRole) != null;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textHint),
      onSelected: (v) {
        if (v == 'demote') _demote(context);
        if (v == 'delete') _delete(context);
      },
      itemBuilder: (_) => [
        if (canDemote)
          PopupMenuItem(
            value: 'demote',
            child: Row(
              children: [
                Icon(Icons.arrow_downward,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text('Demote',
                    style: TextStyle(color: AppColors.warning)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text('Remove', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SHARED HELPERS
// =============================================================================

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

Widget _empty(IconData icon, String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500])),
          ],
        ],
      ),
    ),
  );
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message, {
  required String confirmLabel,
  required Color confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> _reasonDialog(
    BuildContext context, String title, String subtitle) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'State reason (shown to user)...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final reason = ctrl.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(ctx, reason);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result;
}

Future<void> _sendNotification(
  BuildContext context, {
  required String targetUserId,
  required String title,
  required String message,
  required String reason,
}) async {
  final me = context.read<AuthProvider>().user!;
  await DatabaseService().insertRoleNotification(RoleNotification(
    id: 'rn_${DateTime.now().millisecondsSinceEpoch}',
    userId: targetUserId,
    title: title,
    message: message,
    reason: reason,
    fromRole: me.normalizedRole,
    fromName: me.fullName,
    createdAt: DateTime.now(),
  ));
}