// lib/screens/reports/reports_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/reports_service.dart';

const _repColor = Color(0xFF1565C0);
const _repLight = Color(0xFF42A5F5);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() =>
      _ReportsScreenState();
}

class _ReportsScreenState
    extends State<ReportsScreen> {
  ReportType? _selectedType;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().clearReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports & Export'),
        backgroundColor: _repColor,
        actions: [
          Consumer<ReportsProvider>(
            builder: (_, prov, __) {
              if (prov.currentReport == null ||
                  !prov.currentReport!.hasData) {
                return const SizedBox.shrink();
              }
              return _exporting
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                          Icons.ios_share,
                          color: Colors.white),
                      tooltip: 'Export CSV',
                      onPressed: () =>
                          _exportCsv(prov.currentReport!),
                    );
            },
          ),
        ],
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Report catalogue
              _CatalogueBar(
                selected: _selectedType,
                onSelect: (type) {
                  setState(() => _selectedType = type);
                  provider.clearReport();
                },
              ),

              // Filter bar
              if (_selectedType != null)
                _FilterBar(provider: provider),

              // Content
              Expanded(
                child: _selectedType == null
                    ? _WelcomeView()
                    : provider.isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(
                                    color: _repColor))
                        : provider.error != null
                            ? _ErrorView(
                                error: provider.error!)
                            : provider.currentReport ==
                                    null
                                ? _GeneratePrompt(
                                    type: _selectedType!,
                                    provider: provider,
                                  )
                                : _ReportView(
                                    report: provider
                                        .currentReport!,
                                    onExport: () =>
                                        _exportCsv(provider
                                            .currentReport!),
                                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportCsv(
      GeneratedReport report) async {
    setState(() => _exporting = true);
    try {
      final csv = report.toCsv();
      final dir =
          await getTemporaryDirectory();
      final safeName = report.meta.title
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('/', '_');
      final timestamp =
          DateTime.now().millisecondsSinceEpoch;
      final file = File(
          '${dir.path}/${safeName}_$timestamp.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: report.meta.title,
        text:
            '${report.meta.title} — exported from AgricAssist ZW',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }
}

// =============================================================================
// CATALOGUE BAR — horizontal scrolling report type chips
// =============================================================================

class _CatalogueBar extends StatelessWidget {
  final ReportType? selected;
  final ValueChanged<ReportType> onSelect;
  const _CatalogueBar(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _repColor,
      padding:
          const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              ReportsService.catalogue.map((meta) {
            final isSelected =
                selected == meta.type;
            return GestureDetector(
              onTap: () => onSelect(meta.type),
              child: AnimatedContainer(
                duration: const Duration(
                    milliseconds: 180),
                margin: const EdgeInsets.only(
                    right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white
                            .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(meta.emoji,
                        style: const TextStyle(
                            fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      meta.title,
                      style: TextStyle(
                        color: isSelected
                            ? _repColor
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// =============================================================================
// FILTER BAR
// =============================================================================

class _FilterBar extends StatelessWidget {
  final ReportsProvider provider;
  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final filter = provider.filter;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.date_range,
              size: 16, color: _repColor),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              final range =
                  await showDateRangePicker(
                context: context,
                firstDate: DateTime(2022),
                lastDate: DateTime.now(),
                initialDateRange:
                    filter.from != null &&
                            filter.to != null
                        ? DateTimeRange(
                            start: filter.from!,
                            end: filter.to!)
                        : null,
                builder: (context, child) =>
                    Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme:
                        const ColorScheme.light(
                      primary: _repColor,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (range != null) {
                provider.updateFilter(
                    filter.copyWith(
                  from: range.start,
                  to: range.end,
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _repColor.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                    color: _repColor.withOpacity(0.2)),
              ),
              child: Text(
                filter.from != null &&
                        filter.to != null
                    ? '${ReportsService.formatDate(filter.from!)} → ${ReportsService.formatDate(filter.to!)}'
                    : 'All dates',
                style: TextStyle(
                  color: _repColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (filter.from != null)
            GestureDetector(
              onTap: () => provider.updateFilter(
                  filter.copyWith(
                      from: DateTime(2022),
                      to: DateTime.now())),
              child: const Icon(Icons.close,
                  size: 16,
                  color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// VIEWS
// =============================================================================

class _WelcomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text('📊 Farm Reports',
              style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(
            'Select a report type above to generate '
            'a report from your farm data. '
            'All reports can be exported as CSV '
            'and shared via WhatsApp, email, or saved to your device.',
            style: AppTextStyles.bodySmall
                .copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6),
          ),
          const SizedBox(height: 20),
          ...ReportsService.catalogue
              .map((meta) => _CatalogueCard(meta: meta)),
        ],
      ),
    );
  }
}

class _CatalogueCard extends StatelessWidget {
  final ReportMeta meta;
  const _CatalogueCard({required this.meta});

  Color get _color {
    try {
      return Color(
          int.parse(meta.color.replaceAll('#', '0xFF')));
    } catch (_) {
      return _repColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _color, width: 4),
          top: const BorderSide(
              color: AppColors.divider),
          right: const BorderSide(
              color: AppColors.divider),
          bottom: const BorderSide(
              color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Text(meta.emoji,
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(meta.title,
                    style: AppTextStyles.body
                        .copyWith(
                            fontWeight:
                                FontWeight.w700)),
                const SizedBox(height: 2),
                Text(meta.description,
                    style: AppTextStyles.caption
                        .copyWith(
                            color: AppColors
                                .textSecondary,
                            height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _GeneratePrompt extends StatelessWidget {
  final ReportType type;
  final ReportsProvider provider;
  const _GeneratePrompt(
      {required this.type, required this.provider});

  @override
  Widget build(BuildContext context) {
    final meta = ReportsService.catalogue
        .firstWhere((m) => m.type == type);

    Color color;
    try {
      color = Color(int.parse(
          meta.color.replaceAll('#', '0xFF')));
    } catch (_) {
      color = _repColor;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(meta.emoji,
                style: const TextStyle(
                    fontSize: 64)),
            const SizedBox(height: 16),
            Text(meta.title,
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              meta.description,
              style: AppTextStyles.bodySmall
                  .copyWith(
                      color:
                          AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  final user = context
                      .read<AuthProvider>()
                      .user;
                  if (user == null) return;
                  provider.generate(
                      type, user.userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: const Icon(
                    Icons.bar_chart_rounded),
                label: Text(
                  'Generate ${meta.title}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text('❌',
                style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Error generating report',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(error,
                style: AppTextStyles.bodySmall
                    .copyWith(
                        color: AppColors.error),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// REPORT VIEW — summary box + data table
// =============================================================================

class _ReportView extends StatelessWidget {
  final GeneratedReport report;
  final VoidCallback onExport;
  const _ReportView(
      {required this.report, required this.onExport});

  Color get _color {
    try {
      return Color(int.parse(
          report.meta.color.replaceAll('#', '0xFF')));
    } catch (_) {
      return _repColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!report.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(report.meta.emoji,
                  style:
                      const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('No data found',
                  style: AppTextStyles.heading3
                      .copyWith(
                          color: AppColors
                              .textSecondary)),
              const SizedBox(height: 8),
              Text(
                'No records match the selected date range.\n'
                'Try widening the date filter.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [_color, _color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(report.meta.emoji,
                        style: const TextStyle(
                            fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        report.meta.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Generated: ${ReportsService.formatDate(report.generatedAt)}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12),
                ),
                if (report.filter.from != null) ...[
                  Text(
                    'Period: ${ReportsService.formatDate(report.filter.from!)} → '
                    '${ReportsService.formatDate(report.filter.to ?? DateTime.now())}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Summary box
          if (report.summary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                    color: _color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('📋 Summary',
                      style: AppTextStyles.label
                          .copyWith(
                              fontWeight:
                                  FontWeight.w700,
                              color: _color)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children:
                        report.summary.entries
                            .map(
                              (e) => Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    e.key,
                                    style: AppTextStyles
                                        .caption
                                        .copyWith(
                                            color:
                                                AppColors
                                                    .textHint),
                                  ),
                                  Text(
                                    e.value,
                                    style: AppTextStyles
                                        .body
                                        .copyWith(
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color: _color,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Export button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onExport,
              icon: Icon(Icons.ios_share,
                  color: _color, size: 18),
              label: Text(
                'Export as CSV',
                style: TextStyle(color: _color),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _color),
                padding: const EdgeInsets.symmetric(
                    vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Row count
          Text(
            '${report.rows.length} record${report.rows.length == 1 ? '' : 's'}',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Data table
          _DataTable(report: report, color: _color),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// =============================================================================
// DATA TABLE — horizontal scroll for wide tables
// =============================================================================

class _DataTable extends StatelessWidget {
  final GeneratedReport report;
  final Color color;
  const _DataTable(
      {required this.report, required this.color});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 32,
        ),
        child: Table(
          border: TableBorder.all(
            color: AppColors.divider,
            width: 1,
            borderRadius: BorderRadius.circular(8),
          ),
          defaultColumnWidth:
              const IntrinsicColumnWidth(),
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
              ),
              children: report.headers
                  .map(
                    (h) => Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8),
                      child: Text(
                        h,
                        style: AppTextStyles.caption
                            .copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            // Data rows
            ...report.rows.asMap().entries.map(
              (entry) => TableRow(
                decoration: BoxDecoration(
                  color: entry.key.isEven
                      ? Colors.white
                      : AppColors.background,
                ),
                children: entry.value.cells
                    .map(
                      (cell) => Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7),
                        child: Text(
                          cell,
                          style:
                              AppTextStyles.bodySmall,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}