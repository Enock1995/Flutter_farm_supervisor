// lib/screens/farm_management/gps_clockin_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import '../../models/farm_management_model.dart';
import '../../services/farm_management_database_service.dart';
import 'farm_management_shared_widgets.dart';

class GpsClockInScreen extends StatefulWidget {
  const GpsClockInScreen({super.key});

  @override
  State<GpsClockInScreen> createState() => _GpsClockInScreenState();
}

class _GpsClockInScreenState extends State<GpsClockInScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final _phoneCtrl = TextEditingController();
  final _farmCodeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _workerLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FarmManagementProvider>();
      final farm = provider.selectedFarm;
      if (farm != null) {
        provider.loadLiveAttendance(farm.id);
      }
      if (provider.currentWorker != null) {
        _workerLoggedIn = true;
        provider.loadClockState(provider.currentWorker!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _phoneCtrl.dispose();
    _farmCodeCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _workerLogin() async {
    if (_phoneCtrl.text.trim().isEmpty ||
        _farmCodeCtrl.text.trim().isEmpty ||
        _pinCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final result = await context.read<FarmManagementProvider>().workerLogin(
          phone: _phoneCtrl.text.trim(),
          farmCode: _farmCodeCtrl.text.trim().toUpperCase(),
          pin: _pinCtrl.text.trim(),
        );

    if (!mounted) return;

    if (result == WorkerLoginResult.success) {
      setState(() => _workerLoggedIn = true);
      final worker = context.read<FarmManagementProvider>().currentWorker!;
      context.read<FarmManagementProvider>().loadClockState(worker.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Clock-In/Out'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Worker View'),
            Tab(text: 'Owner View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _workerLoggedIn
              ? _WorkerClockTab()
              : _WorkerLoginTab(
                  phoneCtrl: _phoneCtrl,
                  farmCodeCtrl: _farmCodeCtrl,
                  pinCtrl: _pinCtrl,
                  onLogin: _workerLogin,
                ),
          _OwnerAttendanceTab(),
        ],
      ),
    );
  }
}

// ── Worker Login Tab ──────────────────────────────────────
class _WorkerLoginTab extends StatefulWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController farmCodeCtrl;
  final TextEditingController pinCtrl;
  final VoidCallback onLogin;
  const _WorkerLoginTab({
    required this.phoneCtrl,
    required this.farmCodeCtrl,
    required this.pinCtrl,
    required this.onLogin,
  });

  @override
  State<_WorkerLoginTab> createState() => _WorkerLoginTabState();
}

class _WorkerLoginTabState extends State<_WorkerLoginTab> {
  bool _pinVisible = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == FarmMgmtState.loading;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FarmSectionHeader(
                icon: Icons.location_on_outlined,
                color: AppColors.primary,
                title: 'Worker Clock-In',
                subtitle:
                    'Log in with your phone number, Farm Code and PIN.',
              ),
              const SizedBox(height: 24),

              TextField(
                controller: widget.farmCodeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Farm Code',
                  hintText: 'e.g. FARM-4821',
                  prefixIcon: Icon(Icons.tag, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: widget.phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Your Phone Number',
                  hintText: '07XXXXXXXX',
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: widget.pinCtrl,
                obscureText: !_pinVisible,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: '4-Digit PIN',
                  prefixIcon:
                      const Icon(Icons.pin_outlined, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _pinVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _pinVisible = !_pinVisible),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (provider.state == FarmMgmtState.error)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FarmErrorBanner(message: provider.errorMessage),
                ),

              ElevatedButton.icon(
                onPressed: isLoading ? null : widget.onLogin,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.login, color: Colors.white),
                label: Text(
                  isLoading ? 'Logging in...' : 'Log In',
                  style: AppTextStyles.button,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Worker Clock Tab (after login) ───────────────────────
class _WorkerClockTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, provider, _) {
        final worker = provider.currentWorker;
        if (worker == null) return const SizedBox();

        final isClockedIn = provider.isClockedIn;
        final activeRecord = provider.activeClockRecord;
        final isLoading = provider.state == FarmMgmtState.loading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker greeting card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          worker.fullName.isNotEmpty
                              ? worker.fullName[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.heading2
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mhoro, ${worker.fullName}! 👋',
                              style: AppTextStyles.heading3
                                  .copyWith(color: Colors.white)),
                          Text(
                            '${worker.role == WorkerRole.supervisor ? '🎯 Supervisor' : '👷 Field Worker'}  •  ${worker.farmCode}',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _ClockStatusCard(
                  isClockedIn: isClockedIn, activeRecord: activeRecord),
              const SizedBox(height: 20),

              // Clock in/out button — load farm from DB using the service
              FutureBuilder<FarmEntity?>(
                future: FarmManagementDatabaseService.getFarmByCode(
                    worker.farmCode),
                builder: (context, snapshot) {
                  final farm = snapshot.data;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading || farm == null
                          ? null
                          : () async {
                              if (isClockedIn) {
                                await provider.clockOut();
                              } else {
                                final result =
                                    await provider.clockIn(worker, farm);
                                if (!context.mounted) return;
                                _showClockInResult(context, result);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isClockedIn ? AppColors.error : AppColors.success,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Icon(
                              isClockedIn ? Icons.logout : Icons.login,
                              color: Colors.white,
                              size: 28),
                      label: Text(
                        isLoading
                            ? 'Please wait...'
                            : isClockedIn
                                ? 'Clock Out'
                                : 'Clock In',
                        style: AppTextStyles.button.copyWith(fontSize: 18),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              Text('My Attendance History', style: AppTextStyles.heading3),
              const SizedBox(height: 10),
              if (provider.clockHistory.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No records yet.',
                        style: AppTextStyles.bodySmall),
                  ),
                )
              else
                ...provider.clockHistory.map((r) => _ClockHistoryCard(record: r)),
            ],
          ),
        );
      },
    );
  }

  void _showClockInResult(BuildContext context, ClockInResult result) {
    String message;
    Color color;
    switch (result) {
      case ClockInResult.success:
        message = 'Clocked in successfully! ✅';
        color = AppColors.success;
        break;
      case ClockInResult.outsideGeofence:
        message =
            '⚠️ You are outside the farm boundary, but your clock-in was recorded.';
        color = AppColors.warning;
        break;
      case ClockInResult.locationFailed:
        message = 'Could not get your location. Please enable GPS.';
        color = AppColors.error;
        break;
      case ClockInResult.error:
        message = 'Something went wrong. Please try again.';
        color = AppColors.error;
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
    ));
  }
}

// ── Owner Attendance Tab ──────────────────────────────────
class _OwnerAttendanceTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FarmManagementProvider>(
      builder: (context, provider, _) {
        final live = provider.liveAttendance;
        final farm = provider.selectedFarm;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.farms.length > 1) ...[
                DropdownButtonFormField<FarmEntity>(
                  value: farm,
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
                      provider.loadLiveAttendance(f.id);
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              if (farm != null) ...[
                _FarmInfoCard(farm: farm),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Text('Live on Farm', style: AppTextStyles.heading3),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${live.length}',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon:
                        const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh',
                    onPressed: () {
                      if (farm != null) provider.loadLiveAttendance(farm.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (live.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 8),
                        Text('No workers currently clocked in.',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                )
              else
                ...live.map((r) => _LiveWorkerCard(record: r)),
            ],
          ),
        );
      },
    );
  }
}

// ── Clock status card ─────────────────────────────────────
class _ClockStatusCard extends StatelessWidget {
  final bool isClockedIn;
  final ClockRecord? activeRecord;
  const _ClockStatusCard({required this.isClockedIn, this.activeRecord});

  @override
  Widget build(BuildContext context) {
    final color =
        isClockedIn ? AppColors.success : AppColors.textSecondary;
    final now = DateTime.now();
    String duration = '';
    if (isClockedIn && activeRecord != null) {
      final diff = now.difference(activeRecord!.clockInTime);
      duration = '${diff.inHours}h ${diff.inMinutes % 60}m';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isClockedIn
                  ? [
                      BoxShadow(
                          color: AppColors.success.withOpacity(0.4),
                          blurRadius: 6)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isClockedIn ? 'Currently Clocked In' : 'Not Clocked In',
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600, color: color),
                ),
                if (isClockedIn && activeRecord != null) ...[
                  Text(
                    'Since ${DateFormat('HH:mm').format(activeRecord!.clockInTime)}  •  $duration elapsed',
                    style: AppTextStyles.caption,
                  ),
                  if (!activeRecord!.withinGeofence)
                    const Text(
                      '⚠️ Clocked in outside farm boundary',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
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

// ── Clock history card ────────────────────────────────────
class _ClockHistoryCard extends StatelessWidget {
  final ClockRecord record;
  const _ClockHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(record.clockInTime);
    final clockIn = DateFormat('HH:mm').format(record.clockInTime);
    final clockOut = record.clockOutTime != null
        ? DateFormat('HH:mm').format(record.clockOutTime!)
        : '—';
    final hours = record.hoursWorked != null
        ? '${record.hoursWorked!.toStringAsFixed(1)}h'
        : record.isClockedIn
            ? 'Active'
            : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: record.isClockedIn
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                record.isClockedIn ? Icons.login : Icons.access_time,
                color: record.isClockedIn
                    ? AppColors.success
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text('In: $clockIn  •  Out: $clockOut',
                      style: AppTextStyles.caption),
                  if (!record.withinGeofence)
                    const Text('⚠️ Outside boundary',
                        style: TextStyle(
                            color: AppColors.warning, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(hours,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live worker card (owner view) ─────────────────────────
class _LiveWorkerCard extends StatelessWidget {
  final ClockRecord record;
  const _LiveWorkerCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final since = DateFormat('HH:mm').format(record.clockInTime);
    final diff = DateTime.now().difference(record.clockInTime);
    final duration = '${diff.inHours}h ${diff.inMinutes % 60}m';

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
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              record.workerName.isNotEmpty
                  ? record.workerName[0].toUpperCase()
                  : '?',
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.success),
            ),
          ),
        ),
        title: Text(record.workerName,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clocked in at $since  •  $duration',
                style: AppTextStyles.caption),
            if (!record.withinGeofence)
              const Text('⚠️ Outside farm boundary',
                  style: TextStyle(color: AppColors.warning, fontSize: 11)),
          ],
        ),
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.success.withOpacity(0.4), blurRadius: 6)
            ],
          ),
        ),
      ),
    );
  }
}

// ── Farm info card ────────────────────────────────────────
class _FarmInfoCard extends StatelessWidget {
  final FarmEntity farm;
  const _FarmInfoCard({required this.farm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farm.farmName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                  '${farm.sizeHectares} ha  •  ${farm.district}  •  Geofence: ${farm.geofenceRadiusMeters.toInt()}m',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(farm.farmCode,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}