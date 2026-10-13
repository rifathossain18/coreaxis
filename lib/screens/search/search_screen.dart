import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/entry_model.dart';
import '../../models/misc_models.dart';
import '../../providers/entries_provider.dart';
import '../../providers/calendar_and_phone_provider.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/highlight_badge.dart';
import '../../widgets/section_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String _typeFilter = 'all'; // all | EntryType values | 'phone'

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesProvider = context.watch<EntriesProvider>();
    final phoneProvider = context.watch<PhoneProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<EntryModel> entryResults = _typeFilter == 'phone'
        ? <EntryModel>[]
        : entriesProvider.search(_query,
            type: _typeFilter == 'all' ? null : _typeFilter);

    final List<PhoneContact> phoneResults =
        (_typeFilter == 'all' || _typeFilter == 'phone')
            ? phoneProvider.search(_query)
            : <PhoneContact>[];

    final hasQuery = _query.trim().isNotEmpty;
    final hasResults = entryResults.isNotEmpty || phoneResults.isNotEmpty;
    final totalResults = entryResults.length + phoneResults.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF7F8FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.travel_explore,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Search Everything',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Search Bar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D23) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search name, phone, card number...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.search,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: hasQuery
                          ? theme.colorScheme.primary.withOpacity(0.35)
                          : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),

          // ─── Filter Chips ─────────────────────────────
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', 'all', Icons.apps_rounded),
                ...EntryType.all.map(
                  (t) => _chip(EntryType.label(t), t, _iconForType(t)),
                ),
                _chip('Phone', 'phone', Icons.contact_phone_rounded),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── Result count ─────────────────────────────
          if (hasQuery && hasResults)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$totalResults result${totalResults == 1 ? "" : "s"} found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ─── Results ──────────────────────────────────
          Expanded(
            child: !hasQuery
                ? _buildInitialState(isDark, theme)
                : !hasResults
                    ? _buildEmptyState(isDark)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          if (entryResults.isNotEmpty)
                            _buildSection(
                              title: 'Entries',
                              count: entryResults.length,
                              icon: Icons.assignment_ind_rounded,
                              accent: theme.colorScheme.primary,
                              child: Column(
                                children: entryResults
                                    .map((e) => _entryTile(e, isDark))
                                    .toList(),
                              ),
                            ),
                          if (entryResults.isNotEmpty &&
                              phoneResults.isNotEmpty)
                            const SizedBox(height: 16),
                          if (phoneResults.isNotEmpty)
                            _buildSection(
                              title: 'Phone Directory',
                              count: phoneResults.length,
                              icon: Icons.contact_phone_rounded,
                              accent: AppColors.success,
                              child: Column(
                                children: phoneResults
                                    .map((c) => _phoneTile(c, isDark))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ─── Initial (no query) state ────────────────────────
  Widget _buildInitialState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.manage_search_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Search across the whole app',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find entries, contacts & more',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ─────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 56,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No matches found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword or filter',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section wrapper ─────────────────────────────────
  Widget _buildSection({
    required String title,
    required int count,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D23) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Entry tile ──────────────────────────────────────
  Widget _entryTile(EntryModel e, bool isDark) {
    final inside = e.isInside;
    final color = inside ? AppColors.success : AppColors.danger;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.015),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(
              inside ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (e.category != null) ...[
                      const SizedBox(width: 6),
                      HighlightBadge(category: e.category),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${EntryType.label(e.type)} • IN ${AppDate.dateTime(e.inTime)}'
                  '${e.outTime != null ? " • OUT ${AppDate.dateTime(e.outTime)}" : " • Inside now"}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Phone tile ──────────────────────────────────────
  Widget _phoneTile(PhoneContact c, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.015),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.success.withOpacity(0.15),
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.designation ?? ''}${(c.designation != null && c.department != null) ? ' • ' : ''}${c.department ?? ''}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.success.withOpacity(0.12),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => DialerHelper.call(c.mobile ?? c.telephone),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.call_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter chip ─────────────────────────────────────
  Widget _chip(String label, String value, IconData icon) {
    final selected = _typeFilter == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                )
              : null,
          color: selected
              ? null
              : (isDark ? const Color(0xFF1A1D23) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => setState(() => _typeFilter = value),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Icon helper for entry types ─────────────────────
  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('visitor') || t.contains('guest')) {
      return Icons.person_add_alt_1_rounded;
    }
    if (t.contains('staff') || t.contains('employee')) {
      return Icons.badge_rounded;
    }
    if (t.contains('vehicle') || t.contains('car')) {
      return Icons.directions_car_rounded;
    }
    if (t.contains('delivery') || t.contains('courier')) {
      return Icons.local_shipping_rounded;
    }
    if (t.contains('vendor') || t.contains('supplier')) {
      return Icons.storefront_rounded;
    }
    return Icons.category_rounded;
  }
}