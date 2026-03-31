// lib/screens/mudhumeni/area_management_screen.dart
// Developed by Sir Enocks Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../services/mudhumeni_database_service.dart';

class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _farmers = [];
  List<UserModel> _mudhumeniOfficers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final db = DatabaseService();

      // Load based on authority level
      if (user.isNationalAdmin) {
        // National admin sees ALL farmers and ALL mudhumeni
        _farmers = await db.getUsersByRole('farmer');
        _mudhumeniOfficers = await db.getUsersByRole('mudhumeni');
      } else if (user.isProvincialAdmin) {
        // Provincial admin sees farmers and mudhumeni in their province
        _farmers = await db.getUsersByRole('farmer', province: user.province);
        _mudhumeniOfficers = await db.getUsersByRole('mudhumeni', province: user.province);
      } else if (user.isDistrictAdmin) {
        // District admin sees farmers and mudhumeni in their district
        _farmers = await db.getUsersByRole('farmer', district: user.district);
        _mudhumeniOfficers = await db.getUsersByRole('mudhumeni', district: user.district);
      } else if (user.isMudhumeni) {
        // Mudhumeni sees farmers in their ward only
        _farmers = await db.getFarmersByWard(user.ward);
        _mudhumeniOfficers = []; // Mudhumeni don't see other mudhumeni
      } else {
        setState(() {
          _error = 'Insufficient permissions';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Area Management')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area & Farmer Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'My Farmers'),
            Tab(icon: Icon(Icons.verified_user), text: 'Mudhumeni Officers'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadData)
              : Column(
                  children: [
                    _AreaInfoHeader(user: user),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _FarmersTab(
                            farmers: _farmers,
                            user: user,
                            onRefresh: _loadData,
                          ),
                          _MudhumeniTab(
                            officers: _mudhumeniOfficers,
                            user: user,
                            onRefresh: _loadData,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AREA INFO HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _AreaInfoHeader extends StatelessWidget {
  final UserModel user;
  const _AreaInfoHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                user.roleEmoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.roleLabel,
                      style: AppTextStyles.heading3.copyWith(color: Colors.white),
                    ),
                    Text(
                      user.fullName,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoChip(
            icon: Icons.location_on,
            label: _getAreaLabel(user),
          ),
        ],
      ),
    );
  }

  String _getAreaLabel(UserModel user) {
    if (user.isNationalAdmin) return 'National Coverage';
    if (user.isProvincialAdmin) return 'Province: ${user.province}';
    if (user.isDistrictAdmin) return 'District: ${user.district}';
    if (user.isMudhumeni) return 'Ward: ${user.ward}, ${user.district}';
    return user.district;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FARMERS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _FarmersTab extends StatelessWidget {
  final List<UserModel> farmers;
  final UserModel user;
  final VoidCallback onRefresh;

  const _FarmersTab({
    required this.farmers,
    required this.user,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (farmers.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline,
        title: 'No Farmers Found',
        message: 'There are no farmers registered in your area yet.',
      );
    }

    // Group by ward if admin
    final groupedFarmers = <String, List<UserModel>>{};
    if (user.isAdmin) {
      for (final farmer in farmers) {
        final key = farmer.ward.isEmpty ? 'No Ward Assigned' : 'Ward ${farmer.ward}';
        groupedFarmers.putIfAbsent(key, () => []).add(farmer);
      }
    } else {
      groupedFarmers['Ward ${user.ward}'] = farmers;
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedFarmers.length,
        itemBuilder: (context, index) {
          final ward = groupedFarmers.keys.elementAt(index);
          final wardFarmers = groupedFarmers[ward]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      ward,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${wardFarmers.length}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...wardFarmers.map((farmer) => _FarmerCard(
                    farmer: farmer,
                    canManage: user.canManageUser(farmer),
                    onRefresh: onRefresh,
                  )),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final UserModel farmer;
  final bool canManage;
  final VoidCallback onRefresh;

  const _FarmerCard({
    required this.farmer,
    required this.canManage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            farmer.fullName.isNotEmpty ? farmer.fullName[0].toUpperCase() : '?',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(farmer.fullName, style: AppTextStyles.body),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${farmer.userId}  •  ${farmer.phone}',
              style: AppTextStyles.caption,
            ),
            if (farmer.ward.isNotEmpty)
              Text(
                'Ward ${farmer.ward}, ${farmer.district}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
          ],
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'activity',
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 8),
                        Text('View Activity'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'contact',
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 20),
                        SizedBox(width: 8),
                        Text('Contact'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'activity':
        _showActivityDialog(context);
        break;
      case 'contact':
        _showContactDialog(context);
        break;
    }
  }

  Future<void> _showActivityDialog(BuildContext context) async {
    final stats = await _loadFarmerStats();
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${farmer.fullName} - Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(icon: Icons.question_answer, label: 'Questions Asked', value: '${stats['questions']}'),
            _StatRow(icon: Icons.forum, label: 'Community Posts', value: '${stats['posts']}'),
            _StatRow(icon: Icons.calendar_today, label: 'Field Visits', value: '${stats['visits']}'),
            _StatRow(icon: Icons.event_available, label: 'Last Active', value: stats['lastActive']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadFarmerStats() async {
    try {
      final questions = await MudhumeniDatabaseService.getQuestionsByUser(farmer.userId);
      final posts = await MudhumeniDatabaseService.getCommunityPostsByUser(farmer.userId);
      final visits = await MudhumeniDatabaseService.getVisitsByFarmer(farmer.userId);

      // Get most recent activity
      // NOTE: createdAt fields are stored as ISO8601 strings, need to parse them
      DateTime? lastActivity;
      
      if (questions.isNotEmpty) {
        // Parse the string to DateTime
        lastActivity = DateTime.tryParse(questions.first.createdAt);
      }
      
      if (posts.isNotEmpty) {
        final postDate = DateTime.tryParse(posts.first.createdAt);
        if (postDate != null && (lastActivity == null || postDate.isAfter(lastActivity))) {
          lastActivity = postDate;
        }
      }

      final lastActiveStr = lastActivity != null
          ? _formatDate(lastActivity)
          : 'No activity';

      return {
        'questions': questions.length,
        'posts': posts.length,
        'visits': visits.length,
        'lastActive': lastActiveStr,
      };
    } catch (e) {
      return {
        'questions': 0,
        'posts': 0,
        'visits': 0,
        'lastActive': 'Unknown',
      };
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${farmer.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primary),
              title: Text(farmer.phone),
              subtitle: const Text('Phone Number'),
            ),
            if (farmer.email != null)
              ListTile(
                leading: const Icon(Icons.email, color: AppColors.primary),
                title: Text(farmer.email!),
                subtitle: const Text('Email'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MUDHUMENI TAB
// ══════════════════════════════════════════════════════════════════════════════

class _MudhumeniTab extends StatelessWidget {
  final List<UserModel> officers;
  final UserModel user;
  final VoidCallback onRefresh;

  const _MudhumeniTab({
    required this.officers,
    required this.user,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!user.isAdmin) {
      return const _EmptyState(
        icon: Icons.lock_outline,
        title: 'Admin Only',
        message: 'Only administrators can view Mudhumeni officers.',
      );
    }

    if (officers.isEmpty) {
      return const _EmptyState(
        icon: Icons.verified_user_outlined,
        title: 'No Mudhumeni Officers',
        message: 'No Mudhumeni officers are registered in your area yet.',
      );
    }

    // Group by district
    final groupedOfficers = <String, List<UserModel>>{};
    for (final officer in officers) {
      final key = officer.district;
      groupedOfficers.putIfAbsent(key, () => []).add(officer);
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedOfficers.length,
        itemBuilder: (context, index) {
          final district = groupedOfficers.keys.elementAt(index);
          final districtOfficers = groupedOfficers[district]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      district,
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${districtOfficers.length} officers',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...districtOfficers.map((officer) => _MudhumeniCard(officer: officer)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _MudhumeniCard extends StatelessWidget {
  final UserModel officer;
  const _MudhumeniCard({required this.officer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withOpacity(0.1),
          child: const Icon(Icons.verified_user, color: AppColors.success),
        ),
        title: Text(officer.fullName, style: AppTextStyles.body),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${officer.userId}  •  ${officer.phone}',
              style: AppTextStyles.caption,
            ),
            Text(
              'Ward ${officer.ward}, ${officer.district}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Text(
            'VERIFIED',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}