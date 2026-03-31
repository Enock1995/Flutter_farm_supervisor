// lib/screens/vet/farmer_vet_network_screen.dart
// Developed by Sir Enocks Cor Technologies
// Farmer's main vet services hub

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/vet_model.dart';
import '../../services/vet_database_service.dart';

class FarmerVetNetworkScreen extends StatefulWidget {
  const FarmerVetNetworkScreen({super.key});

  @override
  State<FarmerVetNetworkScreen> createState() => _FarmerVetNetworkScreenState();
}

class _FarmerVetNetworkScreenState extends State<FarmerVetNetworkScreen> {
  List<VetProfile> _vetsInMyArea = [];
  List<VetKnowledgePost> _urgentAlerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      // Load vets in farmer's district
      final vets = await VetDatabaseService.getVerifiedVetsByDistrict(user.district);
      
      // Load urgent alerts
      final alerts = await VetDatabaseService.getUrgentPosts(user.district);

      if (mounted) {
        setState(() {
          _vetsInMyArea = vets;
          _urgentAlerts = alerts;
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
        title: const Text('Veterinary Services'),
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
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome banner
                  _buildWelcomeBanner(user?.fullName ?? 'Farmer'),

                  const SizedBox(height: 20),

                  // Urgent alerts
                  if (_urgentAlerts.isNotEmpty) ...[
                    _buildUrgentAlerts(),
                    const SizedBox(height: 20),
                  ],

                  // Quick actions
                  _buildQuickActions(),

                  const SizedBox(height: 20),

                  // Vets in my area
                  _buildVetsSection(),

                  const SizedBox(height: 20),

                  // Additional resources
                  _buildResourcesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeBanner(String name) {
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
              const Icon(Icons.medical_services, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hello, $name!',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Connect with professional veterinary officers in your area for expert animal health care.',
            style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text('Urgent Alerts', style: AppTextStyles.heading3),
          ],
        ),
        const SizedBox(height: 12),
        ...(_urgentAlerts.take(3).map((alert) => _buildAlertCard(alert))),
        if (_urgentAlerts.length > 3)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/vet-knowledge');
            },
            child: const Text('View All Alerts'),
          ),
      ],
    );
  }

  Widget _buildAlertCard(VetKnowledgePost alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            alert.postTypeEnum.emoji == '🦠' ? Icons.coronavirus : Icons.warning,
            color: AppColors.error,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${alert.authorName} • ${alert.animalTypeEnum.label}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.error),
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
              icon: Icons.question_answer,
              title: 'Ask Question',
              subtitle: 'Get expert advice',
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/vet-qa');
              },
            ),
            _buildActionCard(
              icon: Icons.library_books,
              title: 'Knowledge',
              subtitle: 'Browse articles',
              color: Colors.orange,
              onTap: () {
                Navigator.pushNamed(context, '/vet-knowledge');
              },
            ),
            _buildActionCard(
              icon: Icons.report_problem,
              title: 'Report Issue',
              subtitle: 'Sick animal?',
              color: Colors.red,
              onTap: () {
                _showComingSoon('Disease Reporting');
              },
            ),
            _buildActionCard(
              icon: Icons.phone_in_talk,
              title: 'Emergency',
              subtitle: 'Urgent help',
              color: Colors.purple,
              onTap: () {
                _showEmergencyContacts();
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
    required String subtitle,
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

  Widget _buildVetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vets in My Area', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        if (_vetsInMyArea.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.medical_services_outlined,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    'No vets registered in your area yet',
                    style: AppTextStyles.body.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_vetsInMyArea.map((vet) => _buildVetCard(vet))),
      ],
    );
  }

  Widget _buildVetCard(VetProfile vet) {
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
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                child: Text(
                  vet.fullName[0].toUpperCase(),
                  style: AppTextStyles.heading3.copyWith(
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vet.fullName, style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 4),
                    Text(
                      vet.specializationEnum.label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${vet.yearsExperience} yrs',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(vet.qualification, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Serves: ${vet.wards}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _callVet(vet);
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _consultVet(vet);
                  },
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Consult'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resources', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        _buildResourceCard(
          icon: Icons.vaccines,
          title: 'Vaccination Schedule',
          subtitle: 'Track animal vaccinations',
          onTap: () => _showComingSoon('Vaccination Schedule'),
        ),
        const SizedBox(height: 8),
        _buildResourceCard(
          icon: Icons.health_and_safety,
          title: 'Animal Health Records',
          subtitle: 'View health history',
          onTap: () => _showComingSoon('Health Records'),
        ),
      ],
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  void _callVet(VetProfile vet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Call ${vet.fullName}'),
        content: Text('Phone: ${vet.phone}\n\nThis will open your phone dialer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // In production: launch phone dialer
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _consultVet(VetProfile vet) {
    // Navigate to private consultation
    Navigator.pushNamed(
      context,
      '/vet-qa',
      arguments: {'vetId': vet.userId, 'vetName': vet.fullName},
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: const Text(
          'Emergency Vet Hotline:\n0800 VET HELP\n\n'
          'Zimbabwe Veterinary Association:\n+263 4 123 456',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}