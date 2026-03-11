// lib/screens/ai/ai_diagnosis_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';
import 'ai_shared_widgets.dart';

class AiDiagnosisScreen extends StatefulWidget {
  const AiDiagnosisScreen({super.key});

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _symptomsCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _subjectType = 'crop';
  File? _photo;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.userId ?? '';
      context.read<AiProvider>().loadDiagnosisHistory(userId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _symptomsCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 1024);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _runDiagnosis() async {
    if (_symptomsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the symptoms first.')),
      );
      return;
    }
    final userId = context.read<AuthProvider>().user?.userId ?? '';
    await context.read<AiProvider>().runDiagnosis(
          userId: userId,
          symptoms: _symptomsCtrl.text.trim(),
          subjectType: _subjectType,
          cropOrAnimalName: _nameCtrl.text.trim().isNotEmpty
              ? _nameCtrl.text.trim()
              : null,
          photo: _photo,
        );
    if (context.read<AiProvider>().state == AiState.success) {
      context.read<AiProvider>().loadDiagnosisHistory(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnosis'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Diagnose'), Tab(text: 'History')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DiagnoseTab(
            symptomsCtrl: _symptomsCtrl,
            nameCtrl: _nameCtrl,
            subjectType: _subjectType,
            photo: _photo,
            onSubjectChanged: (v) => setState(() => _subjectType = v!),
            onPickPhoto: _pickPhoto,
            onRemovePhoto: () => setState(() => _photo = null),
            onSubmit: _runDiagnosis,
          ),
          _HistoryTab(tabs: _tabs),
        ],
      ),
    );
  }
}

class _DiagnoseTab extends StatelessWidget {
  final TextEditingController symptomsCtrl;
  final TextEditingController nameCtrl;
  final String subjectType;
  final File? photo;
  final ValueChanged<String?> onSubjectChanged;
  final Function(ImageSource) onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onSubmit;

  const _DiagnoseTab({
    required this.symptomsCtrl,
    required this.nameCtrl,
    required this.subjectType,
    required this.photo,
    required this.onSubjectChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        final isLoading = ai.state == AiState.loading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AiHeaderCard(
                icon: Icons.medical_services_outlined,
                color: const Color(0xFF7B2D8B),
                title: 'AI Crop & Livestock Diagnosis',
                subtitle:
                    'Describe symptoms and get an instant AI-powered diagnosis with treatment advice.',
              ),
              const SizedBox(height: 20),

              Text('What are you diagnosing?', style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TypeChip(
                    label: '🌱 Crop',
                    selected: subjectType == 'crop',
                    onTap: () => onSubjectChanged('crop'),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: '🐄 Livestock',
                    selected: subjectType == 'livestock',
                    onTap: () => onSubjectChanged('livestock'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: subjectType == 'crop'
                      ? 'Crop name (e.g. Maize, Tomato)'
                      : 'Animal type (e.g. Cattle, Goat)',
                  prefixIcon: Icon(
                    subjectType == 'crop'
                        ? Icons.eco_outlined
                        : Icons.pets_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: symptomsCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe the symptoms *',
                  hintText:
                      'e.g. Leaves turning yellow from the edges, wilting in the afternoon...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description_outlined,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Attach a Photo (Optional)',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (photo != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(photo!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onRemovePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _PhotoButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: () => onPickPhoto(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PhotoButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: () => onPickPhoto(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2D8B),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search, color: Colors.white),
                  label: Text(
                    isLoading ? 'Analysing...' : 'Run AI Diagnosis',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (ai.state == AiState.error)
                AiErrorCard(message: ai.errorMessage),

              if (ai.state == AiState.success &&
                  ai.diagnosisResult != null) ...[
                const Divider(height: 32),
                _DiagnosisResultCard(result: ai.diagnosisResult!),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final TabController tabs;
  const _HistoryTab({required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        final history = ai.diagnosisHistory;
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No diagnoses yet.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => tabs.animateTo(0),
                  child: const Text('Run your first diagnosis'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, i) {
            final h = history[i];
            final treatment =
                List<String>.from(jsonDecode(h['treatment'] ?? '[]'));
            final date = DateTime.parse(h['created_at'] as String);
            final severity = h['severity'] as String? ?? '';
            final severityColor = _severityColor(severity);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(h['diagnosis'] as String? ?? '',
                              style: AppTextStyles.heading3),
                        ),
                        AiBadge(label: severity, color: severityColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${h['subject_type']} • ${h['crop_or_animal']} • ${DateFormat('dd MMM yyyy').format(date)}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    Text(h['symptoms'] as String? ?? '',
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (treatment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Treatment: ${treatment.first}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.success)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'mild':     return AppColors.success;
      case 'moderate': return AppColors.warning;
      case 'severe':   return AppColors.error;
      case 'critical': return const Color(0xFFB71C1C);
      default:         return AppColors.textSecondary;
    }
  }
}

class _DiagnosisResultCard extends StatelessWidget {
  final DiagnosisResult result;
  const _DiagnosisResultCard({required this.result});

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'mild':     return AppColors.success;
      case 'moderate': return AppColors.warning;
      case 'severe':   return AppColors.error;
      case 'critical': return const Color(0xFFB71C1C);
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(result.severity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diagnosis Result', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7B2D8B).withOpacity(0.08),
                const Color(0xFF7B2D8B).withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: const Color(0xFF7B2D8B).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(result.diagnosis,
                        style: AppTextStyles.heading2
                            .copyWith(color: const Color(0xFF7B2D8B))),
                  ),
                  AiBadge(label: result.severity, color: severityColor),
                ],
              ),
              const SizedBox(height: 4),
              AiBadge(
                  label: 'Confidence: ${result.confidence}',
                  color: AppColors.info),
              const SizedBox(height: 10),
              Text(result.description, style: AppTextStyles.body),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AiSectionCard(
          icon: Icons.healing_outlined,
          title: 'Treatment Steps',
          color: AppColors.success,
          items: result.treatment,
        ),
        const SizedBox(height: 12),
        AiSectionCard(
          icon: Icons.shield_outlined,
          title: 'Prevention Tips',
          color: AppColors.info,
          items: result.prevention,
        ),
        if (result.localProducts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store_outlined,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available in Zimbabwe',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(result.localProducts,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (result.seeExpert) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: AppColors.error),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This condition may be serious. Consult an AGRITEX officer or veterinarian.',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Private widgets (this file only) ─────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7B2D8B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF7B2D8B) : AppColors.divider,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}