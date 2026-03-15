// lib/screens/mudhumeni/community_fieldvisits_screens.dart
// Developed by Sir Enocks — Cor Technologies
// Contains: CommunityScreen, FieldVisitsScreen, SeasonalCalendarScreen, AreaManagementScreen

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/mudhumeni_model.dart';
import '../../services/mudhumeni_database_service.dart';
import '../farm_management/farm_management_shared_widgets.dart';

// ═══════════════════════════════════════════════════════════
// COMMUNITY  —  /community
// ═══════════════════════════════════════════════════════════
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<CommunityPost> _posts = [];
  bool _loading = true;

  String get _ward =>
      context.read<AuthProvider>().user?.district ?? 'General';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final posts = await MudhumeniDatabaseService.getCommunityPosts(_ward);
    setState(() { _posts = posts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Community'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Feed'), Tab(text: 'Post')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CommunityFeed(
            posts: _posts,
            loading: _loading,
            onRefresh: _load,
            onReact: (id) async {
              await MudhumeniDatabaseService.reactToPost(id);
              _load();
            },
            onDelete: (id) async {
              await MudhumeniDatabaseService.deletePost(id);
              _load();
            },
          ),
          _CreateCommunityPost(
            ward: _ward,
            onCreated: () {
              _load();
              _tabs.animateTo(0);
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityFeed extends StatelessWidget {
  final List<CommunityPost> posts;
  final bool loading;
  final VoidCallback onRefresh;
  final Function(int) onReact;
  final Function(int) onDelete;

  const _CommunityFeed({
    required this.posts,
    required this.loading,
    required this.onRefresh,
    required this.onReact,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No posts yet. Be the first!',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, i) {
          final post = posts[i];
          final date = DateTime.tryParse(post.createdAt);
          final dateStr =
              date != null ? DateFormat('dd MMM HH:mm').format(date) : '';
          final pollOptions = post.postType == 'poll'
              ? List<String>.from(jsonDecode(post.pollOptions))
              : <String>[];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.12),
                        child: Text(
                          post.authorName.isNotEmpty
                              ? post.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName,
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w600)),
                            Text(dateStr,
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'delete') onDelete(post.id!);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Post')),
                        ],
                        child: const Icon(Icons.more_vert,
                            color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (post.content.isNotEmpty)
                    Text(post.content, style: AppTextStyles.body),
                  if (pollOptions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...pollOptions.map((opt) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(opt, style: AppTextStyles.body),
                        )),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => onReact(post.id!),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_outline,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('${post.reactions}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CreateCommunityPost extends StatefulWidget {
  final String ward;
  final VoidCallback onCreated;
  const _CreateCommunityPost(
      {required this.ward, required this.onCreated});

  @override
  State<_CreateCommunityPost> createState() =>
      _CreateCommunityPostState();
}

class _CreateCommunityPostState extends State<_CreateCommunityPost> {
  final _contentCtrl = TextEditingController();
  String _postType = 'text';
  final List<TextEditingController> _pollCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    for (final c in _pollCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty && _postType != 'poll') return;
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;

    final pollOptions = _postType == 'poll'
        ? jsonEncode(_pollCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList())
        : '[]';

    final post = CommunityPost(
      authorId: user?.userId ?? '',
      authorName: user?.fullName ?? '',
      ward: widget.ward,
      postType: _postType,
      content: _contentCtrl.text.trim(),
      photoPath: '',
      pollOptions: pollOptions,
      reactions: 0,
      isDeleted: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    await MudhumeniDatabaseService.saveCommunityPost(post);
    setState(() => _saving = false);
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Post Type', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final t in [
                ('text', 'Text', Icons.text_fields),
                ('poll', 'Poll', Icons.poll_outlined),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _postType = t.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _postType == t.$1
                              ? AppColors.primary
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _postType == t.$1
                                  ? AppColors.primary
                                  : AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Icon(t.$3,
                                color: _postType == t.$1
                                    ? Colors.white
                                    : AppColors.textSecondary),
                            const SizedBox(height: 4),
                            Text(t.$2,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _postType == t.$1
                                        ? Colors.white
                                        : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_postType != 'poll')
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'What\'s on your mind?',
                alignLabelWithHint: true,
              ),
            ),
          if (_postType == 'poll') ...[
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(labelText: 'Poll Question'),
            ),
            const SizedBox(height: 12),
            ..._pollCtrls.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                          labelText: 'Option ${e.key + 1}'),
                    ),
                  ),
                ),
            TextButton.icon(
              onPressed: () => setState(
                  () => _pollCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(_saving ? 'Posting...' : 'Post to Community',
                  style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FIELD VISITS  —  /field-visits
// ═══════════════════════════════════════════════════════════
class FieldVisitsScreen extends StatefulWidget {
  const FieldVisitsScreen({super.key});

  @override
  State<FieldVisitsScreen> createState() => _FieldVisitsScreenState();
}

class _FieldVisitsScreenState extends State<FieldVisitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<FieldVisit> _visits = [];
  bool _loading = true;

  static const _stubMudhumeniId = 'mudhumeni_001';
  static const _green = Color(0xFF558B2F);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    final visits = await MudhumeniDatabaseService.getVisitsByFarmer(
        user?.userId ?? '');
    setState(() { _visits = visits; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field Visit Scheduler')),
      body: TabBarView(
        controller: _tabs,
        children: [
          _VisitListTab(
            visits: _visits,
            loading: _loading,
            onRefresh: _load,
            onUpdateStatus: (id, status) async {
              await MudhumeniDatabaseService.updateVisitStatus(
                  id, status);
              _load();
            },
          ),
          _RequestVisitTab(
            mudhumeniId: _stubMudhumeniId,
            onRequested: () {
              _load();
              _tabs.animateTo(0);
            },
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabs,
        labelColor: _green,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: _green,
        tabs: const [
          Tab(icon: Icon(Icons.list_alt_outlined), text: 'My Requests'),
          Tab(icon: Icon(Icons.add_circle_outline), text: 'Request Visit'),
        ],
      ),
    );
  }
}

class _VisitListTab extends StatelessWidget {
  final List<FieldVisit> visits;
  final bool loading;
  final VoidCallback onRefresh;
  final Function(int, String) onUpdateStatus;

  const _VisitListTab({
    required this.visits,
    required this.loading,
    required this.onRefresh,
    required this.onUpdateStatus,
  });

  static const _statusColors = {
    'requested': Color(0xFF1565C0),
    'confirmed': Color(0xFF2E7D32),
    'rescheduled': Color(0xFFE65100),
    'completed': AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No visit requests yet.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, i) {
        final v = visits[i];
        final color = _statusColors[v.status] ?? AppColors.primary;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(v.issueDescription,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(v.status.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Preferred: ${v.preferredDate}',
                    style: AppTextStyles.caption),
                if (v.confirmedDate.isNotEmpty)
                  Text('Confirmed: ${v.confirmedDate}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.success)),
                if (v.visitNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(v.visitNotes,
                        style: AppTextStyles.bodySmall),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestVisitTab extends StatefulWidget {
  final String mudhumeniId;
  final VoidCallback onRequested;
  const _RequestVisitTab(
      {required this.mudhumeniId, required this.onRequested});

  @override
  State<_RequestVisitTab> createState() => _RequestVisitTabState();
}

class _RequestVisitTabState extends State<_RequestVisitTab> {
  final _issueCtrl = TextEditingController();
  DateTime? _preferredDate;
  bool _saving = false;

  static const _green = Color(0xFF558B2F);

  @override
  void dispose() {
    _issueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d != null) setState(() => _preferredDate = d);
  }

  Future<void> _submit() async {
    if (_issueCtrl.text.trim().isEmpty || _preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields.')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;
    final visit = FieldVisit(
      farmerId: user?.userId ?? '',
      farmerName: user?.fullName ?? '',
      mudhumeniId: widget.mudhumeniId,
      ward: user?.district ?? '',
      issueDescription: _issueCtrl.text.trim(),
      preferredDate:
          DateFormat('dd MMM yyyy').format(_preferredDate!),
      confirmedDate: '',
      status: 'requested',
      visitNotes: '',
      createdAt: DateTime.now().toIso8601String(),
    );
    await MudhumeniDatabaseService.saveVisitRequest(visit);
    setState(() => _saving = false);
    widget.onRequested();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FarmSectionHeader(
            icon: Icons.event_available_outlined,
            color: _green,
            title: 'Request Farm Visit',
            subtitle: 'Ask your AGRITEX Mudhumeni to visit your farm.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _issueCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe the Issue *',
              alignLabelWithHint: true,
              hintText:
                  'e.g. My maize crop is showing unusual symptoms and I need expert advice...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description_outlined,
                    color: _green),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: _green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _preferredDate != null
                          ? 'Preferred Date: ${DateFormat('dd MMM yyyy').format(_preferredDate!)}'
                          : 'Select Preferred Date *',
                      style: AppTextStyles.body.copyWith(
                        color: _preferredDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textHint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(_saving ? 'Requesting...' : 'Request Visit',
                  style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SEASONAL CALENDAR  —  /seasonal-calendar
// ═══════════════════════════════════════════════════════════
class SeasonalCalendarScreen extends StatefulWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  State<SeasonalCalendarScreen> createState() =>
      _SeasonalCalendarScreenState();
}

class _SeasonalCalendarScreenState extends State<SeasonalCalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<SeasonalEntry> _entries = [];
  bool _loading = true;

  static const _green = Color(0xFF558B2F);

  String get _ward =>
      context.read<AuthProvider>().user?.district ?? 'General';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entries =
        await MudhumeniDatabaseService.getCalendarByWard(_ward);
    setState(() { _entries = entries; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seasonal Crop Calendar')),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CalendarTab(
            entries: _entries,
            loading: _loading,
            onRefresh: _load,
            onToggleDone: (id, done) async {
              await MudhumeniDatabaseService.markEntryDone(id, done);
              _load();
            },
            onDelete: (id) async {
              await MudhumeniDatabaseService.deleteEntry(id);
              _load();
            },
          ),
          _AddEntryTab(
            ward: _ward,
            onAdded: () {
              _load();
              _tabs.animateTo(0);
            },
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabs,
        labelColor: _green,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: _green,
        tabs: const [
          Tab(icon: Icon(Icons.calendar_view_month), text: 'Calendar'),
          Tab(icon: Icon(Icons.add_circle_outline), text: 'Add Activity'),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  final List<SeasonalEntry> entries;
  final bool loading;
  final VoidCallback onRefresh;
  final Function(int, bool) onToggleDone;
  final Function(int) onDelete;

  const _CalendarTab({
    required this.entries,
    required this.loading,
    required this.onRefresh,
    required this.onToggleDone,
    required this.onDelete,
  });

  static const _actColors = {
    'plant': Color(0xFF2E7D32),
    'fertilize': Color(0xFF1565C0),
    'spray': Color(0xFFE65100),
    'harvest': Color(0xFFF9A825),
  };
  static const _actIcons = {
    'plant': Icons.eco_outlined,
    'fertilize': Icons.science_outlined,
    'spray': Icons.water_drop_outlined,
    'harvest': Icons.agriculture_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No calendar entries yet.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final color = _actColors[e.activityType] ?? AppColors.primary;
        final icon =
            _actIcons[e.activityType] ?? Icons.event_outlined;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: e.isDone ? AppColors.background : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: e.isDone
                    ? AppColors.divider
                    : color.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(e.isDone ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: color.withOpacity(e.isDone ? 0.3 : 1.0),
                  size: 22),
            ),
            title: Text(
              '${e.cropType} — ${e.activityType.toUpperCase()}',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: e.isDone
                    ? AppColors.textHint
                    : AppColors.textPrimary,
                decoration: e.isDone
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              '${e.scheduledDate}${e.notes.isNotEmpty ? ' · ${e.notes}' : ''}',
              style: AppTextStyles.caption,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: e.isDone,
                  activeColor: AppColors.success,
                  onChanged: (v) => onToggleDone(e.id!, v ?? false),
                ),
                GestureDetector(
                  onTap: () => onDelete(e.id!),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.textHint, size: 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddEntryTab extends StatefulWidget {
  final String ward;
  final VoidCallback onAdded;
  const _AddEntryTab({required this.ward, required this.onAdded});

  @override
  State<_AddEntryTab> createState() => _AddEntryTabState();
}

class _AddEntryTabState extends State<_AddEntryTab> {
  final _cropCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _activityType = 'plant';
  DateTime? _date;
  bool _saving = false;

  static const _green = Color(0xFF558B2F);
  static const _activities = [
    ('plant', 'Plant', Icons.eco_outlined),
    ('fertilize', 'Fertilize', Icons.science_outlined),
    ('spray', 'Spray', Icons.water_drop_outlined),
    ('harvest', 'Harvest', Icons.agriculture_outlined),
  ];

  @override
  void dispose() {
    _cropCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_cropCtrl.text.trim().isEmpty || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crop type and date are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;
    final entry = SeasonalEntry(
      mudhumeniId: user?.userId ?? '',
      ward: widget.ward,
      cropType: _cropCtrl.text.trim(),
      activityType: _activityType,
      scheduledDate: DateFormat('dd MMM yyyy').format(_date!),
      notes: _notesCtrl.text.trim(),
      isDone: false,
      season: '2025/2026',
      createdAt: DateTime.now().toIso8601String(),
    );
    await MudhumeniDatabaseService.saveSeasonalEntry(entry);
    setState(() => _saving = false);
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _cropCtrl,
            decoration: const InputDecoration(
              labelText: 'Crop Type *',
              prefixIcon:
                  Icon(Icons.eco_outlined, color: _green),
            ),
          ),
          const SizedBox(height: 16),
          Text('Activity Type', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Row(
            children: _activities.map((a) {
              final sel = _activityType == a.$1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activityType = a.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _green : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? _green : AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Icon(a.$3,
                              color:
                                  sel ? Colors.white : AppColors.textHint,
                              size: 20),
                          const SizedBox(height: 3),
                          Text(a.$2,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textHint)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: _green),
                  const SizedBox(width: 12),
                  Text(
                    _date != null
                        ? 'Date: ${DateFormat('dd MMM yyyy').format(_date!)}'
                        : 'Select Scheduled Date *',
                    style: AppTextStyles.body.copyWith(
                      color: _date != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              prefixIcon: Icon(Icons.notes_outlined, color: _green),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline,
                      color: Colors.white),
              label: Text(_saving ? 'Saving...' : 'Add to Calendar',
                  style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// AREA MANAGEMENT  —  /area-management
// ═══════════════════════════════════════════════════════════
class AreaManagementScreen extends StatefulWidget {
  const AreaManagementScreen({super.key});

  @override
  State<AreaManagementScreen> createState() => _AreaManagementScreenState();
}

class _AreaManagementScreenState extends State<AreaManagementScreen> {
  static const _green = Color(0xFF558B2F);

  // Stub linked farmers list — in production synced from backend
  final List<Map<String, String>> _linkedFarmers = [
    {'name': 'John Moyo', 'ward': 'Ward 5', 'farm': 'Moyo Farm — 5ha'},
    {'name': 'Chipo Sibanda', 'ward': 'Ward 5', 'farm': 'Sibanda Fields — 3ha'},
    {'name': 'Tapiwa Ncube', 'ward': 'Ward 5', 'farm': 'Ncube Farm — 8ha'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final ward = user?.district ?? 'General';

    return Scaffold(
      appBar: AppBar(title: const Text('Area & Farmer Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FarmSectionHeader(
              icon: Icons.map_outlined,
              color: _green,
              title: 'Your Coverage Area',
              subtitle: 'Ward: $ward',
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _StatCard(
                  icon: Icons.people_outline,
                  label: 'Linked Farmers',
                  value: '${_linkedFarmers.length}',
                  color: _green,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.map_outlined,
                  label: 'Ward Coverage',
                  value: '1 Ward',
                  color: AppColors.info,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text('Linked Farmers', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ..._linkedFarmers.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _green.withOpacity(0.12),
                      child: Text(
                        f['name']![0].toUpperCase(),
                        style: const TextStyle(
                            color: _green, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f['name']!,
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600)),
                          Text('${f['ward']} · ${f['farm']}',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF558B2F), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Farmers in your ward can link to you by selecting your name during registration. Full farmer management requires backend sync.',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF558B2F)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: AppTextStyles.heading2.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}