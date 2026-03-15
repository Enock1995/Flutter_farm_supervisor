// lib/screens/farm_management/task_assignment_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../models/farm_management_model.dart';
import '../../models/task_activity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_management_provider.dart';
import 'farm_management_shared_widgets.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key});

  @override
  State<TaskAssignmentScreen> createState() =>
      _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0: _filterStatus = null; break;
            case 1: _filterStatus = TaskStatus.pending; break;
            case 2: _filterStatus = TaskStatus.inProgress; break;
            case 3: _filterStatus = TaskStatus.completed; break;
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    if (provider.selectedFarm == null) {
      await provider.loadFarms(user.userId);
    }
    final farm = provider.selectedFarm;
    if (farm != null) {
      await provider.loadTasks(farm.id);
      await provider.loadWorkers(farm.id);
    }
  }

  List<TaskModel> _filteredTasks(List<TaskModel> all) {
    if (_filterStatus == null) return all;
    return all.where((t) => t.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Assignment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'New Task',
            onPressed: () => _showCreateTaskSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Done'),
          ],
        ),
      ),
      body: Consumer<FarmManagementProvider>(
        builder: (context, provider, _) {
          final farm = provider.selectedFarm;

          if (farm == null) {
            return const _NoFarmPlaceholder();
          }

          final filtered = _filteredTasks(provider.tasks);

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // Summary cards
                SliverToBoxAdapter(
                  child: _TaskSummaryBar(
                      summary: provider.taskSummary),
                ),

                // Overdue banner
                if (provider.overdueTasks.isNotEmpty &&
                    _filterStatus == null)
                  SliverToBoxAdapter(
                    child: _OverdueBanner(
                        count: provider.overdueTasks.length),
                  ),

                // Task list
                filtered.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyTasksPlaceholder(
                            status: _filterStatus),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _TaskCard(
                              task: filtered[i],
                              workers: provider.workers,
                              onStatusChange: (status, note) =>
                                  _changeStatus(
                                filtered[i],
                                status,
                                note,
                                provider,
                                farm,
                              ),
                              onDelete: () => _deleteTask(
                                  filtered[i], provider, farm),
                            ),
                            childCount: filtered.length,
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _changeStatus(
    TaskModel task,
    TaskStatus newStatus,
    String? note,
    FarmManagementProvider provider,
    FarmEntity farm,
  ) async {
    final user = context.read<AuthProvider>().user!;
    await provider.updateTaskStatus(
      task.id,
      newStatus,
      user.fullName,
      completionNote: note,
      farmId: farm.id,
      ownerId: user.userId,
    );
  }

  Future<void> _deleteTask(
    TaskModel task,
    FarmManagementProvider provider,
    FarmEntity farm,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: Text(
            'Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style:
                    TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final user = context.read<AuthProvider>().user!;
      await provider.deleteTask(task.id, farm.id, user.userId);
    }
  }

  void _showCreateTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateTaskSheet(),
    );
  }
}

// ── SUMMARY BAR ───────────────────────────────────────────
class _TaskSummaryBar extends StatelessWidget {
  final Map<String, int> summary;
  const _TaskSummaryBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _SummaryChip(
              label: 'Pending',
              count: summary['pending'] ?? 0,
              color: AppColors.warning),
          const SizedBox(width: 8),
          _SummaryChip(
              label: 'Active',
              count: summary['inProgress'] ?? 0,
              color: AppColors.info),
          const SizedBox(width: 8),
          _SummaryChip(
              label: 'Done',
              count: summary['completed'] ?? 0,
              color: AppColors.success),
          const SizedBox(width: 8),
          _SummaryChip(
              label: 'Cancelled',
              count: summary['cancelled'] ?? 0,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label,
      required this.count,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── OVERDUE BANNER ────────────────────────────────────────
class _OverdueBanner extends StatelessWidget {
  final int count;
  const _OverdueBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count task${count > 1 ? 's are' : ' is'} overdue',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── TASK CARD ─────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final List<WorkerModel> workers;
  final Function(TaskStatus, String?) onStatusChange;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.workers,
    required this.onStatusChange,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.low:    return AppColors.success;
      case TaskPriority.medium: return AppColors.warning;
      case TaskPriority.high:   return const Color(0xFFFF7043);
      case TaskPriority.urgent: return AppColors.error;
    }
  }

  Color get _statusColor {
    switch (task.status) {
      case TaskStatus.pending:    return AppColors.warning;
      case TaskStatus.inProgress: return AppColors.info;
      case TaskStatus.completed:  return AppColors.success;
      case TaskStatus.cancelled:  return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isDueToday = task.isDueToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.4)
              : AppColors.divider,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: priority stripe + title ──────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: _priorityColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(task.priority.emoji,
                              style: const TextStyle(
                                  fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(
                            task.priority.label
                                .toUpperCase(),
                            style: TextStyle(
                              color: _priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(
                              label: task.status.label,
                              color: _statusColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          decoration:
                              task.status == TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                          color: task.status ==
                                  TaskStatus.completed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                _TaskMenu(
                    task: task,
                    onStatusChange: onStatusChange,
                    onDelete: onDelete),
              ],
            ),
          ),

          // ── Description ────────────────────────────
          if (task.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 14, 8),
              child: Text(
                task.description,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Meta row ──────────────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                // Due date
                _MetaTag(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDueDate(task.dueDate),
                  color: isOverdue
                      ? AppColors.error
                      : isDueToday
                          ? AppColors.warning
                          : AppColors.textSecondary,
                ),
                // Assigned worker
                if (task.assignedWorkerName != null)
                  _MetaTag(
                    icon: Icons.person_outline,
                    label: task.assignedWorkerName!,
                    color: AppColors.primary,
                  ),
                // Field/plot
                if (task.fieldOrPlot != null &&
                    task.fieldOrPlot!.isNotEmpty)
                  _MetaTag(
                    icon: Icons.landscape_outlined,
                    label: task.fieldOrPlot!,
                    color: AppColors.earth,
                  ),
              ],
            ),
          ),

          // ── Completion note ───────────────────────
          if (task.completionNote != null &&
              task.completionNote!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(task.completionNote!,
                        style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff < 0) return 'Overdue ${(-diff)}d';
    if (diff <= 7) return 'Due in ${diff}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── STATUS PILL ───────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ── META TAG ──────────────────────────────────────────────
class _MetaTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaTag(
      {required this.icon,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── TASK POPUP MENU ───────────────────────────────────────
class _TaskMenu extends StatelessWidget {
  final TaskModel task;
  final Function(TaskStatus, String?) onStatusChange;
  final VoidCallback onDelete;
  const _TaskMenu(
      {required this.task,
      required this.onStatusChange,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert,
          color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        switch (value) {
          case 'start':
            onStatusChange(TaskStatus.inProgress, null);
            break;
          case 'complete':
            final note = await _showCompletionDialog(context);
            if (note != null) {
              onStatusChange(TaskStatus.completed, note);
            }
            break;
          case 'cancel':
            onStatusChange(TaskStatus.cancelled, null);
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (_) => [
        if (task.status == TaskStatus.pending)
          const PopupMenuItem(
            value: 'start',
            child: Row(children: [
              Icon(Icons.play_arrow_outlined,
                  color: AppColors.info, size: 18),
              SizedBox(width: 8),
              Text('Mark In Progress'),
            ]),
          ),
        if (task.status == TaskStatus.inProgress ||
            task.status == TaskStatus.pending)
          const PopupMenuItem(
            value: 'complete',
            child: Row(children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 18),
              SizedBox(width: 8),
              Text('Mark Complete'),
            ]),
          ),
        if (task.status != TaskStatus.cancelled &&
            task.status != TaskStatus.completed)
          const PopupMenuItem(
            value: 'cancel',
            child: Row(children: [
              Icon(Icons.cancel_outlined,
                  color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Text('Cancel Task'),
            ]),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline,
                color: AppColors.error, size: 18),
            SizedBox(width: 8),
            Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }

  Future<String?> _showCompletionDialog(
      BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add a completion note (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Planted 2 rows of maize...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

// ── CREATE TASK BOTTOM SHEET ──────────────────────────────
class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet();

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  WorkerModel? _assignedWorker;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a task title.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<FarmManagementProvider>();
    final user = context.read<AuthProvider>().user!;
    final farm = provider.selectedFarm!;

    final success = await provider.createTask(
      farmId: farm.id,
      ownerId: user.userId,
      ownerName: user.fullName,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      assignedWorkerId: _assignedWorker?.id,
      assignedWorkerName: _assignedWorker?.fullName,
      fieldOrPlot: _fieldCtrl.text.trim().isEmpty
          ? null
          : _fieldCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Task created successfully ✅'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = context
        .watch<FarmManagementProvider>()
        .workers
        .where((w) => w.status == WorkerStatus.approved)
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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

            Text('Create New Task',
                style: AppTextStyles.heading3),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco(
                  'Task Title *', Icons.task_alt_outlined),
            ),
            const SizedBox(height: 14),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco('Description (optional)',
                  Icons.notes_outlined),
            ),
            const SizedBox(height: 14),

            // Priority
            Text('Priority', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 14),

            // Due date
            Text('Due Date', style: AppTextStyles.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined,
                        color: AppColors.textHint, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Assign worker
            Text('Assign To (optional)',
                style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<WorkerModel?>(
              value: _assignedWorker,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline,
                    color: AppColors.primary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              hint: const Text('Unassigned'),
              items: [
                const DropdownMenuItem(
                    value: null,
                    child: Text('Unassigned')),
                ...workers.map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w.fullName),
                    )),
              ],
              onChanged: (w) =>
                  setState(() => _assignedWorker = w),
            ),
            const SizedBox(height: 14),

            // Field/plot
            TextField(
              controller: _fieldCtrl,
              decoration: _inputDeco(
                  'Field / Plot (optional)',
                  Icons.landscape_outlined),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Icon(
                        Icons.check_circle_outline),
                label: Text(
                  _isLoading
                      ? 'Creating...'
                      : 'Create Task',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
    );
  }
}

// ── PRIORITY SELECTOR ─────────────────────────────────────
class _PrioritySelector extends StatelessWidget {
  final TaskPriority selected;
  final Function(TaskPriority) onChanged;
  const _PrioritySelector(
      {required this.selected, required this.onChanged});

  Color _colorFor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:    return AppColors.success;
      case TaskPriority.medium: return AppColors.warning;
      case TaskPriority.high:   return const Color(0xFFFF7043);
      case TaskPriority.urgent: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = selected == p;
        final color = _colorFor(p);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                  vertical: 10),
              decoration: BoxDecoration(
                color:
                    isSelected ? color : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSelected
                        ? color
                        : color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(p.emoji,
                      style:
                          const TextStyle(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    p.label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── PLACEHOLDERS ──────────────────────────────────────────
class _EmptyTasksPlaceholder extends StatelessWidget {
  final TaskStatus? status;
  const _EmptyTasksPlaceholder({this.status});

  @override
  Widget build(BuildContext context) {
    final label = status == null
        ? 'No tasks yet'
        : 'No ${status!.label.toLowerCase()} tasks';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋',
              style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text('Tap + to create a task',
              style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _NoFarmPlaceholder extends StatelessWidget {
  const _NoFarmPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌾',
                style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('No Farm Registered',
                style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Register a farm first to start assigning tasks.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/farm-registration'),
              child: const Text('Register Farm'),
            ),
          ],
        ),
      ),
    );
  }
}