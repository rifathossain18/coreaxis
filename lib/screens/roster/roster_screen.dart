import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/guard_model.dart';
import '../../providers/guards_provider.dart';
import '../../providers/roster_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/export_helper.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = false;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    await context.read<RosterProvider>().loadMonth(_month.year, _month.month);
    await context.read<RosterProvider>()
        .loadHolidaysAndLeaves(_month.year, _month.month);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _generate() async {
    final guards = context.read<GuardsProvider>().activeGuards;
    final shiftCount = context.read<SettingsProvider>().settings.shiftCount;
    setState(() => _loading = true);
    await context.read<RosterProvider>().generateForMonth(
          guards: guards,
          year: _month.year,
          month: _month.month,
          shiftCount: shiftCount,
        );
    if (mounted) setState(() => _loading = false);
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadMonth();
  }

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final guards = context.watch<GuardsProvider>().activeGuards;
    final roster = context.watch<RosterProvider>();
    final monthLabel = '${_monthNames[_month.month - 1]} ${_month.year}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Modern Header =====
            _buildHeader(context, monthLabel, guards, roster),
            // ===== Tab Bar =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D24) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? Colors.white70 : Colors.black54,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(height: 44, text: 'Monthly View'),
                  Tab(height: 44, text: 'Daily View'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ===== Legend =====
            const _LegendRow(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ),
            const SizedBox(height: 8),
            // ===== Body =====
            Expanded(
              child: guards.isEmpty
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _MonthlyGrid(
                            guards: guards,
                            month: _month,
                            daysInMonth: _daysInMonth),
                        _DailyView(guards: guards, date: DateTime.now()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String monthLabel,
    List<GuardModel> guards,
    RosterProvider roster,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duty Roster',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${guards.length} active guards',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _buildMenuButton(context, guards, roster),
            ],
          ),
          const SizedBox(height: 16),
          // Month Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D24) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _monthNavButton(
                  Icons.chevron_left_rounded,
                  () => _changeMonth(-1),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                _monthNavButton(
                  Icons.chevron_right_rounded,
                  () => _changeMonth(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    List<GuardModel> guards,
    RosterProvider roster,
  ) {
    final monthLabel = '${_monthNames[_month.month - 1]} ${_month.year}';
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1D24)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_vert_rounded),
      ),
      onSelected: (v) async {
        if (v == 'generate') {
          await _generate();
        } else if (v == 'pdf') {
          await ExportHelper.exportRosterPdf(
            monthLabel: monthLabel,
            guards: guards,
            daysInMonth: _daysInMonth,
            codeFor: (guardId, day) =>
                roster.shiftCodeOn(
                    guardId, DateTime(_month.year, _month.month, day)) ??
                '-',
          );
        } else if (v == 'excel') {
          await ExportHelper.exportRosterExcel(
            monthLabel: monthLabel,
            guards: guards,
            daysInMonth: _daysInMonth,
            codeFor: (guardId, day) =>
                roster.shiftCodeOn(
                    guardId, DateTime(_month.year, _month.month, day)) ??
                '-',
          );
        } else if (v == 'holiday') {
          _pickHolidayDate(context, guards);
        }
      },
      itemBuilder: (context) => [
        _menuItem('generate', Icons.auto_awesome_rounded,
            'Generate / Refresh'),
        _menuItem('holiday', Icons.beach_access_rounded, 'Mark Holiday'),
        const PopupMenuDivider(),
        _menuItem('pdf', Icons.picture_as_pdf_rounded, 'Export PDF'),
        _menuItem('excel', Icons.table_chart_rounded, 'Export Excel'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shield_outlined,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Guards Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add guards first from the Security Guards screen\nto generate their duty roster.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickHolidayDate(
      BuildContext context, List<GuardModel> guards) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await context
        .read<RosterProvider>()
        .setHolidayForAll(guards: guards, date: picked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
              'Marked ${picked.toLocal()} as holiday for all guards'),
        ),
      );
    }
  }
}

// ============================================================
// LEGEND ROW
// ============================================================
class _LegendRow extends StatelessWidget {
  const _LegendRow();

  static const _items = [
    _LegendItem('A', 'Day/Morning', AppColors.primary),
    _LegendItem('B', 'Night/Evening', AppColors.accent),
    _LegendItem('C', 'Night (3-shift)', AppColors.director),
    _LegendItem('O', 'Off Day', Colors.grey),
    _LegendItem('H', 'Holiday', AppColors.warning),
    _LegendItem('L', 'Leave', AppColors.danger),
    _LegendItem('G', 'General', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildChip(_items[i]),
      ),
    );
  }

  Widget _buildChip(_LegendItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.code,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final String code;
  final String label;
  final Color color;
  const _LegendItem(this.code, this.label, this.color);
}

// ============================================================
// MONTHLY GRID
// ============================================================
class _MonthlyGrid extends StatelessWidget {
  final List<GuardModel> guards;
  final DateTime month;
  final int daysInMonth;

  const _MonthlyGrid({
    required this.guards,
    required this.month,
    required this.daysInMonth,
  });

  Color _colorFor(String code) {
    switch (code) {
      case 'A':
        return AppColors.primary;
      case 'B':
        return AppColors.accent;
      case 'C':
        return AppColors.director;
      case 'O':
        return Colors.grey;
      case 'H':
        return AppColors.warning;
      case 'L':
        return AppColors.danger;
      case 'G':
        return AppColors.success;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = context.watch<RosterProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  isDark
                      ? const Color(0xFF232732)
                      : AppColors.primary.withOpacity(0.06),
                ),
                columnSpacing: 8,
                horizontalMargin: 12,
                headingRowHeight: 42,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 42,
                dividerThickness: 0.4,
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 100,
                      child: Text(
                        'Guard',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  ...List.generate(
                    daysInMonth,
                    (i) => DataColumn(
                      label: SizedBox(
                        width: 24,
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                rows: guards.map((g) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.15),
                                child: Text(
                                  g.name.isNotEmpty
                                      ? g.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  g.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...List.generate(daysInMonth, (i) {
                        final date =
                            DateTime(month.year, month.month, i + 1);
                        final code =
                            roster.shiftCodeOn(g.id ?? 0, date) ?? '-';
                        final isWeekend = date.weekday == DateTime.saturday ||
                            date.weekday == DateTime.sunday;
                        return DataCell(
                          GestureDetector(
                            onTap: () =>
                                _editCell(context, g, date, code),
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: code == '-'
                                    ? (isWeekend
                                        ? Colors.grey.withOpacity(0.15)
                                        : Colors.transparent)
                                    : _colorFor(code).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(6),
                                border: code == '-'
                                    ? Border.all(
                                        color:
                                            Colors.grey.withOpacity(0.25),
                                        width: 0.8)
                                    : null,
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: code == '-'
                                      ? Colors.grey
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editCell(BuildContext context, GuardModel g, DateTime date,
      String current) async {
    const codes = ['A', 'B', 'C', 'O', 'H', 'L', 'G'];
    const labels = {
      'A': 'Day / Morning Shift',
      'B': 'Night / Evening Shift',
      'C': 'Night Shift (3-shift)',
      'O': 'Off Day',
      'H': 'Holiday',
      'L': 'On Leave',
      'G': 'General Shift',
    };

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${g.name} • ${date.day}/${date.month}/${date.year}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Current: $current',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: codes.map((c) {
                  final selected = c == current;
                  final color = _colorFor(c);
                  return InkWell(
                    onTap: () => Navigator.pop(ctx, c),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? color
                            : color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            labels[c] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? Colors.white
                                  : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (choice != null && g.id != null) {
      await context
          .read<RosterProvider>()
          .setCell(guardId: g.id!, date: date, shiftCode: choice);
    }
  }
}

// ============================================================
// DAILY VIEW
// ============================================================
class _DailyView extends StatelessWidget {
  final List<GuardModel> guards;
  final DateTime date;

  const _DailyView({required this.guards, required this.date});

  static const _order = ['A', 'B', 'C', 'G', 'O', 'H', 'L'];
  static const _labels = {
    'A': 'Shift A — Day / Morning',
    'B': 'Shift B — Night / Evening',
    'C': 'Shift C — Night (3-shift)',
    'G': 'General Shift',
    'O': 'Off Day',
    'H': 'Holiday',
    'L': 'On Leave',
  };

  Color _colorFor(String code) {
    switch (code) {
      case 'A':
        return AppColors.primary;
      case 'B':
        return AppColors.accent;
      case 'C':
        return AppColors.director;
      case 'O':
        return Colors.grey;
      case 'H':
        return AppColors.warning;
      case 'L':
        return AppColors.danger;
      case 'G':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  IconData _iconFor(String code) {
    switch (code) {
      case 'A':
        return Icons.wb_sunny_rounded;
      case 'B':
        return Icons.nights_stay_rounded;
      case 'C':
        return Icons.dark_mode_rounded;
      case 'G':
        return Icons.work_rounded;
      case 'O':
        return Icons.free_breakfast_rounded;
      case 'H':
        return Icons.beach_access_rounded;
      case 'L':
        return Icons.event_busy_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = context.watch<RosterProvider>();
    final byCode = <String, List<GuardModel>>{};
    for (final g in guards) {
      final code = roster.shiftCodeOn(g.id ?? 0, date) ?? '-';
      byCode.putIfAbsent(code, () => []).add(g);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        // Date Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.today_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${date.day} ${_monthName(date.month)} ${date.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${guards.length} Guards',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Group Cards
        for (final code in _order)
          if (byCode[code] != null && byCode[code]!.isNotEmpty)
            _buildShiftCard(
              context,
              code,
              byCode[code]!,
              isDark,
            ),
      ],
    );
  }

  Widget _buildShiftCard(
    BuildContext context,
    String code,
    List<GuardModel> members,
    bool isDark,
  ) {
    final color = _colorFor(code);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(code), color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _labels[code] ?? code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${members.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((g) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF232732)
                        : color.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: color.withOpacity(0.2),
                        child: Text(
                          g.name.isNotEmpty
                              ? g.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            g.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          if (g.designation.isNotEmpty)
                            Text(
                              g.designation,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}