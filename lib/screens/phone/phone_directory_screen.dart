import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/misc_models.dart';
import '../../providers/calendar_and_phone_provider.dart';
import '../../utils/app_helpers.dart';

class PhoneDirectoryScreen extends StatefulWidget {
  const PhoneDirectoryScreen({super.key});

  @override
  State<PhoneDirectoryScreen> createState() => _PhoneDirectoryScreenState();
}

class _PhoneDirectoryScreenState extends State<PhoneDirectoryScreen> {
  // ─── Palette ───
  static const _bg1 = Color(0xFF0B1020);
  static const _bg2 = Color(0xFF161B3D);
  static const _bg3 = Color(0xFF0A1628);
  static const _accent = Color(0xFF6EE7F9);
  static const _accent2 = Color(0xFF8B5CF6);
  static const _glass = Colors.white;

  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _collapsed = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhoneProvider>();
    final depts = provider.departments;
    final allContacts = provider.contacts;

    // filtering
    final filtered = _query.isEmpty
        ? allContacts
        : allContacts.where((c) {
            final q = _query.toLowerCase();
            return c.name.toLowerCase().contains(q) ||
                (c.designation ?? '').toLowerCase().contains(q) ||
                (c.department ?? '').toLowerCase().contains(q) ||
                (c.mobile ?? '').contains(q) ||
                (c.telephone ?? '').contains(q);
          }).toList();

    // grouping
    final grouped = <String, List<PhoneContact>>{};
    for (final d in depts) {
      final list = filtered.where((c) => c.department == d).toList();
      if (list.isNotEmpty) grouped[d] = list;
    }
    final otherList =
        filtered.where((c) => !depts.contains(c.department)).toList();
    if (otherList.isNotEmpty) grouped['Other'] = otherList;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _bg1,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bg1, _bg2, _bg3],
          ),
        ),
        child: Stack(
          children: [
            // decorative glows
            Positioned(
              top: -80,
              right: -60,
              child: _glow(_accent.withOpacity(0.35), 240),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _glow(_accent2.withOpacity(0.30), 260),
            ),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(provider.contacts.length, depts.length),
                _buildSearchSliver(),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(
                      _query.isEmpty
                          ? 'No contacts saved yet'
                          : 'No results for "$_query"',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final entry = grouped.entries.elementAt(i);
                          return _departmentCard(entry.key, entry.value);
                        },
                        childCount: grouped.length,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: _fab(context),
    );
  }

  // ───────────────────── Decorative Glow ─────────────────────
  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      );

  // ───────────────────── Sliver AppBar ─────────────────────
  Widget _buildSliverAppBar(int contactCount, int deptCount) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 200,
      backgroundColor: _bg1.withOpacity(0.65),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accent.withOpacity(0.18),
                    _accent2.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_accent, _accent2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accent.withOpacity(0.5),
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.contact_phone_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Directory',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Find & call your team instantly',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statPill(Icons.people_alt_rounded,
                          '$contactCount Contacts'),
                      const SizedBox(width: 10),
                      _statPill(Icons.apartment_rounded,
                          '$deptCount Departments'),
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

  Widget _statPill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _glass.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _glass.withOpacity(0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );

  // ───────────────────── Search Bar ─────────────────────
  Widget _buildSearchSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: _glass.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _glass.withOpacity(0.18)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: const TextStyle(color: Colors.white),
                cursorColor: _accent,
                decoration: InputDecoration(
                  hintText: 'Search by name, dept, number...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13.5),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: _accent),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Department Card ─────────────────────
  Widget _departmentCard(String dept, List<PhoneContact> list) {
    final isCollapsed = _collapsed.contains(dept);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: _glass.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _glass.withOpacity(0.16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => setState(() {
                    if (isCollapsed) {
                      _collapsed.remove(dept);
                    } else {
                      _collapsed.add(dept);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _accent.withOpacity(0.35),
                                _accent2.withOpacity(0.25),
                              ],
                            ),
                            border: Border.all(
                                color: _accent.withOpacity(0.45)),
                          ),
                          child: const Icon(Icons.apartment_rounded,
                              color: _accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dept,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _accent.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${list.length}',
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: isCollapsed ? 0 : 0.5,
                          duration: const Duration(milliseconds: 220),
                          child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: isCollapsed
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: Column(
                      children: list.map((c) => _contactTile(c)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Contact Tile ─────────────────────
  Widget _contactTile(PhoneContact c) {
    final subtitleParts = <String>[];
    if (c.designation?.isNotEmpty ?? false) {
      subtitleParts.add(c.designation!);
    }
    if (c.mobile?.isNotEmpty ?? false) subtitleParts.add(c.mobile!);
    if (c.telephone?.isNotEmpty ?? false) {
      subtitleParts.add('Ext. ${c.telephone}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: () => _confirmDelete(c),
              borderRadius: BorderRadius.circular(16),
              splashColor: _accent.withOpacity(0.15),
              highlightColor: _accent.withOpacity(0.08),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _glass.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _glass.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            _accent.withOpacity(0.9),
                            _accent2.withOpacity(0.9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.35),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(c.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
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
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                          if (subtitleParts.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitleParts.join(' • '),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _callButton(c),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Call Button → Dialer ─────────────────────
  Widget _callButton(PhoneContact c) {
    final number = (c.mobile?.isNotEmpty ?? false)
        ? c.mobile!
        : (c.telephone ?? '');

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.25),
            AppColors.success.withOpacity(0.10),
          ],
        ),
        border:
            Border.all(color: AppColors.success.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.30),
            blurRadius: 14,
          ),
        ],
      ),
      child: IconButton(
        iconSize: 18,
        icon: const Icon(Icons.call_rounded,
            color: AppColors.success),
        tooltip: 'Call $number',
        onPressed: () async {
          if (number.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No phone number available'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
          await DialerHelper.call(number);
        },
      ),
    );
  }

  // ───────────────────── FAB ─────────────────────
  Widget _fab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.45),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _accent2.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accent.withOpacity(0.95),
                  _accent2.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border:
                  Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white),
              label: const Text(
                'Add Contact',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Empty State ─────────────────────
  Widget _emptyState(String message) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _glass.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _glass.withOpacity(0.20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_accent, _accent2],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withOpacity(0.45),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.contacts_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Helpers ─────────────────────
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  // ───────────────────── CONFIRM DELETE ─────────────────────
  Future<void> _confirmDelete(PhoneContact c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => _glassDialog(
        title: 'Delete Contact?',
        content: 'Remove ${c.name} from the directory?',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && c.id != null && mounted) {
      await context.read<PhoneProvider>().delete(c.id!);
    }
  }

  // ───────────────────── SHOW ADD DIALOG ─────────────────────
  Future<void> _showAddDialog(BuildContext context) async {
   
    final nameCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final telCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    try {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Add Contact',
        barrierColor: Colors.black.withOpacity(0.65),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, anim, _, __) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: _addContactDialog(
                ctx,
                formKey: formKey,
                nameCtrl: nameCtrl,
                designationCtrl: designationCtrl,
                deptCtrl: deptCtrl,
                mobileCtrl: mobileCtrl,
                telCtrl: telCtrl,
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Add contact dialog error: $e');
    }
    
  }

  // ───────────────────── ADD CONTACT DIALOG UI ─────────────────────
  Widget _addContactDialog(
    BuildContext ctx, {
    required GlobalKey<FormState> formKey,
    required TextEditingController nameCtrl,
    required TextEditingController designationCtrl,
    required TextEditingController deptCtrl,
    required TextEditingController mobileCtrl,
    required TextEditingController telCtrl,
  }) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _bg2.withOpacity(0.95),
                    _bg1.withOpacity(0.98),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                  BoxShadow(
                    color: _accent.withOpacity(0.15),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Basic Information',
                                Icons.info_outline_rounded),
                            const SizedBox(height: 12),
                            _GlassField(
                              controller: nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              required: true,
                              textCapitalization:
                                  TextCapitalization.words,
                            ),
                            const SizedBox(height: 14),
                            _GlassField(
                              controller: designationCtrl,
                              label: 'Designation',
                              icon: Icons.badge_outlined,
                              textCapitalization:
                                  TextCapitalization.words,
                            ),
                            const SizedBox(height: 14),
                            _GlassField(
                              controller: deptCtrl,
                              label: 'Department',
                              icon: Icons.apartment_rounded,
                              textCapitalization:
                                  TextCapitalization.words,
                            ),
                            const SizedBox(height: 22),
                            _sectionLabel('Contact Details',
                                Icons.contact_phone_rounded),
                            const SizedBox(height: 12),
                            _GlassField(
                              controller: mobileCtrl,
                              label: 'Mobile Number',
                              icon: Icons.smartphone_rounded,
                              keyboard: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\-\s()]')),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _GlassField(
                              controller: telCtrl,
                              label: 'Telephone (Ext.)',
                              icon: Icons.phone_in_talk_outlined,
                              keyboard: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\-\s()]')),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _glassOutlinedButton(
                                    label: 'Cancel',
                                    icon: Icons.close_rounded,
                                    onTap: () {
                                      if (Navigator.of(ctx).canPop()) {
                                        Navigator.of(ctx).pop();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _gradientButton(
                                    label: 'Save Contact',
                                    icon: Icons.check_rounded,
                                    onTap: () => _handleSave(
                                      ctx,
                                      formKey: formKey,
                                      nameCtrl: nameCtrl,
                                      designationCtrl: designationCtrl,
                                      deptCtrl: deptCtrl,
                                      mobileCtrl: mobileCtrl,
                                      telCtrl: telCtrl,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── HANDLE SAVE (SAFE) ─────────────────────
  Future<void> _handleSave(
    BuildContext ctx, {
    required GlobalKey<FormState> formKey,
    required TextEditingController nameCtrl,
    required TextEditingController designationCtrl,
    required TextEditingController deptCtrl,
    required TextEditingController mobileCtrl,
    required TextEditingController telCtrl,
  }) async {
    
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    
    final navigator = Navigator.of(ctx);
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<PhoneProvider>(context, listen: false);
    final name = nameCtrl.text.trim();

    
    final newContact = PhoneContact(
      name: name,
      designation: designationCtrl.text.trim(),
      department:
          deptCtrl.text.trim().isEmpty ? 'Other' : deptCtrl.text.trim(),
      mobile: mobileCtrl.text.trim(),
      telephone: telCtrl.text.trim(),
    );

    try {
      
      await provider.add(newContact);

      if (navigator.mounted) navigator.pop();

     
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('$name added successfully')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      
      debugPrint('Save contact error: $e');
      if (navigator.mounted) navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ───────────────────── DIALOG HEADER ─────────────────────
  Widget _dialogHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withOpacity(0.22),
            _accent2.withOpacity(0.18),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_accent, _accent2]),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.55),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Contact',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fill in the details below',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── SECTION LABEL ─────────────────────
  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.20),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────── GRADIENT BUTTON ─────────────────────
  Widget _gradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [_accent, _accent2]),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────── GLASS OUTLINED BUTTON ─────────────────────
  Widget _glassOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────── GLASS DIALOG (Delete) ─────────────────────
  Widget _glassDialog({
    required String title,
    String? content,
    Widget? contentWidget,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 14),
                if (contentWidget != null) contentWidget,
                if (content != null)
                  Text(
                    content,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: w,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//                    GLASS TEXT FIELD WIDGET
// ═══════════════════════════════════════════════════════════════
class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final TextInputType? keyboard;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.keyboard,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  static const _accent = Color(0xFF6EE7F9);
  final _focus = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _hasFocus = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.keyboard,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: _accent,
      validator: widget.required
          ? (v) => (v == null || v.trim().isEmpty)
              ? 'This field is required'
              : null
          : null,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: _hasFocus ? _accent : Colors.white.withOpacity(0.65),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: _accent,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hasFocus
                ? _accent.withOpacity(0.20)
                : Colors.white.withOpacity(0.06),
            border: Border.all(
              color: _hasFocus
                  ? _accent.withOpacity(0.55)
                  : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Icon(
            widget.icon,
            color:
                _hasFocus ? _accent : Colors.white.withOpacity(0.65),
            size: 18,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _accent.withOpacity(0.85),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.redAccent.withOpacity(0.7),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.6,
          ),
        ),
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 11.5,
        ),
      ),
    );
  }
}