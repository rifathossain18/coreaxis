import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/entry_model.dart';
import '../../providers/entries_provider.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/highlight_badge.dart';
import '../../widgets/in_out_button.dart';
import '../../widgets/section_card.dart';
import 'entry_form_screen.dart';

class EntryListScreen extends StatefulWidget {
  final String type;
  final String title;

  const EntryListScreen({super.key, required this.type, required this.title});

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Color theme per entry type
  Color get _accentColor {
    switch (widget.type) {
      case EntryType.buyer:
        return const Color(0xFF6C5CE7);
      case EntryType.audit:
        return const Color(0xFF00B894);
      case EntryType.boss:
        return const Color(0xFFE17055);
      case EntryType.car:
        return const Color(0xFF0984E3);
      default:
        return const Color(0xFF2D3436);
    }
  }

  IconData get _typeIcon {
    switch (widget.type) {
      case EntryType.buyer:
        return Icons.shopping_bag_rounded;
      case EntryType.audit:
        return Icons.verified_rounded;
      case EntryType.boss:
        return Icons.workspace_premium_rounded;
      case EntryType.car:
        return Icons.directions_car_rounded;
      default:
        return Icons.people_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EntriesProvider>();
    final allForType = provider.byType(widget.type);
    final inside = allForType.where((e) => e.isInside).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 70, right: 16),
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _accentColor,
                          Color.lerp(_accentColor, Colors.black, 0.25)!,
                        ],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    right: 40,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Big icon watermark
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(
                      _typeIcon,
                      size: 110,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  labelColor: _accentColor,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.meeting_room_rounded, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Inside (${inside.length})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_rounded, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'All (${allForType.length})',
                              overflow: TextOverflow.ellipsis,
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
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _EntryList(
              entries: inside,
              type: widget.type,
              accentColor: _accentColor,
              emptyMessage: 'Nobody is inside right now',
              emptyIcon: Icons.meeting_room_outlined,
            ),
            _EntryList(
              entries: allForType,
              type: widget.type,
              accentColor: _accentColor,
              emptyMessage: 'No history yet',
              emptyIcon: Icons.history_toggle_off_rounded,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EntryFormScreen(
              type: widget.type,
              title: widget.title,
            ),
          ),
        ),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Entry',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Boss Link Dialog
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _showLinkBossDialog(BuildContext context, int carEntryId) async {
  final nameCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  String category = BossCategory.regular;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE17055).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFE17055),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Link a Boss',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Boss Name',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: designationCtrl,
                decoration: InputDecoration(
                  labelText: 'Designation',
                  prefixIcon: const Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: BossCategory.all
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(BossCategory.label(c)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => category = v ?? BossCategory.regular),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE17055),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await ctx.read<EntriesProvider>().checkInBossWithCar(
                    bossName: nameCtrl.text.trim(),
                    designation: designationCtrl.text.trim(),
                    category: category,
                    carEntryId: carEntryId,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Check In'),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry List Widget
// ─────────────────────────────────────────────────────────────────────────────
class _EntryList extends StatelessWidget {
  final List<EntryModel> entries;
  final String type;
  final Color accentColor;
  final String emptyMessage;
  final IconData emptyIcon;

  const _EntryList({
    required this.entries,
    required this.type,
    required this.accentColor,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyState(
        message: emptyMessage,
        icon: emptyIcon,
        accentColor: accentColor,
      );
    }

    final isVip = type == EntryType.buyer || type == EntryType.audit;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return _EntryCard(
          entry: e,
          type: type,
          isVip: isVip,
          accentColor: accentColor,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry Card  — overflow-safe
// ─────────────────────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final EntryModel entry;
  final String type;
  final bool isVip;
  final Color accentColor;

  const _EntryCard({
    required this.entry,
    required this.type,
    required this.isVip,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isInside = e.isInside;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Row: avatar + name + badges + menu ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.85),
                            accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _initials(e.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + badges + subtitle + card
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badges row (flex-safe)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  e.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (isVip) ...[
                                const SizedBox(width: 6),
                                const HighlightBadge(label: 'VIP'),
                              ],
                              if (type == EntryType.boss &&
                                  e.category != null &&
                                  e.category != BossCategory.regular) ...[
                                const SizedBox(width: 6),
                                HighlightBadge(category: e.category),
                              ],
                            ],
                          ),

                          // Subtitle
                          if (e.subtitle != null && e.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              e.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],

                          // Card number pill
                          if (e.cardNumber != null &&
                              e.cardNumber!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F1F5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    size: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      e.cardNumber!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Popup menu
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      onSelected: (v) {
                        final p = context.read<EntriesProvider>();
                        if (v == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntryFormScreen(
                                type: type,
                                title: EntryType.label(type),
                                existing: e,
                              ),
                            ),
                          );
                        } else if (v == 'reopen') {
                          p.reopen(e.id!);
                        } else if (v == 'delete') {
                          p.deleteEntry(e.id!);
                        } else if (v == 'link_boss') {
                          _showLinkBossDialog(context, e.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        _menuItem('edit', Icons.edit_rounded, 'Edit'),
                        if (type == EntryType.car && e.isInside)
                          _menuItem('link_boss', Icons.link_rounded,
                              'Link a Boss riding this car'),
                        if (e.outTime != null)
                          _menuItem('reopen', Icons.undo_rounded,
                              'Undo Checkout'),
                        _menuItem('delete', Icons.delete_outline_rounded,
                            'Delete',
                            color: Colors.red),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // ─── Status chip ───
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isInside
                        ? const Color(0xFF00B894).withValues(alpha: 0.12)
                        : const Color(0xFF95A5A6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isInside
                              ? const Color(0xFF00B894)
                              : const Color(0xFF95A5A6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isInside ? 'Inside' : 'Checked Out',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isInside
                              ? const Color(0xFF00B894)
                              : const Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ─── Times (full width, safe) ───
                SizedBox(
                  width: double.infinity,
                  child: InOutTimeRow(
                    inTimeText: AppDate.dateTime(e.inTime),
                    outTimeText:
                        e.outTime != null ? AppDate.dateTime(e.outTime) : null,
                  ),
                ),

                // ─── Checkout button ───
                if (isInside) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: InOutButton(
                      isIn: false,
                      onPressed: () async {
                        final p = context.read<EntriesProvider>();
                        await p.checkOut(e.id!);
                        if (type == EntryType.car) {
                          await p.checkOutLinkedBoss(e.id!);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey.shade700),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color accentColor;

  const _EmptyState({
    required this.message,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color: accentColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the button below to add one',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}