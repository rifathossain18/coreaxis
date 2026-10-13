import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../entries/company_car_screen.dart';
import '../entries/entry_list_screen.dart';
import '../guards/guard_list_screen.dart';
import '../roster/roster_screen.dart';
import '../phone/phone_directory_screen.dart';
import '../calendar/calendar_screen.dart';

class _FeatureItem {
  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  final String category;

  _FeatureItem(
    this.title,
    this.icon,
    this.color,
    this.builder, {
    this.category = 'General',
  });
}

class AllFeaturesScreen extends StatefulWidget {
  const AllFeaturesScreen({super.key});

  @override
  State<AllFeaturesScreen> createState() => _AllFeaturesScreenState();
}

class _AllFeaturesScreenState extends State<AllFeaturesScreen> {
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_FeatureItem> _allFeatures = [
    // Entry
    _FeatureItem('Car Entry', Icons.local_taxi, AppColors.primary,
        (_) => const EntryListScreen(type: 'car', title: 'Car Entry'),
        category: 'Entry'),
    _FeatureItem('Company Cars', Icons.directions_car, AppColors.accent,
        (_) => const CompanyCarScreen(),
        category: 'Entry'),
    _FeatureItem('Boss Entry', Icons.badge, AppColors.md,
        (_) => const EntryListScreen(type: 'boss', title: 'Boss Entry'),
        category: 'Entry'),
    _FeatureItem('Outside Worker', Icons.engineering, AppColors.warning,
        (_) => const EntryListScreen(type: 'outside_worker', title: 'Outside Worker'),
        category: 'Entry'),
    _FeatureItem('Supplier Entry', Icons.local_shipping, AppColors.success,
        (_) => const EntryListScreen(type: 'supplier', title: 'Supplier Entry'),
        category: 'Entry'),
    _FeatureItem('Buyer Entry', Icons.workspace_premium, AppColors.buyer,
        (_) => const EntryListScreen(type: 'buyer', title: 'Buyer Entry'),
        category: 'Entry'),
    _FeatureItem('Audit Entry', Icons.fact_check, AppColors.audit,
        (_) => const EntryListScreen(type: 'audit', title: 'Audit Entry'),
        category: 'Entry'),

    // Management
    _FeatureItem('Security Guards', Icons.security, AppColors.primaryDark,
        (_) => const GuardListScreen(),
        category: 'Management'),
    _FeatureItem('Duty Roster', Icons.calendar_view_month, AppColors.director,
        (_) => const RosterScreen(),
        category: 'Management'),

    // Utilities
    _FeatureItem('Phone Directory', Icons.contact_phone, AppColors.chairman,
        (_) => const PhoneDirectoryScreen(),
        category: 'Utilities'),
    _FeatureItem('Calendar View', Icons.calendar_month, AppColors.danger,
        (_) => const CalendarScreen(),
        category: 'Utilities'),
  ];

  List<_FeatureItem> get _filtered => _allFeatures
      .where((f) => f.title.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  Map<String, List<_FeatureItem>> get _grouped {
    final map = <String, List<_FeatureItem>>{};
    for (final f in _filtered) {
      map.putIfAbsent(f.category, () => []).add(f);
    }
    return map;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F7FB),
      body: CustomScrollView(
        slivers: [
          // ─────────── Gradient AppBar ───────────
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: const Text(
                'All Features',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      bottom: -40,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─────────── Search Bar ───────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search features...',
                    prefixIcon: Icon(Icons.search,
                        color: AppColors.primary.withOpacity(0.8)),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  ),
                ),
              ),
            ),
          ),

          // ─────────── Grouped Feature Grids ───────────
          for (final entry in grouped.entries) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final f = entry.value[i];
                    return _FeatureCard(item: f);
                  },
                  childCount: entry.value.length,
                ),
              ),
            ),
          ],

          // ─────────── Empty State ───────────
          if (grouped.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No features found',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─────────── Feature Card Widget ───────────
class _FeatureCard extends StatefulWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.item;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTapDown: (_) => _ctrl.reverse(),
          onTapUp: (_) => _ctrl.forward(),
          onTapCancel: () => _ctrl.forward(),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: f.builder),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1F26) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: f.color.withOpacity(isDark ? 0.18 : 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: f.color.withOpacity(isDark ? 0.25 : 0.08),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          f.color.withOpacity(0.9),
                          f.color.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: f.color.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(f.icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    f.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        f.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: f.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: f.color.withOpacity(0.7),
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
}