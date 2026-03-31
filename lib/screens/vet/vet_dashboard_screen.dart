// lib/screens/vet/vet_dashboard_screen.dart
// Developed by Sir Enocks Cor Technologies
// Veterinary Officer Dashboard

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/vet_model.dart';
import '../../services/vet_database_service.dart';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  VetProfile? _myProfile;
  List<VetQuestion> _pendingQuestions = [];
  List<VetVisit> _upcomingVisits = [];
  bool _loading = true;

  int _pendingQuestionsCount = 0;
  int _urgentQuestionsCount = 0;
  int _todayVisitsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      // Load vet profile
      final profile = await VetDatabaseService.getProfileByUserId(user.userId);
      
      if (profile == null) {
        // Vet not yet approved
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // Load pending private questions
      final questions = await VetDatabaseService.getPrivateQuestionsForVet(user.userId);
      final unanswered = questions.where((q) => q.answer.isEmpty).toList();
      final urgent = unanswered.where((q) => q.urgency == 'urgent').toList();

      // Load visits
      final visits = await VetDatabaseService.getVisitsByVet(user.userId);
      final today = DateTime.now();
      final todayVisits = visits.where((v) {
        if (v.confirmedDate.isEmpty) return false;
        try {
          final visitDate = DateTime.parse(v.confirmedDate);
          return visitDate.year == today.year &&
                 visitDate.month == today.month &&
                 visitDate.day == today.day;
        } catch (_) {
          return false;
        }
      }).toList();

      if (mounted) {
        setState(() {
          _myProfile = profile;
          _pendingQuestions = unanswered;
          _upcomingVisits = visits.where((v) => v.status != 'completed').take(5).toList();
          _pendingQuestionsCount = unanswered.length;
          _urgentQuestionsCount = urgent.length;
          _todayVisitsCount = todayVisits.length;
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
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vet Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myProfile == null
              ? _buildNotApprovedView()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Welcome section
                      _buildWelcomeSection(user?.fullName ?? 'Vet'),

                      const SizedBox(height: 20),

                      // Statistics cards
                      _buildStatistics(),

                      const SizedBox(height: 20),

                      // Quick actions
                      _buildQuickActions(),

                      const SizedBox(height: 20),

                      // Pending questions
                      if (_pendingQuestions.isNotEmpty) ...[
                        _buildPendingQuestions(),
                        const SizedBox(height: 20),
                      ],

                      // Upcoming visits
                      if (_upcomingVisits.isNotEmpty) ...[
                        _buildUpcomingVisits(),
                        const SizedBox(height: 20),
                      ],

                      // Service area info
                      _buildServiceAreaInfo(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNotApprovedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'Application Pending',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your veterinary officer application is being reviewed by admin. '
              'You will be notified once approved.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.medical_services, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. $name',
                      style: AppTextStyles.heading3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _myProfile?.specializationEnum.label ?? 'Veterinary Officer',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Service Area: ${_myProfile?.district ?? ''}, ${_myProfile?.wards ?? ''}',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.question_answer,
                count: _pendingQuestionsCount,
                label: 'Pending Questions',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.priority_high,
                count: _urgentQuestionsCount,
                label: 'Urgent',
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.event,
                count: _todayVisitsCount,
                label: 'Today\'s Visits',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_month,
                count: _upcomingVisits.length,
                label: 'Upcoming',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: AppTextStyles.heading2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              icon: Icons.article,
              title: 'Post Article',
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.pushNamed(context, '/vet-knowledge');
              },
            ),
            _buildActionCard(
              icon: Icons.question_answer,
              title: 'Answer Q&A',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/vet-qa');
              },
            ),
            _buildActionCard(
              icon: Icons.calendar_today,
              title: 'View Schedule',
              color: Colors.orange,
              onTap: () {
                _showComingSoon('Visit Schedule');
              },
            ),
            _buildActionCard(
              icon: Icons.report,
              title: 'Disease Reports',
              color: Colors.red,
              onTap: () {
                _showComingSoon('Disease Reports');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pending Questions', style: AppTextStyles.heading3),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/vet-qa');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_pendingQuestions.take(3).map((q) => _buildQuestionCard(q))),
      ],
    );
  }

  Widget _buildQuestionCard(VetQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                question.animalTypeEnum.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.authorName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
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
          Text(
            question.question,
            style: AppTextStyles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (question.symptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Symptoms: ${question.symptoms}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingVisits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Visits', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        ...(_upcomingVisits.take(3).map((v) => _buildVisitCard(v))),
      ],
    );
  }

  Widget _buildVisitCard(VetVisit visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: visit.statusEnum == VisitStatus.confirmed
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: visit.statusEnum == VisitStatus.confirmed
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.farmerName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${visit.animalTypeEnum.label} - ${visit.issueDescription}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  visit.confirmedDate.isNotEmpty
                      ? visit.confirmedDate.split('T')[0]
                      : visit.preferredDate.split('T')[0],
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            visit.statusEnum.label,
            style: AppTextStyles.caption.copyWith(
              color: visit.statusEnum == VisitStatus.confirmed
                  ? Colors.green
                  : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceAreaInfo() {
    if (_myProfile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Service Area', style: AppTextStyles.heading4),
          const Divider(height: 24),
          _buildInfoRow('Registration', _myProfile!.registrationNumber),
          _buildInfoRow('Qualification', _myProfile!.qualification),
          _buildInfoRow('Specialization', _myProfile!.specializationEnum.label),
          _buildInfoRow('Experience', '${_myProfile!.yearsExperience} years'),
          _buildInfoRow('District', _myProfile!.district),
          _buildInfoRow('Wards', _myProfile!.wards),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }
}