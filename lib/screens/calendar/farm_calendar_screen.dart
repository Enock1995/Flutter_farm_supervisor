// lib/screens/calendar/farm_calendar_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_calendar_provider.dart';
import '../../services/farm_calendar_service.dart';

class FarmCalendarScreen extends StatefulWidget {
  const FarmCalendarScreen({super.key});

  @override
  State<FarmCalendarScreen> createState() =>
      _FarmCalendarScreenState();
}

class _FarmCalendarScreenState
    extends State<FarmCalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<FarmCalendarProvider>()
            .loadTasks(user.userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farm Calendar'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Tasks'),
            Tab(text: 'Today'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: AppColors.primaryLight,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Task',
            style: AppTextStyles.button),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CalendarTab(
            selectedDay: _selectedDay,
            onDaySelected: (day) =>
                setState(() => _selectedDay = day),
          ),
          const _TaskListTab(),
          const _TodayTab(),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

// =============================================================================
// TAB 1 — CALENDAR VIEW
// =============================================================================

class _CalendarTab extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  const _CalendarTab({
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmCalendarProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Month navigator + grid
            _MonthCalendar(
              focusedMonth: provider.focusedMonth,
              selectedDay: selectedDay,
              daysWithTasks: provider.daysWithTasks,
              onDaySelected: onDaySelected,
              onMonthChanged: provider.setFocusedMonth,
            ),

            const Divider(height: 1),

            // Tasks for selected day
            Expanded(
              child: _DayTaskList(
                day: selectedDay,
                tasks: provider.tasksForDay(selectedDay),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// MONTH CALENDAR WIDGET
// ---------------------------------------------------------------------------

class _MonthCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Set<int> daysWithTasks;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.daysWithTasks,
    required this.onDaySelected,
    required this.onMonthChanged,
  });

  static const _weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  static const _months = [
    '','January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    // Monday-based offset
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(
            focusedMonth.year, focusedMonth.month + 1, 0)
        .day;
    final today = DateTime.now();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMonthChanged(DateTime(
                    focusedMonth.year,
                    focusedMonth.month - 1)),
              ),
              Text(
                '${_months[focusedMonth.month]} ${focusedMonth.year}',
                style: AppTextStyles.heading3,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMonthChanged(DateTime(
                    focusedMonth.year,
                    focusedMonth.month + 1)),
              ),
            ],
          ),

          // Weekday headers
          Row(
            children: _weekdays.map((d) => Expanded(
              child: Center(
                child: Text(d,
                    style: AppTextStyles.caption.copyWith(
                      color: d == 'Sat' || d == 'Sun'
                          ? AppColors.textHint
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            )).toList(),
          ),
          const SizedBox(height: 6),

          // Days grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox();

              final day = i - startOffset + 1;
              final date = DateTime(
                  focusedMonth.year, focusedMonth.month, day);
              final isSelected = selectedDay.year == date.year &&
                  selectedDay.month == date.month &&
                  selectedDay.day == date.day;
              final isToday = today.year == date.year &&
                  today.month == date.month &&
                  today.day == date.day;
              final hasTasks = daysWithTasks.contains(day);

              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : isToday
                            ? AppColors.primaryLight
                                .withOpacity(0.12)
                            : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.primaryLight,
                            width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasTasks && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DAY TASK LIST
// ---------------------------------------------------------------------------

class _DayTaskList extends StatelessWidget {
  final DateTime day;
  final List<CalendarTask> tasks;
  const _DayTaskList(
      {required this.day, required this.tasks});

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              16, 14, 16, 8),
          child: Text(
            '${day.day} ${months[day.month]} — '
            '${tasks.isEmpty ? 'No tasks' : '${tasks.length} task${tasks.length == 1 ? '' : 's'}'}',
            style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text('📅',
                          style:
                              TextStyle(fontSize: 40)),
                      const SizedBox(height: 10),
                      Text('No tasks this day',
                          style: AppTextStyles.bodySmall
                              .copyWith(
                                  color: AppColors
                                      .textHint)),
                      const SizedBox(height: 6),
                      Text('Tap + Add Task to schedule',
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: AppColors
                                      .textHint)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 80),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) =>
                      _TaskTile(task: tasks[i]),
                ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 2 — ALL TASKS LIST
// =============================================================================

class _TaskListTab extends StatelessWidget {
  const _TaskListTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmCalendarProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryLight));
        }

        final overdue = provider.overdueTasks;
        final upcoming = provider.upcomingTasks
            .where((t) => !t.isOverdue)
            .toList();
        final completed = provider.tasks
            .where((t) => t.isCompleted)
            .toList();

        if (provider.tasks.isEmpty) {
          return _EmptyTasks();
        }

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Stats row
            _StatsRow(provider: provider),
            const SizedBox(height: 16),

            if (overdue.isNotEmpty) ...[
              _SectionHeader(
                label: '⚠️ Overdue (${overdue.length})',
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              ...overdue.map((t) => _TaskTile(task: t)),
              const SizedBox(height: 16),
            ],

            if (upcoming.isNotEmpty) ...[
              _SectionHeader(
                label:
                    '📅 Upcoming (${upcoming.length})',
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              ...upcoming.map((t) => _TaskTile(task: t)),
              const SizedBox(height: 16),
            ],

            if (completed.isNotEmpty) ...[
              _SectionHeader(
                label:
                    '✅ Completed (${completed.length})',
                color: AppColors.success,
              ),
              const SizedBox(height: 8),
              ...completed
                  .take(5)
                  .map((t) => _TaskTile(task: t)),
              const SizedBox(height: 30),
            ],
          ],
        );
      },
    );
  }
}

// =============================================================================
// TAB 3 — TODAY
// =============================================================================

class _TodayTab extends StatelessWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmCalendarProvider>(
      builder: (context, provider, _) {
        final today = provider.todayTasks;
        final overdue = provider.overdueTasks;

        if (today.isEmpty && overdue.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text('🌱',
                    style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text('All clear today!',
                    style: AppTextStyles.heading3
                        .copyWith(
                            color: AppColors
                                .textSecondary)),
                const SizedBox(height: 8),
                Text(
                  'No tasks scheduled. Tap + Add Task\nto plan your farm day.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primaryLight
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🌅',
                      style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayLabel(),
                        style: AppTextStyles.heading3
                            .copyWith(
                                color: Colors.white),
                      ),
                      Text(
                        '${today.length} task${today.length == 1 ? '' : 's'} today'
                        '${overdue.isNotEmpty ? ' • ${overdue.length} overdue' : ''}',
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (overdue.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(
                  label:
                      '⚠️ Overdue — do these first',
                  color: AppColors.error),
              const SizedBox(height: 8),
              ...overdue.map((t) => _TaskTile(task: t)),
            ],

            if (today.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(
                  label: "📋 Today's Tasks",
                  color: AppColors.primary),
              const SizedBox(height: 8),
              ...today.map((t) => _TaskTile(task: t)),
            ],

            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday]}, ${now.day} ${months[now.month]}';
  }
}

// =============================================================================
// TASK TILE
// =============================================================================

class _TaskTile extends StatelessWidget {
  final CalendarTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FarmCalendarProvider>();

    return Dismissible(
      key: Key(task.id),
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
      onDismissed: (_) => provider.deleteTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? AppColors.background
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isOverdue && !task.isCompleted
                ? AppColors.error.withOpacity(0.4)
                : task.isSmartSuggestion
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.divider,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
          leading: GestureDetector(
            onTap: () => provider.toggleComplete(task.id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? AppColors.success
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.success
                      : task.priorityColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 18)
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: AppTextStyles.body.copyWith(
              decoration: task.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: task.isCompleted
                  ? AppColors.textHint
                  : AppColors.textPrimary,
              fontWeight: task.isCompleted
                  ? FontWeight.w400
                  : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(task.categoryEmoji,
                      style:
                          const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(task.category,
                      style: AppTextStyles.caption
                          .copyWith(
                              color: AppColors
                                  .textSecondary)),
                  if (task.linkedCrop != null) ...[
                    const Text(' • ',
                        style: TextStyle(
                            color: AppColors.textHint)),
                    Text(task.linkedCrop!,
                        style: AppTextStyles.caption
                            .copyWith(
                                color: AppColors
                                    .primaryLight)),
                  ],
                  if (task.isSmartSuggestion) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent
                            .withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text('smart',
                          style: AppTextStyles.caption
                              .copyWith(
                            fontSize: 9,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ],
              ),
              if (task.isOverdue && !task.isCompleted)
                Text('Overdue',
                    style: AppTextStyles.caption
                        .copyWith(
                            color: AppColors.error,
                            fontWeight:
                                FontWeight.w700)),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: task.priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${task.date.day}/${task.date.month}',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ADD TASK BOTTOM SHEET
// =============================================================================

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() =>
      _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _category = 'Other';
  String _priority = 'medium';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    await context.read<FarmCalendarProvider>().addTask(
          userId: user.userId,
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          date: _selectedDate,
          category: _category,
          priority: _priority,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task added to calendar!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now()
          .subtract(const Duration(days: 1)),
      lastDate:
          DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.primaryLight),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            Text('Add Farm Task',
                style: AppTextStyles.heading3),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task title *',
                hintText: 'e.g. Spray tomatoes with Mancozeb',
                prefixIcon: const Icon(
                    Icons.task_alt,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText:
                    'Additional details or reminders',
                prefixIcon: const Icon(Icons.notes,
                    color: AppColors.primaryLight),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.background,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primaryLight),
                    const SizedBox(width: 12),
                    Text(
                      _fmtDate(_selectedDate),
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category
            Text('Category',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  FarmCalendarService.categories.map((cat) {
                final task = CalendarTask(
                  id: '',
                  userId: '',
                  title: '',
                  date: DateTime.now(),
                  category: cat,
                  createdAt: DateTime.now(),
                );
                final isSelected = _category == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      '${task.categoryEmoji} $cat',
                      style: AppTextStyles.caption
                          .copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Priority
            Text('Priority',
                style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                _PriorityChip(
                  label: '🔴 High',
                  value: 'high',
                  selected: _priority == 'high',
                  color: AppColors.error,
                  onTap: () =>
                      setState(() => _priority = 'high'),
                ),
                const SizedBox(width: 8),
                _PriorityChip(
                  label: '🟠 Medium',
                  value: 'medium',
                  selected: _priority == 'medium',
                  color: AppColors.warning,
                  onTap: () =>
                      setState(() => _priority = 'medium'),
                ),
                const SizedBox(width: 8),
                _PriorityChip(
                  label: '🟢 Low',
                  value: 'low',
                  selected: _priority == 'low',
                  color: AppColors.success,
                  onTap: () =>
                      setState(() => _priority = 'low'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                    : const Text('Add to Calendar',
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

  String _fmtDate(DateTime d) {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[d.weekday]}, ${d.day} ${months[d.month]} ${d.year}';
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _PriorityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
              color: selected
                  ? color
                  : AppColors.textPrimary,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w400,
            )),
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

class _StatsRow extends StatelessWidget {
  final FarmCalendarProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _StatPill(
              label: 'Today',
              value: '${provider.todayCount}',
              icon: '📅'),
          _StatPill(
              label: 'Overdue',
              value: '${provider.overdueCount}',
              icon: '⚠️'),
          _StatPill(
              label: 'Upcoming',
              value: '${provider.upcomingCount}',
              icon: '🗓️'),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatPill(
      {required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.heading2
                .copyWith(color: Colors.white)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white70)),
      ],
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

class _EmptyTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No tasks yet',
                style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Tap + Add Task to schedule your first\nfarm activity.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}