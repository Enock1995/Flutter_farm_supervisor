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
  bool _loading = true;
  String _sort = 'newest'; // 'newest' | 'upvotes' | 'unanswered'

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
    final questions =
        await MudhumeniDatabaseService.getPublicQuestions(_ward);
    setState(() { _questions = questions; _loading = false; });
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

  @override
  Widget build(BuildContext context) {
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
            loading: _loading,
            sort: _sort,
            onSortChanged: (v) => setState(() => _sort = v),
            onRefresh: _load,
            onUpvote: (id) async {
              await MudhumeniDatabaseService.upvoteQuestion(id);
              _load();
            },
            onAnswer: (id, ans, by) async {
              await MudhumeniDatabaseService.answerQuestion(
                  id, ans, by, false);
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

  // Stub mudhumeni ID — in production this comes from the linked mudhumeni
  static const _stubMudhumeniId = 'mudhumeni_001';

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
    final questions = await MudhumeniDatabaseService.getPrivateQuestions(
        user?.userId ?? '', _stubMudhumeniId);
    setState(() { _questions = questions; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Q&A')),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PrivateThreadTab(
            questions: _questions,
            loading: _loading,
            onRefresh: _load,
            onMakePublic: (id) async {
              await MudhumeniDatabaseService.makePublic(id);
              _load();
            },
          ),
          _AskTab(
            ward: context.read<AuthProvider>().user?.district ?? '',
            isPublic: false,
            mudhumeniId: _stubMudhumeniId,
            onAsked: () {
              _load();
              _tabs.animateTo(0);
            },
          ),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        tabs: const [Tab(text: 'Thread'), Tab(text: 'Ask')],
      ),
    );
  }
}

// ── Shared: Questions list tab ────────────────────────────
class _QuestionsTab extends StatelessWidget {
  final List<QaQuestion> questions;
  final bool loading;
  final String sort;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onRefresh;
  final Function(int) onUpvote;
  final Function(int, String, String) onAnswer;

  const _QuestionsTab({
    required this.questions,
    required this.loading,
    required this.sort,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onUpvote,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Sort chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text('Sort: ', style: AppTextStyles.bodySmall),
              const SizedBox(width: 6),
              for (final s in [
                ('newest', 'Newest'),
                ('upvotes', 'Most Voted'),
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
                    onUpvote: () => onUpvote(questions[i].id!),
                    onAnswer: (ans, by) =>
                        onAnswer(questions[i].id!, ans, by),
                  ),
                ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QaQuestion q;
  final VoidCallback onUpvote;
  final Function(String, String) onAnswer;

  const _QuestionCard(
      {required this.q, required this.onUpvote, required this.onAnswer});

  void _showAnswerDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Answer this question'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
              hintText: 'Type your answer here...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onAnswer(ctrl.text.trim(), 'Me');
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
                        const Icon(Icons.verified,
                            color: AppColors.success, size: 14),
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
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: onUpvote,
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          size: 16, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text('${q.upvotes} agree',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.info)),
                    ],
                  ),
                ),
                const Spacer(),
                if (!isAnswered)
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
  final VoidCallback onRefresh;
  final Function(int) onMakePublic;

  const _PrivateThreadTab({
    required this.questions,
    required this.loading,
    required this.onRefresh,
    required this.onMakePublic,
  });

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
            Text('No private questions yet.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, i) {
        final q = questions[i];
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
                  ],
                ),
                const SizedBox(height: 6),
                Text(q.question,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                if (q.answer.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(q.answer,
                        style: AppTextStyles.bodySmall),
                  ),
                  if (!q.madePublic) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => onMakePublic(q.id!),
                      icon: const Icon(Icons.public_outlined,
                          size: 14),
                      label: const Text('Make Public',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Awaiting reply from mudhumeni...',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint)),
                  ),
              ],
            ),
          ),
        );
      },
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
                        : 'Private questions go directly to your mudhumeni only.',
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
                  : 'Ask your mudhumeni a private question...',
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