import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/entry_model.dart';
import '../../providers/entries_provider.dart';
import '../../providers/guards_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/calendar_and_phone_provider.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/highlight_badge.dart';
import '../../widgets/in_out_button.dart';
import '../../widgets/section_card.dart';
import '../entries/entry_list_screen.dart';
import '../guards/guard_list_screen.dart';
import '../calendar/calendar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<EntriesProvider>();
    final guards = context.watch<GuardsProvider>();
    final settings = context.watch<SettingsProvider>();
    final cal = context.watch<CalendarProvider>();

    final insideCar = entries.currentlyInside(EntryType.car);
    final insideCompanyCar = entries.currentlyInside(EntryType.companyCar);
    final insideBoss = entries.currentlyInside(EntryType.boss);
    final insideWorker = entries.currentlyInside(EntryType.outsideWorker);
    final insideSupplier = entries.currentlyInside(EntryType.supplier);
    final insideBuyer = entries.currentlyInside(EntryType.buyer);
    final insideAudit = entries.currentlyInside(EntryType.audit);
    final onDutyGuards = guards.onDutyGuards;
    final reminders = cal.remindersForTomorrow;

    final totalInside = insideCar.length +
        insideCompanyCar.length +
        insideBoss.length +
        insideWorker.length +
        insideSupplier.length +
        insideBuyer.length +
        insideAudit.length;

    final companyName = settings.settings.companyName.isEmpty
        ? 'CoreAxis'
        : settings.settings.companyName;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await entries.load();
          await guards.load();
          await cal.load();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ============ PREMIUM HEADER ============
            SliverToBoxAdapter(
              child: _PremiumHeader(
                companyName: companyName,
                totalInside: totalInside,
                onDuty: onDutyGuards.length,
                animation: _headerController,
                reminders: reminders,
              ),
            ),

            // ============ CONTENT ============
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick stats row (mobile-friendly)
                  _AnimatedEntry(
                    animation: _contentController,
                    delay: 0.0,
                    child: _StatsRow(
                      totalInside: totalInside,
                      onDuty: onDutyGuards.length,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // VIP Section
                  if (insideBuyer.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.05,
                      child: _ModernSection(
                        title: 'Buyers Inside',
                        subtitle: 'VIP visitors currently on premises',
                        icon: Icons.workspace_premium_rounded,
                        gradient: const [Color(0xFFFFB74D), Color(0xFFFF8A65)],
                        onSeeAll: () =>
                            _openList(context, EntryType.buyer, 'Buyers'),
                        child: _EntryMiniList(
                          entries: insideBuyer,
                          highlightVip: true,
                        ),
                      ),
                    ),

                  if (insideAudit.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.1,
                      child: _ModernSection(
                        title: 'Audit Inside',
                        subtitle: 'Audit team on premises',
                        icon: Icons.fact_check_rounded,
                        gradient: const [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                        onSeeAll: () =>
                            _openList(context, EntryType.audit, 'Audit'),
                        child: _EntryMiniList(
                          entries: insideAudit,
                          highlightVip: true,
                        ),
                      ),
                    ),

                  if (insideBoss.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.15,
                      child: _ModernSection(
                        title: 'Bosses Inside',
                        subtitle: 'Management currently in office',
                        icon: Icons.badge_rounded,
                        gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        onSeeAll: () =>
                            _openList(context, EntryType.boss, 'Boss Entry'),
                        child: _EntryMiniList(
                          entries: insideBoss,
                          showCategory: true,
                        ),
                      ),
                    ),

                  if (insideCompanyCar.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.2,
                      child: _ModernSection(
                        title: 'Company Cars Out',
                        subtitle: 'Fleet vehicles in use',
                        icon: Icons.directions_car_filled_rounded,
                        gradient: const [Color(0xFF26A69A), Color(0xFF00897B)],
                        onSeeAll: () => _openList(
                            context, EntryType.companyCar, 'Company Cars'),
                        child: _CompanyCarInfoList(entries: insideCompanyCar),
                      ),
                    ),

                  if (insideCar.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.25,
                      child: _ModernSection(
                        title: 'Cars Inside',
                        subtitle: 'Visitor vehicles on premises',
                        icon: Icons.local_taxi_rounded,
                        gradient: const [Color(0xFFEC407A), Color(0xFFD81B60)],
                        onSeeAll: () =>
                            _openList(context, EntryType.car, 'Car Entry'),
                        child: _EntryMiniList(entries: insideCar),
                      ),
                    ),

                  if (insideWorker.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.3,
                      child: _ModernSection(
                        title: 'Outside Workers',
                        subtitle: 'External workers currently inside',
                        icon: Icons.engineering_rounded,
                        gradient: const [Color(0xFFFFA726), Color(0xFFFB8C00)],
                        onSeeAll: () => _openList(
                            context, EntryType.outsideWorker, 'Outside Workers'),
                        child: _EntryMiniList(entries: insideWorker),
                      ),
                    ),

                  if (insideSupplier.isNotEmpty)
                    _AnimatedEntry(
                      animation: _contentController,
                      delay: 0.35,
                      child: _ModernSection(
                        title: 'Suppliers Inside',
                        subtitle: 'Delivery & supply personnel',
                        icon: Icons.local_shipping_rounded,
                        gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                        onSeeAll: () =>
                            _openList(context, EntryType.supplier, 'Suppliers'),
                        child: _EntryMiniList(entries: insideSupplier),
                      ),
                    ),

                  // Guards Section
                  _AnimatedEntry(
                    animation: _contentController,
                    delay: 0.4,
                    child: _ModernSection(
                      title: 'On-Duty Guards',
                      subtitle: onDutyGuards.isEmpty
                          ? 'No guards marked on duty yet'
                          : '${onDutyGuards.length} guards are active today',
                      icon: Icons.security_rounded,
                      gradient: const [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GuardListScreen()),
                      ),
                      child: onDutyGuards.isEmpty
                          ? const _EmptyGuards()
                          : _GuardChipsList(guards: onDutyGuards),
                    ),
                  ),

                  // Empty state for everything
                  if (totalInside == 0 && onDutyGuards.isEmpty)
                    const _FullEmptyState(),

                  const SizedBox(height: 20),

                  // Calendar CTA
                  _AnimatedEntry(
                    animation: _contentController,
                    delay: 0.45,
                    child: _CalendarCTA(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CalendarScreen()),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openList(BuildContext context, String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EntryListScreen(type: type, title: title)),
    );
  }
}

// ================================================================
// PREMIUM HEADER WITH GRADIENT + LIVE STATS
// ================================================================
class _PremiumHeader extends StatelessWidget {
  final String companyName;
  final int totalInside;
  final int onDuty;
  final Animation<double> animation;
  final List reminders;

  const _PremiumHeader({
    required this.companyName,
    required this.totalInside,
    required this.onDuty,
    required this.animation,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(animation.value);
        return Transform.translate(
          offset: Offset(0, (1 - v) * -30),
          child: Opacity(opacity: v, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A00E0),
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A00E0).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: greeting + notification
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle,
                                    size: 8, color: Color(0xFF69F0AE)),
                                SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _greeting(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.shield_moon_rounded,
                      color: Colors.white, size: 24),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Stat pills inside header
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    label: 'Inside',
                    value: '$totalInside',
                    icon: Icons.groups_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderStat(
                    label: 'On Duty',
                    value: '$onDuty',
                    icon: Icons.verified_user_rounded,
                  ),
                ),
              ],
            ),

            // Reminders
            if (reminders.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ReminderPill(reminders: reminders),
            ],
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 👋';
    if (h < 17) return 'Good Afternoon ☀️';
    if (h < 21) return 'Good Evening 🌆';
    return 'Good Night 🌙';
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderPill extends StatelessWidget {
  final List reminders;
  const _ReminderPill({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final first = reminders.first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded,
                color: Color(0xFFE65100), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reminder for Tomorrow',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminders.length == 1
                      ? first.title
                      : '${first.title} +${reminders.length - 1} more',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D4C41),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// STATS ROW (Mobile view)
// ================================================================
class _StatsRow extends StatelessWidget {
  final int totalInside;
  final int onDuty;

  const _StatsRow({required this.totalInside, required this.onDuty});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModernStatCard(
            label: 'Currently Inside',
            value: '$totalInside',
            icon: Icons.groups_rounded,
            gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModernStatCard(
            label: 'Guards On Duty',
            value: '$onDuty',
            icon: Icons.security_rounded,
            gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          ),
        ),
      ],
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _ModernStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MODERN SECTION CARD
// ================================================================
class _ModernSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback? onSeeAll;
  final Widget child;

  const _ModernSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.child,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient accent
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSeeAll != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSeeAll,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: gradient.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: gradient.last,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: gradient.last),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider line
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey.shade100,
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// COMPANY CAR INFO LIST (No checkout button - info only)
// Shows WHO is riding (read from entry.extra['ridingBoss'])
// ================================================================
class _CompanyCarInfoList extends StatelessWidget {
  final List<EntryModel> entries;

  const _CompanyCarInfoList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final shown = entries.take(4).toList();
    return Column(
      children: [
        ...shown.map((e) => _CompanyCarInfoRow(entry: e)),
        if (entries.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${entries.length - shown.length} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompanyCarInfoRow extends StatelessWidget {
  final EntryModel entry;

  const _CompanyCarInfoRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    // Car name/number is stored in entry.name (e.g. "ABC-1234")
    final carLabel = entry.name;
    // "Who is riding" is stored in entry.extra['ridingBoss']
    final ridingValue = entry.extra['ridingBoss'];
    final ridingText =
        (ridingValue != null && ridingValue.toString().trim().isNotEmpty)
            ? ridingValue.toString().trim()
            : null;

    final initials = _initials(carLabel);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (shows car initials)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF00897B)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Car name + riding info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Car number/name
                Text(
                  carLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),

                // "Who is riding" — from extra['ridingBoss']
                if (ridingText != null)
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_rounded,
                          size: 13, color: Color(0xFF00897B)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Riding: $ridingText',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF00897B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Riding: not specified',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Time badge (info only, no button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.login_rounded,
                        size: 11, color: Color(0xFF00897B)),
                    const SizedBox(width: 3),
                    Text(
                      AppDate.time(entry.inTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00897B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'OUT',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF00897B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ================================================================
// ENTRY MINI LIST (Redesigned)
// ================================================================
class _EntryMiniList extends StatelessWidget {
  final List<EntryModel> entries;
  final bool highlightVip;
  final bool showCategory;

  const _EntryMiniList({
    required this.entries,
    this.highlightVip = false,
    this.showCategory = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = entries.take(4).toList();
    return Column(
      children: [
        ...shown.map((e) => _EntryRow(
              entry: e,
              highlightVip: highlightVip,
              showCategory: showCategory,
            )),
        if (entries.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${entries.length - shown.length} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  final EntryModel entry;
  final bool highlightVip;
  final bool showCategory;

  const _EntryRow({
    required this.entry,
    required this.highlightVip,
    required this.showCategory,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(entry.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: highlightVip
                    ? const [Color(0xFFFFB74D), Color(0xFFFF8A65)]
                    : const [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + badge
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    entry.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                if (highlightVip ||
                    (showCategory &&
                        entry.category != null &&
                        entry.category != 'regular')) ...[
                  const SizedBox(width: 6),
                  HighlightBadge(
                    category: entry.category,
                    label: highlightVip ? 'VIP' : null,
                  ),
                ],
              ],
            ),
          ),

          // Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 11, color: Colors.grey.shade600),
                const SizedBox(width: 3),
                Text(
                  AppDate.time(entry.inTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Check-out button
          InOutButton(
            isIn: false,
            compact: true,
            onPressed: () =>
                context.read<EntriesProvider>().checkOut(entry.id!),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ================================================================
// GUARD CHIPS LIST
// ================================================================
class _GuardChipsList extends StatelessWidget {
  final List guards;
  const _GuardChipsList({required this.guards});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: guards.map<Widget>((g) {
        return Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF3F51B5)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3F51B5).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.shield_rounded,
                    size: 15, color: Color(0xFF3F51B5)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    g.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    GuardDesignation.label(g.designation),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyGuards extends StatelessWidget {
  const _EmptyGuards();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            'No guards marked on duty yet',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// FULL EMPTY STATE
// ================================================================
class _FullEmptyState extends StatelessWidget {
  const _FullEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6A11CB).withOpacity(0.15),
                  const Color(0xFF2575FC).withOpacity(0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.night_shelter_outlined,
              size: 42,
              color: Color(0xFF6A11CB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Quiet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nobody is currently inside the company.\nUse Features to add an entry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CALENDAR CTA
// ================================================================
class _CalendarCTA extends StatelessWidget {
  final VoidCallback onTap;
  const _CalendarCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1A2E).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open Calendar View',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'View schedule & upcoming reminders',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ANIMATED ENTRY WRAPPER
// ================================================================
class _AnimatedEntry extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;

  const _AnimatedEntry({
    required this.animation,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay.clamp(0.0, 0.9);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        return Transform.translate(
          offset: Offset(0, (1 - curved.value) * 24),
          child: Opacity(opacity: curved.value, child: c),
        );
      },
      child: child,
    );
  }
}