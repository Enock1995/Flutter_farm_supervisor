// lib/screens/mudhumeni/knowledge_posts_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/mudhumeni_model.dart';
import '../../services/mudhumeni_database_service.dart';
import '../../services/database_service.dart';

class KnowledgePostsScreen extends StatefulWidget {
  const KnowledgePostsScreen({super.key});

  @override
  State<KnowledgePostsScreen> createState() =>
      _KnowledgePostsScreenState();
}

class _KnowledgePostsScreenState extends State<KnowledgePostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<KnowledgePost> _posts = [];
  bool _loading = true;

  String get _ward => context.read<AuthProvider>().user?.ward ?? '';

  bool get _canPost {
    final auth = context.read<AuthProvider>();
    return auth.isMudhumeni || auth.isAdmin;
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _canPost ? 2 : 1, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_ward.isEmpty) {
      setState(() { _loading = false; });
      return;
    }
    final posts = await MudhumeniDatabaseService.getPostsByWard(_ward);
    setState(() { _posts = posts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canPost = auth.isMudhumeni || auth.isAdmin;
    final ward = auth.user?.ward ?? '';

    // Ward not set yet — show ward setup prompt
    if (!_loading && ward.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Knowledge Posts')),
        body: _WardSetupPrompt(
          onWardSaved: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Posts'),
        bottom: canPost
            ? TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Feed'),
                  Tab(text: 'Create Post'),
                ],
              )
            : null,
      ),
      body: canPost
          ? TabBarView(
              controller: _tabs,
              children: [
                _FeedTab(
                  posts: _posts,
                  loading: _loading,
                  onRefresh: _load,
                ),
                _CreatePostTab(
                  ward: _ward,
                  onCreated: () {
                    _load();
                    _tabs.animateTo(0);
                  },
                ),
              ],
            )
          : _FeedTab(
              posts: _posts,
              loading: _loading,
              onRefresh: _load,
              showFarmerBanner: true,
            ),
    );
  }
}

// ── Ward Setup Prompt ─────────────────────────────────────
class _WardSetupPrompt extends StatefulWidget {
  final VoidCallback onWardSaved;
  const _WardSetupPrompt({required this.onWardSaved});

  @override
  State<_WardSetupPrompt> createState() => _WardSetupPromptState();
}

class _WardSetupPromptState extends State<_WardSetupPrompt> {
  final _wardCtrl = TextEditingController();
  bool _saving = false;

  static const _green = Color(0xFF558B2F);

  @override
  void dispose() {
    _wardCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ward = _wardCtrl.text.trim();
    if (ward.isEmpty) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().updateUserWard(ward);
    setState(() => _saving = false);
    widget.onWardSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 56, color: _green),
          ),
          const SizedBox(height: 20),
          Text('Set Your Ward',
              style:
                  AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            'To access the Mudhumeni Network, register your ward. '
            'This links you to extension officers and farmers in your area.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _wardCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Ward *',
              hintText: 'e.g. Ward 5 — Gutu',
              prefixIcon: Icon(Icons.map_outlined, color: _green),
            ),
          ),
          const SizedBox(height: 20),
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
                  : const Icon(Icons.save_outlined, color: Colors.white),
              label: Text(_saving ? 'Saving...' : 'Save Ward',
                  style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed tab ──────────────────────────────────────────────
class _FeedTab extends StatelessWidget {
  final List<KnowledgePost> posts;
  final bool loading;
  final VoidCallback onRefresh;
  final bool showFarmerBanner;

  const _FeedTab({
    required this.posts,
    required this.loading,
    required this.onRefresh,
    this.showFarmerBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (showFarmerBanner)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF558B2F).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF558B2F).withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF558B2F), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Posts are created by verified Mudhumeni extension officers. You can read and mark posts.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF558B2F)),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No posts yet.',
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: onRefresh,
                          child: const Text('Refresh')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => _PostCard(
                      post: posts[i],
                      onRead: () async {
                        await MudhumeniDatabaseService.markPostRead(
                            posts[i].id!);
                        onRefresh();
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final KnowledgePost post;
  final VoidCallback onRead;

  const _PostCard({required this.post, required this.onRead});

  static const _typeColors = {
    'tip': Color(0xFF2E7D32),
    'pest_alert': Color(0xFFE65100),
    'disease_alert': Color(0xFFC62828),
    'seasonal': Color(0xFF1565C0),
    'weather': Color(0xFF0277BD),
  };

  static const _typeLabels = {
    'tip': '💡 Tip',
    'pest_alert': '🐛 Pest Alert',
    'disease_alert': '🦠 Disease Alert',
    'seasonal': '🌱 Seasonal',
    'weather': '🌧️ Weather',
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[post.postType] ?? AppColors.primary;
    final label = _typeLabels[post.postType] ?? post.postType;
    final date = DateTime.tryParse(post.createdAt);
    final dateStr =
        date != null ? DateFormat('dd MMM yyyy').format(date) : '';

    return GestureDetector(
      onTap: onRead,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: post.isRead
                ? AppColors.divider
                : color.withOpacity(0.4),
            width: post.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  if (!post.isRead)
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(dateStr, style: AppTextStyles.caption),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: AppTextStyles.heading3),
                  const SizedBox(height: 6),
                  Text(post.body,
                      style: AppTextStyles.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  if (post.photoPath.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(post.photoPath),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified,
                          size: 14, color: Color(0xFF558B2F)),
                      const SizedBox(width: 4),
                      Text(post.authorName,
                          style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF558B2F),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(post.ward, style: AppTextStyles.caption),
                    ],
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

// ── Create post tab (Mudhumeni/Admin only) ────────────────
class _CreatePostTab extends StatefulWidget {
  final String ward;
  final VoidCallback onCreated;
  const _CreatePostTab({required this.ward, required this.onCreated});

  @override
  State<_CreatePostTab> createState() => _CreatePostTabState();
}

class _CreatePostTabState extends State<_CreatePostTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _postType = 'tip';
  File? _photo;
  final _picker = ImagePicker();
  bool _saving = false;

  static const _green = Color(0xFF558B2F);

  static const _types = [
    ('tip', '💡 Tip'),
    ('pest_alert', '🐛 Pest Alert'),
    ('disease_alert', '🦠 Disease Alert'),
    ('seasonal', '🌱 Seasonal Advisory'),
    ('weather', '🌧️ Weather Warning'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;
    final post = KnowledgePost(
      authorId: user?.userId ?? '',
      authorName: user?.fullName ?? '',
      ward: widget.ward,
      district: user?.district ?? '',
      postType: _postType,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      photoPath: _photo?.path ?? '',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    await MudhumeniDatabaseService.savePost(post);
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final selected = _postType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _postType = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _green : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? _green : AppColors.divider),
                  ),
                  child: Text(t.$2,
                      style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title *',
              prefixIcon: Icon(Icons.title_outlined, color: _green),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bodyCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Body *',
              alignLabelWithHint: true,
              hintText: 'Write your advice, alert or advisory here...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.notes_outlined, color: _green),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_photo!,
                  height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _photo = null),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Remove photo'),
            ),
          ] else
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: _green),
              label: const Text('Attach Photo',
                  style: TextStyle(color: _green)),
            ),
          const SizedBox(height: 20),
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
                  : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(_saving ? 'Publishing...' : 'Publish Post',
                  style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}