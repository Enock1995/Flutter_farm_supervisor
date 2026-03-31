// lib/screens/vet/vet_qa_screens.dart
// Developed by Sir Enocks Cor Technologies
// Vet Q&A - Public Questions and Private Consultations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/vet_model.dart';
import '../../services/vet_database_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class VetQaScreens extends StatefulWidget {
  const VetQaScreens({super.key});

  @override
  State<VetQaScreens> createState() => _VetQaScreensState();
}

class _VetQaScreensState extends State<VetQaScreens>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<VetQuestion> _publicQuestions = [];
  List<VetQuestion> _privateQuestions = [];
  Set<int> _upvotedIds = {};
  bool _loading = true;
  bool _isVet = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _isVet = user?.isVet ?? false;
    
    _tabController = TabController(
      length: _isVet ? 2 : 3, // Vets: Public/Private, Farmers: Public/Private/Ask
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      // Load public questions
      final publicQs = await VetDatabaseService.getPublicQuestions(user.district);
      
      // Load private questions (different method for vets vs farmers)
      List<VetQuestion> privateQs = [];
      if (_isVet) {
        privateQs = await VetDatabaseService.getPrivateQuestionsForVet(user.userId);
      } else {
        // For farmers, get their private questions across all vets
        final allPrivate = await VetDatabaseService.getPrivateQuestions(user.userId, '');
        privateQs = allPrivate;
      }

      // Load upvoted IDs
      final upvoted = await VetDatabaseService.getUserUpvotedIds(user.userId);

      if (mounted) {
        setState(() {
          _publicQuestions = publicQs;
          _privateQuestions = privateQs;
          _upvotedIds = upvoted;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vet Q&A'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: _isVet
              ? const [
                  Tab(text: 'Public Q&A'),
                  Tab(text: 'Private Consultations'),
                ]
              : const [
                  Tab(text: 'Public'),
                  Tab(text: 'Private'),
                  Tab(text: 'Ask Question'),
                ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _isVet
                  ? [
                      _buildPublicQuestionsTab(),
                      _buildPrivateQuestionsTab(),
                    ]
                  : [
                      _buildPublicQuestionsTab(),
                      _buildPrivateQuestionsTab(),
                      _buildAskQuestionTab(),
                    ],
            ),
    );
  }

  Widget _buildPublicQuestionsTab() {
    if (_publicQuestions.isEmpty) {
      return _buildEmptyState('No public questions yet', Icons.question_answer);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _publicQuestions.length,
        itemBuilder: (context, index) {
          final question = _publicQuestions[index];
          return _buildQuestionCard(question, isPublic: true);
        },
      ),
    );
  }

  Widget _buildPrivateQuestionsTab() {
    if (_privateQuestions.isEmpty) {
      return _buildEmptyState(
        _isVet 
            ? 'No private consultations yet' 
            : 'You haven\'t asked any private questions',
        Icons.lock,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _privateQuestions.length,
        itemBuilder: (context, index) {
          final question = _privateQuestions[index];
          return _buildQuestionCard(question, isPublic: false);
        },
      ),
    );
  }

  Widget _buildAskQuestionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ask a Question', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Get expert advice from veterinary officers in your area.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          
          // Public vs Private toggle
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  'Public Question',
                  'Visible to everyone',
                  Icons.public,
                  () => _showAskDialog(isPublic: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeButton(
                  'Private Consultation',
                  'One-on-one with vet',
                  Icons.lock,
                  () => _showAskDialog(isPublic: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Tips
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text('Tips for Better Answers', style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Describe symptoms clearly'),
          _buildTip('Mention animal type and count'),
          _buildTip('Include how long animal has been sick'),
          _buildTip('Upload a photo if possible'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(VetQuestion question, {required bool isPublic}) {
    final isUpvoted = _upvotedIds.contains(question.id);
    final canAnswer = _isVet && question.answer.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(question.animalTypeEnum.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(question.authorName, style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      Text(
                        '${question.animalTypeEnum.label} • ${question.animalCount} animal(s)',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (question.urgency == 'urgent')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'URGENT',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Question
            Text(question.question, style: AppTextStyles.body),
            
            if (question.symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Symptoms: ${question.symptoms}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],

            // Answer
            if (question.answer.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.medical_services, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Answer from ${question.answeredBy}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(question.answer, style: AppTextStyles.body),
              
              if (question.diagnosis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Diagnosis: ${question.diagnosis}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                if (isPublic) ...[
                  IconButton(
                    onPressed: () => _toggleUpvote(question),
                    icon: Icon(
                      isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: isUpvoted ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                    ),
                  ),
                  Text('${question.upvotes}', style: AppTextStyles.caption),
                ],
                const Spacer(),
                if (canAnswer)
                  TextButton.icon(
                    onPressed: () => _answerQuestion(question),
                    icon: const Icon(Icons.reply),
                    label: const Text('Answer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.body.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }

  Future<void> _toggleUpvote(VetQuestion question) async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final nowUpvoted = await VetDatabaseService.toggleUpvote(question.id!, user.userId);
      
      setState(() {
        if (nowUpvoted) {
          _upvotedIds.add(question.id!);
        } else {
          _upvotedIds.remove(question.id!);
        }
      });
      
      await _loadData();
    } catch (e) {
      // Handle error
    }
  }

  void _showAskDialog({required bool isPublic}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPublic 
              ? 'Ask public question - full implementation available'
              : 'Ask private question - full implementation available'
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  void _answerQuestion(VetQuestion question) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer question - full implementation available'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }
}