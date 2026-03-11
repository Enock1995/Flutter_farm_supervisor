// lib/screens/farm_management/worker_onboarding_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../models/farm_management_model.dart';
import 'farm_management_shared_widgets.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  State<WorkerOnboardingScreen> createState() =>
      _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<FarmManagementProvider>().loadPendingWorkers(user.userId);
        final farms = context.read<FarmManagementProvider>().farms;
        if (farms.isNotEmpty) {
          context.read<FarmManagementProvider>().loadWorkers(farms.first.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Onboarding'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Join a Farm'),
            Tab(text: 'Manage Workers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _JoinFarmTab(),
          _ManageWorkersTab(),
        ],
      ),
    );
  }
}

// ── Join Farm Tab (Worker side) ───────────────────────────
class _JoinFarmTab extends StatefulWidget {
  @override
  State<_JoinFarmTab> createState() => _JoinFarmTabState();
}

class _JoinFarmTabState extends State<_JoinFarmTab> {
  final _formKey = GlobalKey<FormState>();
  final _farmCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  WorkerRole _role = WorkerRole.fieldWorker;
  bool _pinVisible = false;

  @override
  void dispose() {
    _farmCodeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await context.read<FarmManagementProvider>().joinFarm(
          farmCode: _farmCodeCtrl.text.trim().toUpperCase(),
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          pin: _pinCtrl.text.trim(),
          role: _role,
        );

    if (!mounted) return;

    if (result == WorkerJoinResult.pendingApproval) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Sent! ✅'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_actions,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Your request to join farm ${_farmCodeCtrl.text.toUpperCase()} has been sent. The farm owner will approve your request.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Text(
              'Once approved, use your phone number and PIN to clock in.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _farmCodeCtrl.clear();
              _nameCtrl.clear();
              _phoneCtrl.clear();
              _pinCtrl.clear();
              _pinConfirmCtrl.clear();
              context.read<FarmManagementProvider>().resetState();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == FarmMgmtState.loading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FarmSectionHeader(
                  icon: Icons.group_add_outlined,
                  color: AppColors.primary,
                  title: 'Join a Farm',
                  subtitle:
                      'Enter the Farm Code given to you by the farm owner.',
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _farmCodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Farm Code *',
                    hintText: 'e.g. FARM-4821',
                    prefixIcon: Icon(Icons.tag, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter the farm code';
                    if (!RegExp(r'^FARM-\d{4}$').hasMatch(v.trim().toUpperCase())) {
                      return 'Format must be FARM-XXXX';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your Full Name *',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: '07XXXXXXXX',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: AppColors.primary),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter your phone number'
                      : null,
                ),
                const SizedBox(height: 14),

                Text('Your Role',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _RoleChip(
                      label: '👷 Field Worker',
                      selected: _role == WorkerRole.fieldWorker,
                      onTap: () =>
                          setState(() => _role = WorkerRole.fieldWorker),
                    ),
                    const SizedBox(width: 12),
                    _RoleChip(
                      label: '🎯 Supervisor',
                      selected: _role == WorkerRole.supervisor,
                      onTap: () =>
                          setState(() => _role = WorkerRole.supervisor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _pinCtrl,
                  obscureText: !_pinVisible,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: '4-Digit PIN *',
                    hintText: 'Used to clock in',
                    prefixIcon:
                        const Icon(Icons.pin_outlined, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_pinVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _pinVisible = !_pinVisible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a 4-digit PIN';
                    if (v.trim().length != 4) return 'PIN must be exactly 4 digits';
                    if (!RegExp(r'^\d{4}$').hasMatch(v.trim())) return 'Numbers only';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _pinConfirmCtrl,
                  obscureText: !_pinVisible,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN *',
                    prefixIcon:
                        Icon(Icons.pin_outlined, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Confirm your PIN';
                    if (v.trim() != _pinCtrl.text.trim()) return 'PINs do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                if (provider.state == FarmMgmtState.error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FarmErrorBanner(message: provider.errorMessage),
                  ),

                ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_outlined, color: Colors.white),
                  label: Text(
                    isLoading ? 'Sending request...' : 'Send Join Request',
                    style: AppTextStyles.button,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Manage Workers Tab (Owner side) ──────────────────────
class _ManageWorkersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, provider, _) {
        final pending = provider.pendingWorkers;
        final approved = provider.workers
            .where((w) => w.status == WorkerStatus.approved)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.farms.length > 1) ...[
                DropdownButtonFormField<FarmEntity>(
                  value: provider.selectedFarm,
                  decoration: const InputDecoration(
                    labelText: 'Select Farm',
                    prefixIcon:
                        Icon(Icons.home_outlined, color: AppColors.primary),
                  ),
                  items: provider.farms
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text(f.farmName)))
                      .toList(),
                  onChanged: (f) {
                    if (f != null) {
                      provider.selectFarm(f);
                      provider.loadWorkers(f.id);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (pending.isNotEmpty) ...[
                Row(
                  children: [
                    Text('Pending Approval', style: AppTextStyles.heading3),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${pending.length}',
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...pending.map((w) => _PendingWorkerCard(worker: w)),
                const SizedBox(height: 20),
              ],

              Text('Active Workers (${approved.length})',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              if (approved.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(Icons.group_off_outlined,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 8),
                        Text('No approved workers yet.',
                            style: AppTextStyles.bodySmall),
                        Text(
                            'Share your Farm Code with workers to invite them.',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              else
                ...approved.map((w) => _WorkerCard(worker: w)),
            ],
          ),
        );
      },
    );
  }
}

// ── Pending worker card ───────────────────────────────────
class _PendingWorkerCard extends StatelessWidget {
  final WorkerModel worker;
  const _PendingWorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      worker.fullName.isNotEmpty
                          ? worker.fullName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.fullName,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(worker.phone, style: AppTextStyles.caption),
                      Text(
                        worker.role == WorkerRole.supervisor
                            ? '🎯 Supervisor'
                            : '👷 Field Worker',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Pending',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<FarmManagementProvider>()
                        .updateWorkerStatus(
                            worker.id, WorkerStatus.rejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context
                        .read<FarmManagementProvider>()
                        .updateWorkerStatus(
                            worker.id, WorkerStatus.approved),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Approved worker card ──────────────────────────────────
class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              worker.fullName.isNotEmpty
                  ? worker.fullName[0].toUpperCase()
                  : '?',
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        title: Text(worker.fullName,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${worker.phone}  •  ${worker.role == WorkerRole.supervisor ? '🎯 Supervisor' : '👷 Field Worker'}',
          style: AppTextStyles.caption,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('Active',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ── Role chip ─────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
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