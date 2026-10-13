import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/entry_model.dart';
import '../../providers/entries_provider.dart';
import '../../widgets/quick_suggestion_field.dart';

class EntryFormScreen extends StatefulWidget {
  final String type;
  final String title;
  final EntryModel? existing;

  const EntryFormScreen({
    super.key,
    required this.type,
    required this.title,
    this.existing,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();

  final _carNoCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _seeingWhomCtrl = TextEditingController();

  String _category = BossCategory.regular;
  String _bossSource = BossSource.house;
  bool _saveAsFrequent = true;
  bool _saving = false;

  // ── theme colors ─────────────────────────────────────────
  static const _primary = Color(0xFF4F46E5);
  static const _primaryDark = Color(0xFF4338CA);
  static const _bg = Color(0xFFF5F6FA);
  static const _cardBg = Colors.white;
  static const _border = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _subtitleCtrl.text = e.subtitle ?? '';
      _phoneCtrl.text = e.phone ?? '';
      _cardCtrl.text = e.cardNumber ?? '';
      _carNoCtrl.text = e.extra['carNo']?.toString() ?? '';
      _licenseCtrl.text = e.extra['driverLicense']?.toString() ?? '';
      _driverPhoneCtrl.text = e.extra['driverPhone']?.toString() ?? '';
      _seeingWhomCtrl.text = e.extra['seeingWhom']?.toString() ?? '';
      _category = e.category ?? BossCategory.regular;
      _bossSource = e.extra['source']?.toString() ?? BossSource.house;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _phoneCtrl.dispose();
    _cardCtrl.dispose();
    _carNoCtrl.dispose();
    _licenseCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _seeingWhomCtrl.dispose();
    super.dispose();
  }

  bool get _isBoss => widget.type == EntryType.boss;
  bool get _isCar =>
      widget.type == EntryType.car || widget.type == EntryType.companyCar;

  Map<String, dynamic> _buildExtra() {
    switch (widget.type) {
      case EntryType.car:
      case EntryType.companyCar:
        return {
          'carNo': _carNoCtrl.text.trim(),
          'driverLicense': _licenseCtrl.text.trim(),
          'driverPhone': _driverPhoneCtrl.text.trim(),
        };
      case EntryType.boss:
        return {
          'designation': _subtitleCtrl.text.trim(),
          'source': _bossSource,
        };
      case EntryType.outsideWorker:
        return {
          'seeingWhom': _seeingWhomCtrl.text.trim(),
          'purpose': _subtitleCtrl.text.trim(),
        };
      default:
        return {};
    }
  }

  void _showSnack(String msg, {Color? color, IconData? icon}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: color ?? const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack(
        _isCar ? 'Driver name is required' : 'Name is required',
        color: const Color(0xFFDC2626),
        icon: Icons.error_outline,
      );
      return;
    }
    if (_isCar && _carNoCtrl.text.trim().isEmpty) {
      _showSnack(
        'Car number is required',
        color: const Color(0xFFDC2626),
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<EntriesProvider>();
      final entry = EntryModel(
        id: widget.existing?.id,
        type: widget.type,
        name: _nameCtrl.text.trim(),
        subtitle: _isCar ? null : _subtitleCtrl.text.trim(),
        category: _isBoss ? _category : null,
        phone: _phoneCtrl.text.trim(),
        cardNumber: _cardCtrl.text.trim(),
        extra: _buildExtra(),
        inTime: widget.existing?.inTime ?? DateTime.now(),
        outTime: widget.existing?.outTime,
        createdAt: widget.existing?.createdAt,
      );

      if (widget.existing != null) {
        await provider.updateEntry(entry);
      } else {
        await provider.checkIn(entry, saveAsFrequent: _saveAsFrequent);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack(
        'Something went wrong: $e',
        color: const Color(0xFFDC2626),
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates =
        context.watch<EntriesProvider>().templatesFor(widget.type);
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _cardBg,
        foregroundColor: const Color(0xFF111827),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit' : 'New',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              // ── NAME / QUICK SUGGESTION ─────────────────────
              if (!isEditing && templates.isNotEmpty)
                _Section(
                  icon: Icons.bolt_rounded,
                  title: 'Quick Check-in',
                  subtitle: 'Tap a regular to check in instantly',
                  child: QuickSuggestionField(
                    label: _isCar ? 'Driver Name' : 'Name',
                    controller: _nameCtrl,
                    templates: templates,
                    onChanged: (_) {},
                    onSuggestionTap: (tpl) async {
                      await context
                          .read<EntriesProvider>()
                          .oneClickCheckIn(tpl);
                      if (!mounted) return;
                      _showSnack(
                        '${tpl.name} checked in',
                        color: const Color(0xFF059669),
                        icon: Icons.check_circle_outline,
                      );
                      Navigator.pop(context);
                    },
                  ),
                )
              else
                _Section(
                  icon: Icons.person_outline_rounded,
                  title: _isCar ? 'Driver Information' : 'Basic Information',
                  child: _LabeledField(
                    label: _isCar ? 'Driver Name' : 'Name',
                    controller: _nameCtrl,
                    hint: _isCar ? 'e.g. Rahim Uddin' : 'Enter full name',
                    icon: Icons.person_outline_rounded,
                    isRequired: true,
                  ),
                ),

              const SizedBox(height: 16),

              // ── TYPE SPECIFIC FIELDS ───────────────────────
              if (_isCar) _buildCarFields(),
              if (_isBoss) _buildBossFields(),
              if (widget.type == EntryType.outsideWorker)
                _buildOutsideWorkerFields(),
              if (widget.type == EntryType.supplier) _buildSupplierFields(),
              if (widget.type == EntryType.buyer ||
                  widget.type == EntryType.audit)
                _buildBuyerFields(),

              // ── SAVE AS FREQUENT ──────────────────────────
              if (!isEditing) ...[
                const SizedBox(height: 16),
                _FrequentToggle(
                  value: _saveAsFrequent,
                  onChanged: (v) => setState(() => _saveAsFrequent = v),
                ),
              ],
            ],
          ),
        ),
      ),

      // ── STICKY CTA ───────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: _cardBg,
          border: const Border(top: BorderSide(color: _border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _PrimaryButton(
          label: isEditing ? 'Save Changes' : 'Check IN Now',
          icon: isEditing ? Icons.save_rounded : Icons.login_rounded,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ),
    );
  }

  // ── CAR FIELDS ─────────────────────────────────────
  Widget _buildCarFields() {
    return _Section(
      icon: Icons.directions_car_outlined,
      title: 'Vehicle & Driver Details',
      subtitle: 'Fields marked * are required',
      child: Column(
        children: [
          _LabeledField(
            label: 'Car Number',
            controller: _carNoCtrl,
            hint: 'e.g. DHA-GA-1234',
            icon: Icons.confirmation_number_outlined,
            isRequired: true,
            textCapitalization: TextCapitalization.characters,
          ),
          _gap,
          _LabeledField(
            label: 'Driver License Number',
            controller: _licenseCtrl,
            hint: 'Enter license number',
            icon: Icons.badge_outlined,
          ),
          _gap,
          _LabeledField(
            label: 'Driver Phone',
            controller: _driverPhoneCtrl,
            hint: '+880 1XXX-XXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
          ),
          _gap,
          _LabeledField(
            label: 'Access Card No.',
            controller: _cardCtrl,
            hint: 'Optional',
            icon: Icons.credit_card_outlined,
          ),
          _gap,
          _LabeledField(
            label: 'Company Name',
            controller: _subtitleCtrl,
            hint: 'Which company the car came from',
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }

  // ── BOSS FIELDS ────────────────────────────────────
  Widget _buildBossFields() {
    return _Section(
      icon: Icons.workspace_premium_outlined,
      title: 'Boss Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            label: 'Designation',
            controller: _subtitleCtrl,
            hint: 'e.g. Head of Finance',
            icon: Icons.work_outline_rounded,
          ),
          _gap,
          _DropdownField<String>(
            label: 'Category',
            value: _category,
            icon: Icons.category_outlined,
            items: BossCategory.all
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(BossCategory.label(c)),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? BossCategory.regular),
          ),
          _gap,
          const _MiniLabel('Entry Source'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              selectedBackgroundColor: _primary,
              selectedForegroundColor: Colors.white,
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            segments: const [
              ButtonSegment(
                value: BossSource.house,
                label: Text('From House'),
                icon: Icon(Icons.home_outlined, size: 18),
              ),
              ButtonSegment(
                value: BossSource.car,
                label: Text('By Car'),
                icon: Icon(Icons.directions_car_outlined, size: 18),
              ),
            ],
            selected: {_bossSource},
            onSelectionChanged: (s) =>
                setState(() => _bossSource = s.first),
          ),
          const SizedBox(height: 10),
          _InfoBanner(
            icon: _bossSource == BossSource.car
                ? Icons.lightbulb_outline
                : Icons.info_outline,
            text: _bossSource == BossSource.car
                ? 'Tip: if this boss is riding in a car that just checked in, use "Link to Car" from the Car Entry screen — it auto check-ins the boss.'
                : 'House entries need a manual IN and OUT.',
            color: _bossSource == BossSource.car
                ? const Color(0xFFF59E0B)
                : _primary,
          ),
        ],
      ),
    );
  }

  // ── OUTSIDE WORKER ─────────────────────────────────
  Widget _buildOutsideWorkerFields() {
    return _Section(
      icon: Icons.engineering_outlined,
      title: 'Worker Details',
      child: Column(
        children: [
          _LabeledField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            hint: '+880 1XXX-XXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _gap,
          _LabeledField(
            label: 'Purpose of Visit',
            controller: _subtitleCtrl,
            hint: 'e.g. AC repair, Electric work',
            icon: Icons.flag_outlined,
          ),
          _gap,
          _LabeledField(
            label: 'Seeing Whom',
            controller: _seeingWhomCtrl,
            hint: 'Which Sir / Staff',
            icon: Icons.person_search_outlined,
          ),
          _gap,
          _LabeledField(
            label: 'Visitor Card No.',
            controller: _cardCtrl,
            hint: 'Optional',
            icon: Icons.credit_card_outlined,
          ),
        ],
      ),
    );
  }

  // ── SUPPLIER ───────────────────────────────────────
  Widget _buildSupplierFields() {
    return _Section(
      icon: Icons.local_shipping_outlined,
      title: 'Supplier Details',
      child: Column(
        children: [
          _LabeledField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            hint: '+880 1XXX-XXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _gap,
          _LabeledField(
            label: 'Company Name',
            controller: _subtitleCtrl,
            hint: 'Supplier company',
            icon: Icons.business_outlined,
          ),
          _gap,
          _LabeledField(
            label: 'Card No.',
            controller: _cardCtrl,
            hint: 'Optional',
            icon: Icons.credit_card_outlined,
          ),
        ],
      ),
    );
  }

  // ── BUYER / AUDIT ──────────────────────────────────
  Widget _buildBuyerFields() {
    return _Section(
      icon: Icons.handshake_outlined,
      title: 'Visitor Details',
      child: Column(
        children: [
          _LabeledField(
            label: 'Company Name',
            controller: _subtitleCtrl,
            hint: 'Company / organization',
            icon: Icons.business_outlined,
          ),
          _gap,
          _LabeledField(
            label: 'Card No.',
            controller: _cardCtrl,
            hint: 'Optional',
            icon: Icons.credit_card_outlined,
          ),
        ],
      ),
    );
  }

  static const _gap = SizedBox(height: 14);
}

// ═══════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final String text;
  const _MiniLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
        letterSpacing: 0.6,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final bool isRequired;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.isRequired = false,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MiniLabel(label),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: const Color(0xFF6B7280))
                : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: const Color(0xFF6B7280))
                : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: color.withOpacity(0.95),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequentToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FrequentToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF4F46E5).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? const Color(0xFF4F46E5).withOpacity(0.4)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bookmark_added_outlined,
                size: 18,
                color: value ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remember as a regular',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'For one-click entry next time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF4F46E5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(
                  colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
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
}