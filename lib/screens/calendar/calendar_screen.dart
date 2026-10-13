import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme.dart';
import '../../models/misc_models.dart';
import '../../providers/calendar_and_phone_provider.dart';
import '../../providers/entries_provider.dart';
import '../../providers/guards_provider.dart';
import '../../providers/roster_provider.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/section_card.dart';

// ── Safe color fallbacks ──────────────────────────────────────────────
class _CalColors {
  static const Color background     = Color(0xFFF5F7FA);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF1A1D26);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color error          = Color(0xFFE53935);
  static const Color border         = Color(0xFFE5E7EB);
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final cal = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: _CalColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient AppBar ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'Calendar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, right: 16),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 60,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Add Reminder',
                icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
                onPressed: () => _openReminderSheet(context),
              ),
            ],
          ),

          // ── Calendar Card ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              decoration: BoxDecoration(
                color: _CalColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2035),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) =>
                      _selected != null &&
                      d.year == _selected!.year &&
                      d.month == _selected!.month &&
                      d.day == _selected!.day,
                  eventLoader: (day) => cal.onDate(day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selected = selected;
                      _focused = focused;
                    });
                  },
                  rowHeight: 48,
                  daysOfWeekHeight: 28,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _CalColors.textPrimary,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.primary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: _CalColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    weekendStyle: TextStyle(
                      color: _CalColors.textSecondary.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    markerSize: 5,
                    markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                    defaultTextStyle: TextStyle(
                      color: _CalColors.textPrimary,
                      fontSize: 14,
                    ),
                    weekendTextStyle: TextStyle(
                      color: _CalColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // ── Day Details ─────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: true,
            child: _selected == null
                ? const _EmptySelection()
                : _DayDetails(date: _selected!),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  //  ✨  NEW REMINDER — Beautiful Bottom Sheet
  // ═════════════════════════════════════════════════════════════════════
  Future<void> _openReminderSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => const _ReminderBottomSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Reminder Bottom Sheet Widget
// ═══════════════════════════════════════════════════════════════════════
class _ReminderBottomSheet extends StatefulWidget {
  const _ReminderBottomSheet();

  @override
  State<_ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<_ReminderBottomSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  bool _remindBefore = true;
  bool _saving = false;
  int _selectedPriority = 1; // 0 = Low, 1 = Normal, 2 = High

  @override
  void initState() {
    super.initState();
    final calendarState = context.findAncestorStateOfType<_CalendarScreenState>();
    _date = calendarState?._selected ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: _CalColors.surface,
            onSurface: _CalColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await context.read<CalendarProvider>().add(
            CalendarEventModel(
              title: _titleCtrl.text.trim(),
              date: _date,
              notes: _notesCtrl.text.trim(),
              remindDayBefore: _remindBefore,
            ),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _CalColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Drag handle ────────────────────────────────
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        color: _CalColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // ── Header ─────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.warning,
                              AppColors.warning.withOpacity(0.7),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Reminder',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _CalColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add an event or important note',
                              style: TextStyle(
                                fontSize: 13,
                                color: _CalColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _CalColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: _CalColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Title Field ────────────────────────────────
                  _FieldLabel(text: 'Title', required: true),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: _CalColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(
                      hint: 'e.g. Chairman visiting',
                      icon: Icons.title_rounded,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a title'
                        : null,
                  ),

                  const SizedBox(height: 18),

                  // ── Notes Field ────────────────────────────────
                  _FieldLabel(text: 'Notes (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 14,
                      color: _CalColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Any additional details…',
                      icon: Icons.notes_rounded,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Date Picker Card ───────────────────────────
                  _FieldLabel(text: 'Date'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _CalColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppDate.date(_date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _CalColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Priority Selector ──────────────────────────
                  _FieldLabel(text: 'Priority'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PriorityChip(
                        label: 'Low',
                        icon: Icons.flag_outlined,
                        color: const Color(0xFF10B981),
                        selected: _selectedPriority == 0,
                        onTap: () => setState(() => _selectedPriority = 0),
                      ),
                      const SizedBox(width: 8),
                      _PriorityChip(
                        label: 'Normal',
                        icon: Icons.flag_rounded,
                        color: AppColors.primary,
                        selected: _selectedPriority == 1,
                        onTap: () => setState(() => _selectedPriority = 1),
                      ),
                      const SizedBox(width: 8),
                      _PriorityChip(
                        label: 'High',
                        icon: Icons.flag_rounded,
                        color: _CalColors.error,
                        selected: _selectedPriority == 2,
                        onTap: () => setState(() => _selectedPriority = 2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Reminder Switch Card ───────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: _CalColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _CalColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      value: _remindBefore,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(
                        'Remind a day before',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _CalColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Show alert on Dashboard one day earlier',
                        style: TextStyle(
                          fontSize: 12,
                          color: _CalColors.textSecondary,
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alarm_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      onChanged: (v) => setState(() => _remindBefore = v),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Action Buttons ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: _CalColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _CalColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'Save Reminder',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable Input Decoration ────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _CalColors.textSecondary.withOpacity(0.7),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, size: 20, color: _CalColors.textSecondary),
      filled: true,
      fillColor: _CalColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _CalColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _CalColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _CalColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _CalColors.error, width: 1.6),
      ),
    );
  }
}

// ── Field Label ──────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel({required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _CalColors.textPrimary,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _CalColors.error,
            ),
          ),
      ],
    );
  }
}

// ── Priority Chip ────────────────────────────────────────────────────
class _PriorityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : _CalColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : _CalColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? color : _CalColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : _CalColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty Selection Widget ───────────────────────────────────────────
class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.touch_app_rounded,
              size: 40,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap a date to see full details',
            style: TextStyle(
              color: _CalColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Details Widget ───────────────────────────────────────────────
class _DayDetails extends StatelessWidget {
  final DateTime date;
  const _DayDetails({required this.date});

  @override
  Widget build(BuildContext context) {
    final cal = context.watch<CalendarProvider>();
    final entries = context.watch<EntriesProvider>();
    final guards = context.watch<GuardsProvider>().activeGuards;
    final roster = context.watch<RosterProvider>();

    final events = cal.onDate(date);
    final dayEntries = entries.all
        .where((e) =>
            e.inTime != null &&
            e.inTime!.year == date.year &&
            e.inTime!.month == date.month &&
            e.inTime!.day == date.day)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppDate.date(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _CalColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        if (events.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              title: 'Events & Reminders',
              icon: Icons.notifications_active_rounded,
              child: Column(
                children: events
                    .map((e) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.2),
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              e.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: e.notes != null && e.notes!.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      e.notes!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _CalColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: _CalColors.error,
                              ),
                              onPressed: () => context
                                  .read<CalendarProvider>()
                                  .delete(e.id!),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

        SectionCard(
          title: 'Entries This Day (${dayEntries.length})',
          icon: Icons.assignment_ind_rounded,
          child: dayEntries.isEmpty
              ? const _MiniEmpty(message: 'No entries recorded')
              : Column(
                  children: dayEntries
                      .map((e) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.15),
                                  child: Text(
                                    e.name.isNotEmpty
                                        ? e.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${e.name} (${e.type})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'IN: ${AppDate.time(e.inTime)}  •  OUT: ${AppDate.time(e.outTime)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _CalColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
        ),

        const SizedBox(height: 12),

        SectionCard(
          title: 'Guard Roster',
          icon: Icons.security_rounded,
          child: guards.isEmpty
              ? const _MiniEmpty(message: 'No guards added')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: guards
                      .map((g) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${g.name}: ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  roster.shiftCodeOn(g.id ?? 0, date) ?? '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

// ── Mini Empty State ─────────────────────────────────────────────────
class _MiniEmpty extends StatelessWidget {
  final String message;
  const _MiniEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 32,
            color: _CalColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: _CalColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}