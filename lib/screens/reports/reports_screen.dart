import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/entry_model.dart';
import '../../providers/entries_provider.dart';
import '../../utils/export_helper.dart';
import '../../widgets/section_card.dart';
import '../roster/roster_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final entriesProvider = context.watch<EntriesProvider>();
    final allFiltered = _filtered(entriesProvider.all);

    return Scaffold(
      // ==================== APP BAR ====================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.85),
                AppColors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---------- Title icon ----------
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.insert_chart_outlined_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ---------- Title + Subtitle ----------
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reports',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Export & analyze your records',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------- Filter badge (optional) ----------
                  if (_range != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt,
                              color: Colors.white, size: 13),
                          SizedBox(width: 4),
                          Text(
                            'Filtered',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
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

      // ==================== BODY ====================
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ---------- Header summary card ----------
          _buildHeaderCard(allFiltered.length),
          const SizedBox(height: 14),

          // ---------- Date range filter ----------
          SectionCard(
            title: 'Date Range Filter',
            icon: Icons.date_range,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _range == null
                      ? 'No filter applied — exports include ALL records'
                      : '${_formatDate(_range!.start)}  →  ${_formatDate(_range!.end)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _range == null
                        ? Colors.grey.shade600
                        : AppColors.primary,
                    fontWeight:
                        _range == null ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDateRange: _range,
                        );
                        if (picked != null) setState(() => _range = picked);
                      },
                      icon: const Icon(Icons.filter_alt, size: 18),
                      label: const Text('Choose Range'),
                    ),
                    if (_range != null)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _range = null),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ---------- Section title ----------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Export by Module',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),

          // ---------- Module cards ----------
          ...EntryType.all.map((type) {
            final list = _filtered(entriesProvider.byType(type));
            return _buildModuleCard(type, list);
          }),

          const SizedBox(height: 20),

          // ---------- Roster report ----------
          _buildRosterCard(),

          const SizedBox(height: 14),

          // ---------- Export all ----------
          _buildExportAllCard(allFiltered),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildHeaderCard(int total) {
    return Container(
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assessment,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reports & Exports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$total record(s) in current range',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(String type, List<EntryModel> list) {
    final hasData = list.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EntryType.label(type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasData
                        ? '${list.length} record(s) in range'
                        : 'No records in range',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasData
                          ? Colors.grey.shade600
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Export PDF',
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.danger),
              onPressed: hasData
                  ? () async {
                      await ExportHelper.exportEntriesPdf(
                        title: EntryType.label(type),
                        entries: list,
                      );
                      _showSnack('PDF exported: ${EntryType.label(type)}');
                    }
                  : null,
            ),
            IconButton(
              tooltip: 'Export Excel',
              icon: const Icon(Icons.grid_on, color: AppColors.success),
              onPressed: hasData
                  ? () async {
                      await ExportHelper.exportEntriesExcel(
                        title: EntryType.label(type),
                        entries: list,
                      );
                      _showSnack('Excel exported: ${EntryType.label(type)}');
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_view_month,
              color: AppColors.primary),
        ),
        title: const Text(
          'Duty Roster Report',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle:
            const Text('Open Roster screen to export monthly PDF / Excel'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RosterScreen()),
        ),
      ),
    );
  }

  Widget _buildExportAllCard(List<EntryModel> all) {
    final hasData = all.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasData
              ? [
                  AppColors.success.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.1),
                ]
              : [Colors.grey.shade200, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? AppColors.success.withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: hasData
                ? AppColors.success.withOpacity(0.15)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.all_inbox,
            color: hasData ? AppColors.success : Colors.grey,
          ),
        ),
        title: const Text(
          'Export Everything',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          hasData
              ? 'One PDF + one Excel with all ${all.length} entries in range'
              : 'No records available in range',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(
          Icons.download,
          color: hasData ? AppColors.success : Colors.grey,
        ),
        onTap: hasData
            ? () async {
                await ExportHelper.exportEntriesPdf(
                  title: 'CoreAxis - All Entries',
                  entries: all,
                );
                await ExportHelper.exportEntriesExcel(
                  title: 'CoreAxis - All Entries',
                  entries: all,
                );
                _showSnack('All entries exported successfully');
              }
            : null,
      ),
    );
  }

  // ==================== HELPERS ====================

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  List<EntryModel> _filtered(List<EntryModel> entries) {
    if (_range == null) return entries;
    return entries.where((e) {
      final t = e.inTime;
      if (t == null) return false;
      return !t.isBefore(_range!.start) &&
          !t.isAfter(_range!.end.add(const Duration(days: 1)));
    }).toList();
  }
}