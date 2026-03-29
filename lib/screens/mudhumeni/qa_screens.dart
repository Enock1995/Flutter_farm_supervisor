// lib/screens/mudhumeni/qa_screens.dart
// Developed by Sir Enocks — Cor Technologies
// Contains both PublicQaScreen (/public-qa) and PrivateQaScreen (/private-qa)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/mudhumeni_model.dart';
import '../../services/mudhumeni_database_service.dart';

// ═══════════════════════════════════════════════════════════
// PUBLIC Q&A  —  /public-qa
// ═══════════════════════════════════════════════════════════
class PublicQaScreen extends StatefulWidget {
  const PublicQaScreen({super.key});

  @override
  State<PublicQaScreen> createState() => _PublicQaScreenState();
}

class _PublicQaScreenState extends State<PublicQaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<QaQuestion> _questions = [];
  Set<int> _upvotedIds = {}; // question IDs this user has already agreed to
  bool _loading = true;
  String _sort = 'newest';

  String get _ward => context.read<AuthProvider>().user?.ward ?? '';
  String get _userId => context.read<AuthProvider>().user?.userId ?? '';

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
    if (_ward.isEmpty) {
      setState(() { _loading = false; });
      return;
    }
    final questions =
        await MudhumeniDatabaseService.getPublicQuestions(_ward);
    final upvoted =
        await MudhumeniDatabaseService.getUserUpvotedIds(_userId);
    setState(() {
      _questions = questions;
      _upvotedIds = upvoted.toSet();
      _loading = false;
    });
  }

  List<QaQuestion> get _sorted {
    final list = List<QaQuestion>.from(_questions);
    switch (_sort) {
      case 'upvotes':
        list.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
      case 'unanswered':
        list.removeWhere((q) => q.answer.isNotEmpty);
        break;
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  Future<void> _handleToggleUpvote(int questionId) async {
    await MudhumeniDatabaseService.toggleUpvote(questionId, _userId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ward = auth.user?.ward ?? '';

    // Ward not set yet — show ward setup prompt
    if (!_loading && ward.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Public Q&A')),
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
        title: const Text('Public Q&A'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Questions'), Tab(text: 'Ask')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _QuestionsTab(
            questions: _sorted,
            upvotedIds: _upvotedIds,
            loading: _loading,
            sort: _sort,
            onSortChanged: (v) => setState(() => _sort = v),
            onRefresh: _load,
            onToggleUpvote: _handleToggleUpvote,
            onAnswer: (id, ans, by, byMudhumeni) async {
              await MudhumeniDatabaseService.answerQuestion(
                  id, ans, by, byMudhumeni);
              _load();
            },
          ),
          _AskTab(
            ward: _ward,
            isPublic: true,
            onAsked: () {
              _load();
              _tabs.animateTo(0);
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PRIVATE Q&A  —  /private-qa
// ═══════════════════════════════════════════════════════════
class PrivateQaScreen extends StatefulWidget {
  const PrivateQaScreen({super.key});

  @override
  State<PrivateQaScreen> createState() => _PrivateQaScreenState();
}

class _PrivateQaScreenState extends State<PrivateQaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<QaQuestion> _questions = [];
  bool _loading = true;
  List<MudhumeniProfile> _wardMudhumeni = [];
  MudhumeniProfile? _selectedMudhumeni;

  String get _ward => context.read<AuthProvider>().user?.ward ?? '';
  String get _userId => context.read<AuthProvider>().user?.userId ?? '';
  bool get _isMudhumeniOrAdmin {
    final auth = context.read<AuthProvider>();
    return auth.isMudhumeni || auth.isAdmin;
  }

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
    if (_ward.isEmpty) {
      setState(() { _loading = false; });
      return;
    }

    if (_isMudhumeniOrAdmin) {
      // Mudhumeni sees private questions sent to their userId
      final questions = await MudhumeniDatabaseService
          .getPrivateQuestionsForMudhumeni(_userId);
      setState(() { _questions = questions; _loading = false; });
    } else {
      // Farmer — load verified mudhumeni in their ward first
      final wardMudhumeni = await MudhumeniDatabaseService
          .getVerifiedMudhumeniByWard(_ward);
      if (_selectedMudhumeni == null && wardMudhumeni.isNotEmpty) {
        _selectedMudhumeni = wardMudhumeni.first;
      }
      final questions = _selectedMudhumeni != null
          ? await MudhumeniDatabaseService.getPrivateQuestions(
              _userId, _selectedMudhumeni!.userId)
          : <QaQuestion>[];
      setState(() {
        _wardMudhumeni = wardMudhumeni;
        _questions = questions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ward = auth.user?.ward ?? '';
    final isMudhumeniOrAdmin = auth.isMudhumeni || auth.isAdmin;

    // Ward not set yet — show ward setup prompt
    if (!_loading && ward.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Private Q&A')),
        body: _WardSetupPrompt(
          onWardSaved: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    }

    // Farmer with no mudhumeni in their ward
    if (!_loading && !isMudhumeniOrAdmin && _wardMudhumeni.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Private Q&A')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_search_outlined,
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No Mudhumeni in Your Ward',
                    style: AppTextStyles.heading3,
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  'There are no verified Mudhumeni extension officers '
                  'in $ward yet. Check back later or use Public Q&A.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Q&A'),
        // Mudhumeni picker only if farmer has multiple mudhumeni in ward
        bottom: (!isMudhumeniOrAdmin && _wardMudhumeni.length > 1)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DropdownButtonFormField<MudhumeniProfile>(
                    value: _selectedMudhumeni,
                    dropdownColor: AppColors.primaryDark,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none),
                    ),
                    items: _wardMudhumeni
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.fullName,
                                  style: const TextStyle(
                                      color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (m) {
                      setState(() {
                        _selectedMudhumeni = m;
                        _loading = true;
                      });
                      _load();
                    },
                  ),
                ),
              )
            : null,
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PrivateThreadTab(
            questions: _questions,
            loading: _loading,
            isMudhumeniOrAdmin: isMudhumeniOrAdmin,
            onRefresh: _load,
            onMakePublic: (id) async {
              await MudhumeniDatabaseService.makePublic(id);
              _load();
            },
            onAnswer: (id, ans) async {
              final name = auth.user?.fullName ?? 'Mudhumeni';
              await MudhumeniDatabaseService.answerQuestion(
                  id, ans, name, true);
              _load();
            },
          ),
          if (!isMudhumeniOrAdmin)
            _AskTab(
              ward: _ward,
              isPublic: false,
              mudhumeniId: _selectedMudhumeni?.userId ?? '',
              onAsked: () {
                _load();
                _tabs.animateTo(0);
              },
            )
          else
            const _MudhumeniInfoPanel(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        tabs: [
          const Tab(text: 'Thread'),
          Tab(text: isMudhumeniOrAdmin ? 'Info' : 'Ask'),
        ],
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
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Set Your Ward',
              style: AppTextStyles.heading2
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(
            'Register your ward to connect with Mudhumeni officers '
            'and farmers in your area.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _wardCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Ward *',
              hintText: 'e.g. Ward 5 — Gutu',
              prefixIcon:
                  Icon(Icons.map_outlined, color: AppColors.primary),
            ),
          ),
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

// ── Questions list tab ────────────────────────────────────
class _QuestionsTab extends StatelessWidget {
  final List<QaQuestion> questions;
  final Set<int> upvotedIds;
  final bool loading;
  final String sort;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onRefresh;
  final Function(int) onToggleUpvote;
  final Function(int, String, String, bool) onAnswer;

  const _QuestionsTab({
    required this.questions,
    required this.upvotedIds,
    required this.loading,
    required this.sort,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onToggleUpvote,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text('Sort: ', style: AppTextStyles.bodySmall),
              const SizedBox(width: 6),
              for (final s in [
                ('newest', 'Newest'),
                ('upvotes', 'Most Agreed'),
                ('unanswered', 'Unanswered'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSortChanged(s.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sort == s.$1
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sort == s.$1
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(s.$2,
                          style: TextStyle(
                              fontSize: 11,
                              color: sort == s.$1
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: sort == s.$1
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No questions yet.',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, i) => _QuestionCard(
                    q: questions[i],
                    hasUpvoted:
                        upvotedIds.contains(questions[i].id),
                    onToggleUpvote: () =>
                        onToggleUpvote(questions[i].id!),
                    onAnswer: (ans, by, byMud) =>
                        onAnswer(questions[i].id!, ans, by, byMud),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QaQuestion q;
  final bool hasUpvoted;
  final VoidCallback onToggleUpvote;
  final Function(String, String, bool) onAnswer;

  const _QuestionCard({
    required this.q,
    required this.hasUpvoted,
    required this.onToggleUpvote,
    required this.onAnswer,
  });

  void _showAnswerDialog(BuildContext context) {
    final ctrl = TextEditingController();
    final auth = context.read<AuthProvider>();
    final isMudhumeniOrAdmin = auth.isMudhumeni || auth.isAdmin;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Answer this question'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration:
              const InputDecoration(hintText: 'Type your answer here...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onAnswer(
                  ctrl.text.trim(),
                  auth.user?.fullName ?? 'User',
                  isMudhumeniOrAdmin,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canAnswer = auth.isMudhumeni || auth.isAdmin;
    final date = DateTime.tryParse(q.createdAt);
    final dateStr =
        date != null ? DateFormat('dd MMM').format(date) : '';
    final isAnswered = q.answer.isNotEmpty;

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
                  child: Text(q.question,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAnswered
                            ? AppColors.success
                            : AppColors.warning)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAnswered ? '✅ Answered' : '⏳ Pending',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isAnswered
                            ? AppColors.success
                            : AppColors.warning),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${q.authorName} · $dateStr',
                style: AppTextStyles.caption),
            if (isAnswered) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          q.answeredByMudhumeni
                              ? Icons.verified
                              : Icons.person_outline,
                          color: q.answeredByMudhumeni
                              ? AppColors.success
                              : AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          q.answeredByMudhumeni
                              ? '${q.answeredBy} · Mudhumeni'
                              : q.answeredBy,
                          style: AppTextStyles.caption.copyWith(
                              color: q.answeredByMudhumeni
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(q.answer, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                // Toggle agree — one per user, filled when agreed
                GestureDetector(
                  onTap: onToggleUpvote,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasUpvoted
                          ? AppColors.info.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasUpvoted
                            ? AppColors.info
                            : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 14,
                          color: hasUpvoted
                              ? AppColors.info
                              : AppColors.textHint,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${q.upvotes} agree',
                          style: AppTextStyles.caption.copyWith(
                            color: hasUpvoted
                                ? AppColors.info
                                : AppColors.textHint,
                            fontWeight: hasUpvoted
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (canAnswer && !isAnswered)
                  TextButton(
                    onPressed: () => _showAnswerDialog(context),
                    child: const Text('Answer',
                        style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private thread tab ────────────────────────────────────
class _PrivateThreadTab extends StatelessWidget {
  final List<QaQuestion> questions;
  final bool loading;
  final bool isMudhumeniOrAdmin;
  final VoidCallback onRefresh;
  final Function(int) onMakePublic;
  final Function(int, String) onAnswer;

  const _PrivateThreadTab({
    required this.questions,
    required this.loading,
    required this.isMudhumeniOrAdmin,
    required this.onRefresh,
    required this.onMakePublic,
    required this.onAnswer,
  });

  void _showReplyDialog(BuildContext context, int questionId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reply to question'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration:
              const InputDecoration(hintText: 'Type your reply here...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onAnswer(questionId, ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              isMudhumeniOrAdmin
                  ? 'No private questions from farmers yet.'
                  : 'No private questions yet.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, i) {
        final q = questions[i];
        final isAnswered = q.answer.isNotEmpty;
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
                    const Icon(Icons.lock_outline,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('Private',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint)),
                    if (isMudhumeniOrAdmin) ...[
                      const Spacer(),
                      Text('From: ${q.authorName}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(q.question,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                if (isAnswered) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified,
                                size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(q.answeredBy,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(q.answer, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  if (!q.madePublic && isMudhumeniOrAdmin) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => onMakePublic(q.id!),
                      icon: const Icon(Icons.public_outlined, size: 14),
                      label: const Text('Make Public',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 8),
                  if (isMudhumeniOrAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showReplyDialog(context, q.id!),
                        icon:
                            const Icon(Icons.reply_outlined, size: 16),
                        label: const Text('Reply'),
                      ),
                    )
                  else
                    Text('Awaiting reply from Mudhumeni...',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Mudhumeni info panel ──────────────────────────────────
class _MudhumeniInfoPanel extends StatelessWidget {
  const _MudhumeniInfoPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Private Questions from Farmers',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Farmers in your ward send you questions privately. '
            'Reply to them in the Thread tab. '
            'You can make answered questions public so other farmers can benefit.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Shared: Ask tab ───────────────────────────────────────
class _AskTab extends StatefulWidget {
  final String ward;
  final bool isPublic;
  final String mudhumeniId;
  final VoidCallback onAsked;

  const _AskTab({
    required this.ward,
    required this.isPublic,
    this.mudhumeniId = '',
    required this.onAsked,
  });

  @override
  State<_AskTab> createState() => _AskTabState();
}

class _AskTabState extends State<_AskTab> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;
    final q = QaQuestion(
      authorId: user?.userId ?? '',
      authorName: user?.fullName ?? '',
      ward: widget.ward,
      targetMudhumeniId: widget.mudhumeniId,
      isPublic: widget.isPublic,
      question: _ctrl.text.trim(),
      answer: '',
      answeredBy: '',
      answeredByMudhumeni: false,
      upvotes: 0,
      madePublic: false,
      createdAt: DateTime.now().toIso8601String(),
      answeredAt: '',
    );
    await MudhumeniDatabaseService.saveQuestion(q);
    _ctrl.clear();
    setState(() => _saving = false);
    widget.onAsked();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isPublic
                        ? 'Public questions are visible to all farmers in your ward.'
                        : 'Private questions go directly to your Mudhumeni only.',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Your Question *',
              alignLabelWithHint: true,
              hintText: widget.isPublic
                  ? 'e.g. Why are my maize leaves curling?'
                  : 'Ask your Mudhumeni a private question...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.help_outline, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
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
              label: Text(_saving ? 'Submitting...' : 'Submit Question',
                  style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}