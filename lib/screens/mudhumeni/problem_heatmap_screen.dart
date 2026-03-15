// lib/screens/mudhumeni/problem_heatmap_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/mudhumeni_model.dart';
import '../../services/mudhumeni_database_service.dart';
import '../farm_management/farm_management_shared_widgets.dart';

class ProblemHeatmapScreen extends StatefulWidget {
  const ProblemHeatmapScreen({super.key});

  @override
  State<ProblemHeatmapScreen> createState() =>
      _ProblemHeatmapScreenState();
}

class _ProblemHeatmapScreenState extends State<ProblemHeatmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<ProblemReport> _reports = [];
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
    final reports =
        await MudhumeniDatabaseService.getReportsByWard(_ward);
    setState(() { _reports = reports; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Problem Heatmap')),
      body: TabBarView(
        controller: _tabs,
        children: [
          _HeatmapTab(
            reports: _reports,
            loading: _loading,
            onRefresh: _load,
            onResolve: (id) async {
              await MudhumeniDatabaseService.resolveReport(id);
              _load();
            },
          ),
          _ReportProblemTab(
            ward: _ward,
            onReported: () {
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
          Tab(icon: Icon(Icons.bubble_chart_outlined), text: 'Heatmap'),
          Tab(icon: Icon(Icons.report_problem_outlined), text: 'Report Problem'),
        ],
      ),
    );
  }
}

// ── Heatmap tab ───────────────────────────────────────────
class _HeatmapTab extends StatelessWidget {
  final List<ProblemReport> reports;
  final bool loading;
  final VoidCallback onRefresh;
  final Function(int) onResolve;

  const _HeatmapTab({
    required this.reports,
    required this.loading,
    required this.onRefresh,
    required this.onResolve,
  });

  static const _typeColors = {
    'pest':    Color(0xFFE65100),
    'disease': Color(0xFFC62828),
    'weather': Color(0xFF0277BD),
    'other':   Color(0xFF558B2F),
  };
  static const _typeIcons = {
    'pest':    Icons.bug_report_outlined,
    'disease': Icons.coronavirus_outlined,
    'weather': Icons.thunderstorm_outlined,
    'other':   Icons.warning_amber_outlined,
  };
  static const _typeLabels = {
    'pest':    '🐛 Pest',
    'disease': '🦠 Disease',
    'weather': '⛈️ Weather',
    'other':   '⚠️ Other',
  };

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    // Group by type for summary
    final Map<String, int> counts = {};
    for (final r in reports) {
      counts[r.problemType] = (counts[r.problemType] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual heatmap summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bubble_chart_outlined,
                          color: Color(0xFF558B2F)),
                      const SizedBox(width: 8),
                      Text('Ward Problem Summary',
                          style: AppTextStyles.heading3),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (reports.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 48),
                          const SizedBox(height: 8),
                          Text('No active problems reported! 🎉',
                              style: AppTextStyles.body.copyWith(
                                  color: AppColors.success)),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: counts.entries.map((e) {
                        final color =
                            _typeColors[e.key] ?? AppColors.primary;
                        final label =
                            _typeLabels[e.key] ?? e.key;
                        final icon =
                            _typeIcons[e.key] ?? Icons.warning_outlined;
                        return _HeatBubble(
                          label: label,
                          count: e.value,
                          color: color,
                          icon: icon,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (reports.isNotEmpty) ...[
              Text('Active Reports (${reports.length})',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              ...reports.map((r) => _ReportCard(
                    report: r,
                    onResolve: () => onResolve(r.id!),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeatBubble extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _HeatBubble({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Size bubble by count (min 80, max 130)
    final size = (80.0 + (count * 10.0)).clamp(80.0, 130.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
          Text(
            label.replaceAll(RegExp(r'^[^\s]+\s'), ''), // strip emoji
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ProblemReport report;
  final VoidCallback onResolve;

  const _ReportCard({required this.report, required this.onResolve});

  static const _typeColors = {
    'pest':    Color(0xFFE65100),
    'disease': Color(0xFFC62828),
    'weather': Color(0xFF0277BD),
    'other':   Color(0xFF558B2F),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[report.problemType] ?? AppColors.primary;
    final date = DateTime.tryParse(report.createdAt);
    final dateStr =
        date != null ? DateFormat('dd MMM yyyy').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.problemType.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
              const Spacer(),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.description,
              style: AppTextStyles.body
                  .copyWith(fontWeight: FontWeight.w600)),
          if (report.cropAffected.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Crop: ${report.cropAffected}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(report.reporterName, style: AppTextStyles.caption),
              const SizedBox(width: 10),
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(report.ward, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 16),
              label: const Text('Mark Resolved',
                  style: TextStyle(color: AppColors.success, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report problem tab ────────────────────────────────────
class _ReportProblemTab extends StatefulWidget {
  final String ward;
  final VoidCallback onReported;
  const _ReportProblemTab(
      {required this.ward, required this.onReported});

  @override
  State<_ReportProblemTab> createState() => _ReportProblemTabState();
}

class _ReportProblemTabState extends State<_ReportProblemTab> {
  final _descCtrl = TextEditingController();
  final _cropCtrl = TextEditingController();
  String _problemType = 'pest';
  bool _saving = false;

  static const _green = Color(0xFF558B2F);
  static const _types = [
    ('pest',    '🐛 Pest',    Color(0xFFE65100)),
    ('disease', '🦠 Disease', Color(0xFFC62828)),
    ('weather', '⛈️ Weather', Color(0xFF0277BD)),
    ('other',   '⚠️ Other',   Color(0xFF558B2F)),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _cropCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the problem.')),
      );
      return;
    }
    setState(() => _saving = true);
    final user = context.read<AuthProvider>().user;
    final report = ProblemReport(
      reporterId: user?.userId ?? '',
      reporterName: user?.fullName ?? '',
      ward: widget.ward,
      district: user?.district ?? '',
      problemType: _problemType,
      description: _descCtrl.text.trim(),
      cropAffected: _cropCtrl.text.trim(),
      latitude: 0.0,
      longitude: 0.0,
      isResolved: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    await MudhumeniDatabaseService.saveProblemReport(report);
    setState(() => _saving = false);
    widget.onReported();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FarmSectionHeader(
            icon: Icons.report_problem_outlined,
            color: _green,
            title: 'Report a Problem',
            subtitle:
                'Help your mudhumeni identify problem hotspots in the ward.',
          ),
          const SizedBox(height: 20),

          Text('Problem Type', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _types.map((t) {
              final sel = _problemType == t.$1;
              return GestureDetector(
                onTap: () => setState(() => _problemType = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? t.$3 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? t.$3 : AppColors.divider),
                  ),
                  child: Text(t.$2,
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              sel ? Colors.white : AppColors.textPrimary,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe the Problem *',
              alignLabelWithHint: true,
              hintText:
                  'e.g. Fall armyworm outbreak affecting most farms in the area...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 60),
                child: Icon(Icons.description_outlined, color: _green),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _cropCtrl,
            decoration: const InputDecoration(
              labelText: 'Crop Affected (Optional)',
              prefixIcon: Icon(Icons.eco_outlined, color: _green),
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
              label: Text(
                _saving ? 'Submitting...' : 'Submit Report',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}