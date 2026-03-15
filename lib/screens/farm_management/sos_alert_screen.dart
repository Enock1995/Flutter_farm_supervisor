// lib/screens/farm_management/sos_alert_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../providers/sos_provider.dart';
import '../../models/sos_model.dart';
import 'farm_management_shared_widgets.dart';

class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key});

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fmProvider = context.read<FarmManagementProvider>();
      final sosProvider = context.read<SosProvider>();
      final farm = fmProvider.selectedFarm;
      if (farm != null) sosProvider.loadAlerts(farm.id);
      final worker = fmProvider.currentWorker;
      if (worker != null) sosProvider.loadWorkerAlerts(worker.id);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWorker =
        context.watch<FarmManagementProvider>().currentWorker != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert'),
        backgroundColor: AppColors.error,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: isWorker ? 'Send SOS' : 'Active Alerts'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          isWorker ? const _WorkerSosTab() : const _OwnerActiveAlertsTab(),
          const _AlertHistoryTab(),
        ],
      ),
    );
  }
}

// ── Worker SOS Tab ────────────────────────────────────────
class _WorkerSosTab extends StatefulWidget {
  const _WorkerSosTab();
  @override
  State<_WorkerSosTab> createState() => _WorkerSosTabState();
}

class _WorkerSosTabState extends State<_WorkerSosTab> {
  SosType _selectedType = SosType.medical;
  final _msgCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSos() async {
    final fmProvider = context.read<FarmManagementProvider>();
    final sosProvider = context.read<SosProvider>();
    final worker = fmProvider.currentWorker;
    final farm = fmProvider.selectedFarm ??
        (fmProvider.farms.isNotEmpty ? fmProvider.farms.first : null);

    if (worker == null || farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to determine farm. Please try again.'),
          backgroundColor: AppColors.error));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Confirm SOS'),
          ],
        ),
        content: Text(
          'You are about to send a ${_selectedType.label} alert. '
          'The farm owner will be notified immediately.\n\n'
          'Only send if this is a real emergency.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await sosProvider.triggerSos(
      worker: worker,
      farm: farm,
      type: _selectedType,
      message: _msgCtrl.text.trim().isEmpty
          ? '${_selectedType.label} — please assist immediately.'
          : _msgCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) setState(() => _sent = true);
  }

  void _resetForm() {
    setState(() {
      _sent = false;
      _selectedType = SosType.medical;
      _msgCtrl.clear();
    });
    context.read<SosProvider>().resetState();
  }

  @override
  Widget build(BuildContext context) {
    final sosProvider = context.watch<SosProvider>();
    final worker = context.watch<FarmManagementProvider>().currentWorker;
    final isLoading = sosProvider.state == SosProviderState.loading;

    if (_sent) {
      return _SosSentConfirmation(onDone: _resetForm);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency,
                    color: AppColors.error, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency SOS',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.error)),
                      Text(
                        'Only use for genuine emergencies. '
                        'Your location will be shared with the farm owner.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Emergency Type', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: SosType.values
                .map((t) => _SosTypeChip(
                      type: t,
                      selected: _selectedType == t,
                      onTap: () => setState(() => _selectedType = t),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          Text('Additional Details (optional)',
              style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          TextField(
            controller: _msgCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Describe what happened...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child:
                    Icon(Icons.notes_outlined, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (worker != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.fullName,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(worker.phone, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _sendSos,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.sos, color: Colors.white, size: 28),
              label: Text(
                isLoading ? 'Sending SOS...' : 'SEND SOS ALERT',
                style: AppTextStyles.button
                    .copyWith(fontSize: 16, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sent confirmation ─────────────────────────────────────
class _SosSentConfirmation extends StatelessWidget {
  final VoidCallback onDone;
  const _SosSentConfirmation({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.sos,
                  color: AppColors.error, size: 56),
            ),
            const SizedBox(height: 24),
            Text('SOS Sent!',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.error)),
            const SizedBox(height: 12),
            Text(
              'Your emergency alert has been recorded. '
              'Stay safe. The farm owner has been notified.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Send Another Alert'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Owner Active Alerts Tab ───────────────────────────────
class _OwnerActiveAlertsTab extends StatelessWidget {
  const _OwnerActiveAlertsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<SosProvider, FarmManagementProvider>(
      builder: (context, sosProvider, fmProvider, _) {
        final active = sosProvider.activeAlerts;
        final farm = fmProvider.selectedFarm;

        return RefreshIndicator(
          color: AppColors.error,
          onRefresh: () async {
            if (farm != null) await sosProvider.loadAlerts(farm.id);
          },
          child: active.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 64, color: AppColors.success),
                          const SizedBox(height: 16),
                          Text('No Active Emergencies',
                              style: AppTextStyles.heading3
                                  .copyWith(color: AppColors.success)),
                          const SizedBox(height: 8),
                          Text('All workers are safe.',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: active.length,
                  itemBuilder: (ctx, i) =>
                      _ActiveAlertCard(alert: active[i]),
                ),
        );
      },
    );
  }
}

// ── Active alert card ─────────────────────────────────────
class _ActiveAlertCard extends StatelessWidget {
  final SosAlert alert;
  const _ActiveAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final since =
        DateFormat('dd MMM, HH:mm').format(alert.triggeredAt);
    final diff = DateTime.now().difference(alert.triggeredAt);
    final elapsed = diff.inMinutes < 60
        ? '${diff.inMinutes}m ago'
        : '${diff.inHours}h ago';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppColors.error.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(alert.type.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.type.label,
                          style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.error)),
                      Text('$since  •  $elapsed',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                _StatusBadge(status: alert.status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                      '${alert.workerName}  •  ${alert.workerPhone}',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(alert.message, style: AppTextStyles.body),
            const SizedBox(height: 16),
            Row(
              children: [
                if (alert.status == SosStatus.active) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _acknowledgeAlert(context, alert),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Acknowledge'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(
                            color: AppColors.warning),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveDialog(context, alert),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(
      BuildContext context, SosAlert alert) async {
    final ownerName =
        context.read<AuthProvider>().user?.fullName ?? 'Farm Owner';
    await context.read<SosProvider>().acknowledgeAlert(
          alertId: alert.id,
          acknowledgedByName: ownerName,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Alert acknowledged ✅'),
          backgroundColor: AppColors.warning));
    }
  }

  Future<void> _resolveDialog(
      BuildContext context, SosAlert alert) async {
    final noteCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resolve Alert', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text('Describe how the emergency was handled.',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    'e.g. Worker taken to clinic, situation under control...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<SosProvider>().resolveAlert(
                        alertId: alert.id,
                        resolutionNote:
                            noteCtrl.text.trim().isEmpty
                                ? 'Resolved by farm owner.'
                                : noteCtrl.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Alert resolved ✅'),
                            backgroundColor: AppColors.success));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: const Text('Mark as Resolved'),
              ),
            ),
          ],
        ),
      ),
    );
    noteCtrl.dispose();
  }
}

// ── Alert History Tab ─────────────────────────────────────
class _AlertHistoryTab extends StatelessWidget {
  const _AlertHistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<SosProvider, FarmManagementProvider>(
      builder: (context, sosProvider, fmProvider, _) {
        final isWorker = fmProvider.currentWorker != null;
        final alerts =
            isWorker ? sosProvider.workerAlerts : sosProvider.alerts;
        final history = alerts
            .where((a) => a.status != SosStatus.active)
            .toList();

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No alert history yet.',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (ctx, i) =>
              _AlertHistoryCard(alert: history[i]),
        );
      },
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  final SosAlert alert;
  const _AlertHistoryCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('dd MMM yyyy, HH:mm').format(alert.triggeredAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(alert.type.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(alert.type.label,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                _StatusBadge(status: alert.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(date, style: AppTextStyles.caption),
            Text(
                '${alert.workerName}  •  ${alert.workerPhone}',
                style: AppTextStyles.caption),
            if (alert.resolutionNote != null) ...[
              const SizedBox(height: 6),
              Text('Resolution: ${alert.resolutionNote}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.success)),
            ],
            if (alert.acknowledgedByName != null &&
                alert.status == SosStatus.acknowledged) ...[
              const SizedBox(height: 6),
              Text(
                  'Acknowledged by ${alert.acknowledgedByName}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.warning)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── SOS Type chip ─────────────────────────────────────────
class _SosTypeChip extends StatelessWidget {
  final SosType type;
  final bool selected;
  final VoidCallback onTap;
  const _SosTypeChip(
      {required this.type,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.error : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  selected ? AppColors.error : AppColors.divider),
        ),
        child: Row(
          children: [
            Text(type.emoji,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                type.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final SosStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case SosStatus.active:
        color = AppColors.error;
        label = '🔴 Active';
        break;
      case SosStatus.acknowledged:
        color = AppColors.warning;
        label = '🟡 Acknowledged';
        break;
      case SosStatus.resolved:
        color = AppColors.success;
        label = '🟢 Resolved';
        break;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}