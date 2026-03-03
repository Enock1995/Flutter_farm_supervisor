// lib/screens/pest_disease/pest_disease_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pest_disease_provider.dart';
import '../../services/pest_disease_service.dart';

class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() =>
      _PestDiseaseScreenState();
}

class _PestDiseaseScreenState
    extends State<PestDiseaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<PestDiseaseProvider>()
            .loadAlerts(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pest & Disease'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🔍 Identify & Treat'),
            Tab(text: '⚠️ My Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _IdentifyTab(searchCtrl: _searchCtrl),
          const _AlertsTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — IDENTIFY & TREAT
// =============================================================================

class _IdentifyTab extends StatelessWidget {
  final TextEditingController searchCtrl;
  const _IdentifyTab({required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return Consumer<PestDiseaseProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 12, 16, 0),
              child: TextField(
                controller: searchCtrl,
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText:
                      'Search pest, disease, or symptom…',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.primaryLight),
                  suffixIcon:
                      provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                  Icons.clear),
                              onPressed: () {
                                searchCtrl.clear();
                                provider.setSearch('');
                              },
                            )
                          : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                          vertical: 0),
                ),
              ),
            ),

            // Crop filter chips
            if (provider.searchQuery.isEmpty) ...[
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount:
                      PestDiseaseService.allCrops.length,
                  itemBuilder: (_, i) {
                    final crop =
                        PestDiseaseService.allCrops[i];
                    final selected =
                        provider.selectedCrop == crop;
                    return GestureDetector(
                      onTap: () =>
                          provider.setSelectedCrop(crop),
                      child: AnimatedContainer(
                        duration: const Duration(
                            milliseconds: 180),
                        margin: const EdgeInsets.only(
                            right: 8),
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.error
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.error
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          crop,
                          style: AppTextStyles.caption
                              .copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Type filter
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${provider.filteredPests.length} result${provider.filteredPests.length == 1 ? '' : 's'}',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint),
                  ),
                  const Spacer(),
                  ...[
                    ('All', 'All'),
                    ('🐛 Pests', 'pest'),
                    ('🍄 Diseases', 'disease'),
                  ].map((t) => GestureDetector(
                        onTap: () =>
                            provider.setTypeFilter(t.$2),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 150),
                          margin: const EdgeInsets.only(
                              left: 6),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4),
                          decoration: BoxDecoration(
                            color: provider.typeFilter ==
                                    t.$2
                                ? AppColors.primaryLight
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  provider.typeFilter ==
                                          t.$2
                                      ? AppColors
                                          .primaryLight
                                      : AppColors.divider,
                            ),
                          ),
                          child: Text(t.$1,
                              style: AppTextStyles.caption
                                  .copyWith(
                                color:
                                    provider.typeFilter ==
                                            t.$2
                                        ? Colors.white
                                        : AppColors
                                            .textPrimary,
                                fontWeight:
                                    provider.typeFilter ==
                                            t.$2
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                              )),
                        ),
                      )),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: provider.filteredPests.isEmpty
                  ? _EmptyResults(
                      onClear: () {
                        searchCtrl.clear();
                        provider.clearFilters();
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 4, 16, 80),
                      itemCount:
                          provider.filteredPests.length,
                      itemBuilder: (_, i) =>
                          _PestCard(
                        pest: provider.filteredPests[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PestDetailScreen(
                              pest: provider
                                  .filteredPests[i],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// TAB 2 — MY ALERTS
// =============================================================================

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PestDiseaseProvider>(
      builder: (context, provider, _) {
        final active = provider.activeAlerts;
        final resolved = provider.alerts
            .where((a) => a.isResolved)
            .toList();

        return Stack(
          children: [
            if (provider.alerts.isEmpty)
              _EmptyAlerts()
            else
              ListView(
                padding: const EdgeInsets.fromLTRB(
                    16, 12, 16, 100),
                children: [
                  // Active alerts
                  if (active.isNotEmpty) ...[
                    _SectionHeader(
                      label:
                          '🔴 Active Outbreaks (${active.length})',
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 8),
                    ...active.map((a) => _AlertCard(
                          alert: a,
                          provider: provider,
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Resolved
                  if (resolved.isNotEmpty) ...[
                    _SectionHeader(
                      label:
                          '✅ Resolved (${resolved.length})',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    ...resolved
                        .take(5)
                        .map((a) => _AlertCard(
                              alert: a,
                              provider: provider,
                            )),
                  ],
                ],
              ),

            // FAB — Report new outbreak
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () =>
                    _showReportSheet(context),
                backgroundColor: AppColors.error,
                icon: const Icon(Icons.add_alert,
                    color: Colors.white),
                label: const Text('Report Outbreak',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReportAlertSheet(),
    );
  }
}

// =============================================================================
// PEST CARD
// =============================================================================

class _PestCard extends StatelessWidget {
  final PestOrDisease pest;
  final VoidCallback onTap;
  const _PestCard(
      {required this.pest, required this.onTap});

  Color get _severityBorder {
    switch (pest.severity) {
      case 'critical': return AppColors.error;
      case 'high':     return AppColors.warning;
      case 'medium':   return AppColors.info;
      default:         return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
                color: _severityBorder, width: 4),
            top: BorderSide(color: AppColors.divider),
            right:
                BorderSide(color: AppColors.divider),
            bottom:
                BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Text(pest.imageEmoji ?? pest.typeEmoji,
                style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(pest.name,
                            style: AppTextStyles.body
                                .copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w700)),
                      ),
                      Text(
                        '${pest.severityEmoji} ${pest.severityLabel}',
                        style:
                            AppTextStyles.caption.copyWith(
                          color: _severityBorder,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (pest.localName.isNotEmpty)
                    Text(pest.localName,
                        style: AppTextStyles.caption
                            .copyWith(
                                color:
                                    AppColors.textHint)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2),
                        decoration: BoxDecoration(
                          color: pest.type == 'pest'
                              ? AppColors.warning
                                  .withOpacity(0.15)
                              : AppColors.info
                                  .withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${pest.typeEmoji} ${pest.typeLabel}',
                          style: AppTextStyles.caption
                              .copyWith(
                            color: pest.type == 'pest'
                                ? AppColors.warning
                                : AppColors.info,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pest.affectedCrops.take(3).join(', '),
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: AppColors
                                      .textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pest.treatments.length} treatment${pest.treatments.length == 1 ? '' : 's'} available  →',
                    style: AppTextStyles.caption
                        .copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
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

// =============================================================================
// ALERT CARD
// =============================================================================

class _AlertCard extends StatelessWidget {
  final FarmAlert alert;
  final PestDiseaseProvider provider;
  const _AlertCard(
      {required this.alert, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Colors.white),
      ),
      onDismissed: (_) =>
          provider.deleteAlert(alert.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: alert.isResolved
              ? AppColors.background
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isResolved
                ? AppColors.divider
                : AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(alert.severityEmoji,
                    style:
                        const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(alert.pestDiseaseName,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration: alert.isResolved
                              ? TextDecoration.lineThrough
                              : null,
                          color: alert.isResolved
                              ? AppColors.textHint
                              : AppColors.textPrimary)),
                ),
                Text(alert.daysAgo,
                    style: AppTextStyles.caption
                        .copyWith(
                            color: AppColors.textHint)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.eco,
                    size: 13,
                    color: AppColors.primaryLight),
                const SizedBox(width: 4),
                Text(alert.affectedCrop,
                    style: AppTextStyles.caption
                        .copyWith(
                            color: AppColors
                                .primaryLight)),
                if (alert.plotOrField != null) ...[
                  const Text(' • ',
                      style: TextStyle(
                          color: AppColors.textHint)),
                  Text(alert.plotOrField!,
                      style: AppTextStyles.caption
                          .copyWith(
                              color:
                                  AppColors.textHint)),
                ],
              ],
            ),
            if (alert.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(alert.notes,
                  style: AppTextStyles.bodySmall
                      .copyWith(
                          color:
                              AppColors.textSecondary)),
            ],
            if (!alert.isResolved) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final pest =
                            PestDiseaseService.getById(
                                alert.pestDiseaseId);
                        if (pest != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PestDetailScreen(
                                      pest: pest),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                          Icons.medical_information,
                          size: 16),
                      label:
                          const Text('Treatment Guide'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.primaryLight,
                        side: const BorderSide(
                            color: AppColors.primaryLight),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => provider
                          .resolveAlert(alert.id),
                      icon: const Icon(Icons.check,
                          size: 16,
                          color: Colors.white),
                      label: const Text(
                          'Mark Resolved',
                          style: TextStyle(
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.success,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DETAIL SCREEN
// =============================================================================

class PestDetailScreen extends StatelessWidget {
  final PestOrDisease pest;
  const PestDetailScreen({super.key, required this.pest});

  Color get _severityColor {
    switch (pest.severity) {
      case 'critical': return AppColors.error;
      case 'high':     return AppColors.warning;
      case 'medium':   return AppColors.info;
      default:         return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _severityColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Report outbreak from detail screen
              IconButton(
                icon: const Icon(Icons.add_alert,
                    color: Colors.white),
                tooltip: 'Report on my farm',
                onPressed: () =>
                    _showReportSheet(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _severityColor,
                      _severityColor.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 50, 20, 0),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,
                      children: [
                        Text(
                          pest.imageEmoji ??
                              pest.typeEmoji,
                          style: const TextStyle(
                              fontSize: 56),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(pest.name,
                                  style: AppTextStyles
                                      .heading2
                                      .copyWith(
                                          color: Colors
                                              .white)),
                              if (pest
                                  .localName.isNotEmpty)
                                Text(pest.localName,
                                    style: AppTextStyles
                                        .bodySmall
                                        .copyWith(
                                            color: Colors
                                                .white70)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _Badge(
                                    label:
                                        '${pest.typeEmoji} ${pest.typeLabel}',
                                    color: Colors.white24,
                                  ),
                                  const SizedBox(width: 6),
                                  _Badge(
                                    label:
                                        '${pest.severityEmoji} ${pest.severityLabel}',
                                    color: Colors.white24,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Affected crops
                  _Section(
                    title: '🌾 Affected Crops',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: pest.affectedCrops
                          .map((c) => Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryLight
                                          .withOpacity(
                                              0.1),
                                  borderRadius:
                                      BorderRadius.circular(
                                          8),
                                  border: Border.all(
                                      color: AppColors
                                          .primaryLight
                                          .withOpacity(
                                              0.3)),
                                ),
                                child: Text(c,
                                    style: AppTextStyles
                                        .caption
                                        .copyWith(
                                            color: AppColors
                                                .primaryLight)),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  _Section(
                    title: '📋 About',
                    child: Text(pest.description,
                        style: AppTextStyles.body
                            .copyWith(height: 1.6)),
                  ),
                  const SizedBox(height: 12),

                  // Symptoms
                  _Section(
                    title: '🔍 Symptoms to Look For',
                    child: Column(
                      children: pest.symptoms
                          .map((s) => _BulletPoint(
                              text: s,
                              color: AppColors.error))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Conditions
                  _Section(
                    title:
                        '🌡️ Conditions That Favour This',
                    child: Column(
                      children: pest.conditions
                          .map((s) => _BulletPoint(
                              text: s,
                              color: AppColors.warning))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Treatments
                  Text('💊 Treatment Options',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 10),
                  ...pest.treatments.map(
                      (t) => _TreatmentCard(t: t)),

                  const SizedBox(height: 12),

                  // Prevention
                  _Section(
                    title: '🛡️ Prevention',
                    color: AppColors.success
                        .withOpacity(0.06),
                    borderColor: AppColors.success
                        .withOpacity(0.3),
                    child: Column(
                      children: pest.prevention
                          .map((s) => _BulletPoint(
                              text: s,
                              color: AppColors.success))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportAlertSheet(
          preselectedPest: pest),
    );
  }
}

// =============================================================================
// TREATMENT CARD
// =============================================================================

class _TreatmentCard extends StatelessWidget {
  final TreatmentOption t;
  const _TreatmentCard({required this.t});

  Color get _typeColor {
    switch (t.type) {
      case 'chemical':   return AppColors.error;
      case 'biological': return AppColors.success;
      default:           return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _typeColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(t.typeEmoji,
                    style:
                        const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.productName,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _typeColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.type[0].toUpperCase() +
                        t.type.substring(1),
                    style: AppTextStyles.caption
                        .copyWith(
                            color: _typeColor,
                            fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (t.activeIngredient.isNotEmpty)
                  _DetailRow(
                      icon: '🧬',
                      label: 'Active ingredient',
                      value: t.activeIngredient),
                _DetailRow(
                    icon: '⚗️',
                    label: 'Dosage',
                    value: t.dosage),
                _DetailRow(
                    icon: '📅',
                    label: 'Frequency',
                    value: t.frequency),
                _DetailRow(
                    icon: '⏰',
                    label: 'When to apply',
                    value: t.timing),
                if (t.safetyInterval.isNotEmpty)
                  _DetailRow(
                      icon: '🌿',
                      label: 'Pre-harvest interval',
                      value: t.safetyInterval),
                if (t.safetyNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning
                          .withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.warning
                              .withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('⚠️ Safety Notes',
                            style: AppTextStyles.caption
                                .copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 4),
                        ...t.safetyNotes.map(
                          (n) => Padding(
                            padding:
                                const EdgeInsets.only(
                                    top: 2),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppColors
                                            .warning)),
                                Expanded(
                                    child: Text(n,
                                        style: AppTextStyles
                                            .caption)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REPORT ALERT SHEET
// =============================================================================

class _ReportAlertSheet extends StatefulWidget {
  final PestOrDisease? preselectedPest;
  const _ReportAlertSheet({this.preselectedPest});

  @override
  State<_ReportAlertSheet> createState() =>
      _ReportAlertSheetState();
}

class _ReportAlertSheetState
    extends State<_ReportAlertSheet> {
  PestOrDisease? _selectedPest;
  String _selectedCrop = '';
  String _severity = 'medium';
  final _notesCtrl = TextEditingController();
  final _plotCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _isSaving = false;
  List<PestOrDisease> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPest != null) {
      _selectedPest = widget.preselectedPest;
      _selectedCrop =
          widget.preselectedPest!.affectedCrops.first;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _plotCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    setState(() {
      _searchResults = q.isEmpty
          ? []
          : PestDiseaseService.search(q).take(5).toList();
    });
  }

  Future<void> _save() async {
    if (_selectedPest == null || _selectedCrop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select a pest/disease and crop.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<PestDiseaseProvider>().addAlert(
          userId: user.userId,
          pestDisease: _selectedPest!,
          affectedCrop: _selectedCrop,
          plotOrField: _plotCtrl.text.trim().isEmpty
              ? null
              : _plotCtrl.text.trim(),
          severity: _severity,
          notes: _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outbreak reported!'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Report Outbreak',
                style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              'Log a pest or disease sighting on your farm.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Pest search or selected
            if (_selectedPest == null) ...[
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  labelText: 'Search pest or disease *',
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.error),
                  border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: AppColors.divider),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _searchResults
                        .map((p) => ListTile(
                              leading: Text(
                                  p.imageEmoji ??
                                      p.typeEmoji,
                                  style: const TextStyle(
                                      fontSize: 20)),
                              title: Text(p.name,
                                  style:
                                      AppTextStyles.body),
                              subtitle: Text(
                                  p.affectedCrops
                                      .take(2)
                                      .join(', '),
                                  style: AppTextStyles
                                      .caption),
                              onTap: () {
                                setState(() {
                                  _selectedPest = p;
                                  _selectedCrop = p
                                      .affectedCrops
                                      .first;
                                  _searchResults = [];
                                  _searchCtrl.clear();
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                        _selectedPest!.imageEmoji ??
                            _selectedPest!.typeEmoji,
                        style:
                            const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_selectedPest!.name,
                          style: AppTextStyles.body
                              .copyWith(
                                  fontWeight:
                                      FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textHint),
                      onPressed: () => setState(
                          () => _selectedPest = null),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Affected crop
            if (_selectedPest != null) ...[
              Text('Affected Crop',
                  style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _selectedPest!.affectedCrops
                    .map((c) => GestureDetector(
                          onTap: () => setState(
                              () => _selectedCrop = c),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 150),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedCrop == c
                                  ? AppColors.primaryLight
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                      20),
                              border: Border.all(
                                  color:
                                      _selectedCrop == c
                                          ? AppColors
                                              .primaryLight
                                          : AppColors
                                              .divider),
                            ),
                            child: Text(c,
                                style: AppTextStyles
                                    .caption
                                    .copyWith(
                                  color:
                                      _selectedCrop == c
                                          ? Colors.white
                                          : AppColors
                                              .textPrimary,
                                  fontWeight:
                                      _selectedCrop == c
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                )),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Plot / field
            TextField(
              controller: _plotCtrl,
              decoration: InputDecoration(
                labelText: 'Plot or field (optional)',
                prefixIcon: const Icon(Icons.map_outlined,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),

            // Severity
            Text('Severity',
                style: AppTextStyles.label
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                ('🟢 Low', 'low'),
                ('🟡 Medium', 'medium'),
                ('🟠 High', 'high'),
                ('🔴 Critical', 'critical'),
              ]
                  .map((s) => Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _severity = s.$2),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 150),
                            margin:
                                const EdgeInsets.only(
                                    right: 4),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 8),
                            decoration: BoxDecoration(
                              color: _severity == s.$2
                                  ? AppColors.error
                                      .withOpacity(0.1)
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      _severity == s.$2
                                          ? AppColors.error
                                          : AppColors
                                              .divider),
                            ),
                            child: Text(s.$1,
                                textAlign: TextAlign.center,
                                style: AppTextStyles
                                    .caption
                                    .copyWith(
                                  fontSize: 9,
                                  fontWeight:
                                      _severity == s.$2
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                  color: _severity == s.$2
                                      ? AppColors.error
                                      : AppColors
                                          .textSecondary,
                                )),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText:
                    'e.g. "20% of plants affected, maize whorl stage"',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(Icons.add_alert),
                label: const Text('Report Outbreak',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SHARED WIDGETS
// =============================================================================

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? color;
  final Color? borderColor;
  const _Section({
    required this.title,
    required this.child,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: borderColor ?? AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletPoint(
      {required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: AppTextStyles.bodySmall
                      .copyWith(height: 1.5))),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon,
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(
      {required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700, color: color));
  }
}

class _EmptyResults extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍',
              style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No results found',
              style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Try a different search or crop filter.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton(
              onPressed: onClear,
              child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No active outbreaks',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap "Report Outbreak" if you spot\na pest or disease on your farm.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}