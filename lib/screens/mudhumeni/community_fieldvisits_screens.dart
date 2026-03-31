// lib/screens/mudhumeni/community_fieldvisits_screens.dart
// Developed by Sir Enocks Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/mudhumeni_database_service.dart';
import '../../models/mudhumeni_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIELD VISITS SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class FieldVisitsScreen extends StatefulWidget {
  const FieldVisitsScreen({super.key});

  @override
  State<FieldVisitsScreen> createState() => _FieldVisitsScreenState();
}

class _FieldVisitsScreenState extends State<FieldVisitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<FieldVisit> _myVisits = [];
  List<FieldVisit> _pendingRequests = [];
  List<FieldVisit> _allVisits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) throw Exception('No user logged in');

      if (user.isMudhumeni || user.isAdmin) {
        // Mudhumeni/Admin: Load visits assigned to them + pending requests in their area
        _myVisits = await MudhumeniDatabaseService.getVisitsByMudhumeni(user.userId);
        _pendingRequests = await MudhumeniDatabaseService.getPendingVisitsInWard(user.ward);
        _allVisits = await MudhumeniDatabaseService.getAllVisitsInWard(user.ward);
      } else {
        // Farmer: Load their own visit requests
        _myVisits = await MudhumeniDatabaseService.getVisitsByFarmer(user.userId);
        _pendingRequests = [];
        _allVisits = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final isMudhumeni = user.isMudhumeni || user.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Visit Scheduler'),
        bottom: isMudhumeni
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(icon: Icon(Icons.notifications_active), text: 'Pending Requests'),
                  Tab(icon: Icon(Icons.event_available), text: 'My Visits'),
                  Tab(icon: Icon(Icons.calendar_month), text: 'All Visits'),
                ],
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVisits,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadVisits)
              : isMudhumeni
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _PendingRequestsTab(
                          visits: _pendingRequests,
                          onRefresh: _loadVisits,
                        ),
                        _MyVisitsTab(
                          visits: _myVisits,
                          isMudhumeni: true,
                          onRefresh: _loadVisits,
                        ),
                        _AllVisitsTab(
                          visits: _allVisits,
                          onRefresh: _loadVisits,
                        ),
                      ],
                    )
                  : _MyVisitsTab(
                      visits: _myVisits,
                      isMudhumeni: false,
                      onRefresh: _loadVisits,
                    ),
      floatingActionButton: !isMudhumeni
          ? FloatingActionButton.extended(
              onPressed: () => _showRequestVisitDialog(context, user.userId, user.ward),
              icon: const Icon(Icons.add),
              label: const Text('Request Visit'),
            )
          : null,
    );
  }

  Future<void> _showRequestVisitDialog(BuildContext context, String farmerId, String ward) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _RequestVisitDialog(farmerId: farmerId, ward: ward),
    );

    if (result == true) {
      _loadVisits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit request submitted! Mudhumeni officer will respond soon.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PENDING REQUESTS TAB (MUDHUMENI VIEW)
// ══════════════════════════════════════════════════════════════════════════════

class _PendingRequestsTab extends StatelessWidget {
  final List<FieldVisit> visits;
  final VoidCallback onRefresh;

  const _PendingRequestsTab({
    required this.visits,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pendingVisits = visits.where((v) => v.status == 'pending').toList();

    if (pendingVisits.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Pending Requests',
        message: 'All visit requests have been addressed.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingVisits.length,
        itemBuilder: (context, index) {
          final visit = pendingVisits[index];
          return _PendingVisitCard(
            visit: visit,
            onAction: onRefresh,
          );
        },
      ),
    );
  }
}

class _PendingVisitCard extends StatelessWidget {
  final FieldVisit visit;
  final VoidCallback onAction;

  const _PendingVisitCard({
    required this.visit,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.warning.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🔔 NEW REQUEST',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(visit.requestedDate),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              visit.farmerName,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Ward ${visit.ward}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.phone, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  visit.farmerPhone,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purpose:',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(visit.purpose, style: AppTextStyles.body),
                  if (visit.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Additional Notes:',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(visit.notes, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(context, visit.id!),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAccept(context, visit),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, FieldVisit visit) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _ScheduleVisitDialog(visit: visit),
    );

    if (result != null) {
      try {
        final user = context.read<AuthProvider>().user!;
        await MudhumeniDatabaseService.updateVisitStatus(
          visit.id!,
          'scheduled',
          mudhumeniId: user.userId,
          mudhumeniName: user.fullName,
          scheduledDate: result,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit scheduled successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          onAction();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(BuildContext context, int visitId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Visit Request'),
        content: const Text(
          'Are you sure you want to decline this visit request? '
          'The farmer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MudhumeniDatabaseService.updateVisitStatus(visitId, 'cancelled');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit request declined'),
              backgroundColor: AppColors.warning,
            ),
          );
          onAction();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MY VISITS TAB
// ══════════════════════════════════════════════════════════════════════════════

class _MyVisitsTab extends StatelessWidget {
  final List<FieldVisit> visits;
  final bool isMudhumeni;
  final VoidCallback onRefresh;

  const _MyVisitsTab({
    required this.visits,
    required this.isMudhumeni,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) {
      return _EmptyState(
        icon: Icons.event_note,
        title: isMudhumeni ? 'No Assigned Visits' : 'No Visit Requests',
        message: isMudhumeni
            ? 'You have no scheduled visits yet.'
            : 'You haven\'t requested any field visits yet.',
      );
    }

    // Group by status
    final scheduled = visits.where((v) => v.status == 'scheduled').toList();
    final completed = visits.where((v) => v.status == 'completed').toList();
    final cancelled = visits.where((v) => v.status == 'cancelled').toList();
    final pending = visits.where((v) => v.status == 'pending').toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.schedule,
              title: 'Pending Response',
              count: pending.length,
              color: AppColors.warning,
            ),
            ...pending.map((v) => _VisitCard(
                  visit: v,
                  isMudhumeni: isMudhumeni,
                  onRefresh: onRefresh,
                )),
            const SizedBox(height: 16),
          ],
          if (scheduled.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.event_available,
              title: 'Scheduled',
              count: scheduled.length,
              color: AppColors.info,
            ),
            ...scheduled.map((v) => _VisitCard(
                  visit: v,
                  isMudhumeni: isMudhumeni,
                  onRefresh: onRefresh,
                )),
            const SizedBox(height: 16),
          ],
          if (completed.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.check_circle,
              title: 'Completed',
              count: completed.length,
              color: AppColors.success,
            ),
            ...completed.map((v) => _VisitCard(
                  visit: v,
                  isMudhumeni: isMudhumeni,
                  onRefresh: onRefresh,
                )),
            const SizedBox(height: 16),
          ],
          if (cancelled.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.cancel,
              title: 'Cancelled',
              count: cancelled.length,
              color: AppColors.error,
            ),
            ...cancelled.map((v) => _VisitCard(
                  visit: v,
                  isMudhumeni: isMudhumeni,
                  onRefresh: onRefresh,
                )),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final FieldVisit visit;
  final bool isMudhumeni;
  final VoidCallback onRefresh;

  const _VisitCard({
    required this.visit,
    required this.isMudhumeni,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(visit.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(visit.status), color: statusColor, size: 20),
        ),
        title: Text(
          isMudhumeni ? visit.farmerName : visit.mudhumeniName ?? 'Pending assignment',
          style: AppTextStyles.body,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(visit.purpose, style: AppTextStyles.caption),
            if (visit.scheduledDate != null)
              Text(
                'Scheduled: ${_formatFullDate(visit.scheduledDate!)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.info),
              )
            else
              Text(
                'Requested: ${_formatFullDate(visit.requestedDate)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
              ),
          ],
        ),
        trailing: visit.status == 'scheduled' && isMudhumeni
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                onPressed: () => _markComplete(context, visit.id!),
                tooltip: 'Mark as complete',
              )
            : null,
        onTap: () => _showVisitDetails(context, visit),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'scheduled':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'scheduled':
        return Icons.event_available;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markComplete(BuildContext context, int visitId) async {
    try {
      await MudhumeniDatabaseService.updateVisitStatus(visitId, 'completed');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit marked as completed!'),
            backgroundColor: AppColors.success,
          ),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showVisitDetails(BuildContext context, FieldVisit visit) {
    showDialog(
      context: context,
      builder: (context) => _VisitDetailsDialog(visit: visit),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ALL VISITS TAB (ADMIN VIEW)
// ══════════════════════════════════════════════════════════════════════════════

class _AllVisitsTab extends StatelessWidget {
  final List<FieldVisit> visits;
  final VoidCallback onRefresh;

  const _AllVisitsTab({
    required this.visits,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_note,
        title: 'No Visits',
        message: 'No field visits in your ward yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return _VisitCard(
            visit: visit,
            isMudhumeni: true,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REQUEST VISIT DIALOG (FARMER)
// ══════════════════════════════════════════════════════════════════════════════

class _RequestVisitDialog extends StatefulWidget {
  final String farmerId;
  final String ward;

  const _RequestVisitDialog({
    required this.farmerId,
    required this.ward,
  });

  @override
  State<_RequestVisitDialog> createState() => _RequestVisitDialogState();
}

class _RequestVisitDialogState extends State<_RequestVisitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Field Visit'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A Mudhumeni officer in your ward will be notified of your request.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Visit *',
                  hintText: 'e.g., Crop disease inspection',
                ),
                maxLines: 2,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any specific details...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = context.read<AuthProvider>().user!;
      final visit = FieldVisit(
        farmerId: user.userId,
        farmerName: user.fullName,
        farmerPhone: user.phone,
        mudhumeniId: '',
        ward: widget.ward,
        purpose: _purposeController.text.trim(),
        notes: _notesController.text.trim(),
        requestedDate: DateTime.now(),
        status: 'pending',
      );

      await MudhumeniDatabaseService.createFieldVisit(visit);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCHEDULE VISIT DIALOG (MUDHUMENI)
// ══════════════════════════════════════════════════════════════════════════════

class _ScheduleVisitDialog extends StatefulWidget {
  final FieldVisit visit;

  const _ScheduleVisitDialog({required this.visit});

  @override
  State<_ScheduleVisitDialog> createState() => _ScheduleVisitDialogState();
}

class _ScheduleVisitDialogState extends State<_ScheduleVisitDialog> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Visit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today, color: AppColors.primary),
            title: const Text('Date'),
            subtitle: Text(_formatDate(_selectedDate)),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: AppColors.primary),
            title: const Text('Time'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final scheduledDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );
            Navigator.pop(context, scheduledDateTime);
          },
          child: const Text('Confirm Schedule'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VISIT DETAILS DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _VisitDetailsDialog extends StatelessWidget {
  final FieldVisit visit;

  const _VisitDetailsDialog({required this.visit});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Visit Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(label: 'Farmer', value: visit.farmerName),
            _DetailRow(label: 'Phone', value: visit.farmerPhone),
            _DetailRow(label: 'Ward', value: visit.ward),
            _DetailRow(label: 'Status', value: visit.status.toUpperCase()),
            const Divider(height: 24),
            _DetailRow(label: 'Purpose', value: visit.purpose),
            if (visit.notes.isNotEmpty) _DetailRow(label: 'Notes', value: visit.notes),
            const Divider(height: 24),
            _DetailRow(
              label: 'Requested',
              value: _formatFullDate(visit.requestedDate),
            ),
            if (visit.scheduledDate != null)
              _DetailRow(
                label: 'Scheduled',
                value: _formatFullDate(visit.scheduledDate!),
              ),
            if (visit.mudhumeniName != null)
              _DetailRow(label: 'Assigned To', value: visit.mudhumeniName!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMMUNITY & SEASONAL CALENDAR SCREENS (STUBS FOR NOW)
// ══════════════════════════════════════════════════════════════════════════════

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Community')),
      body: const Center(child: Text('Community posts coming soon...')),
    );
  }
}

class SeasonalCalendarScreen extends StatelessWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seasonal Calendar')),
      body: const Center(child: Text('Seasonal calendar coming soon...')),
    );
  }
}