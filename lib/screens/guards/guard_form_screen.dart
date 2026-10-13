import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/guard_model.dart';
import '../../providers/guards_provider.dart';
import '../../utils/app_helpers.dart';

class GuardFormScreen extends StatefulWidget {
  final GuardModel? existing;
  const GuardFormScreen({super.key, this.existing});

  @override
  State<GuardFormScreen> createState() => _GuardFormScreenState();
}

class _GuardFormScreenState extends State<GuardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  DateTime? _joinDate;
  String _designation = GuardDesignation.guard;
  bool _shiftChangeAllowed = true;
  String _currentShift = ShiftCode.a;
  String _offDay = 'Saturday';

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      _nameCtrl.text = g.name;
      _idCtrl.text = g.idNumber ?? '';
      _phoneCtrl.text = g.phone ?? '';
      _joinDate = g.joinDate;
      _designation = g.designation;
      _shiftChangeAllowed = g.shiftChangeAllowed;
      _currentShift = g.currentShift;
      _offDay = g.offDay;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GuardsProvider>();
    final guard = GuardModel(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      idNumber: _idCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      joinDate: _joinDate,
      designation: _designation,
      shiftChangeAllowed: _shiftChangeAllowed,
      currentShift: _shiftChangeAllowed ? _currentShift : 'General',
      offDay: _shiftChangeAllowed ? _offDay : 'Friday',
      onDuty: widget.existing?.onDuty ?? false,
    );

    if (isEditing) {
      await provider.updateGuard(guard);
    } else {
      await provider.addGuard(guard);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────
  // Input Decoration
  // ─────────────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: Theme.of(context).primaryColor, width: 1.6),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Section Card
  // ─────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          isEditing ? 'Edit Guard' : 'Add New Guard',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // ── Personal Info ─────────────────────────────
            _sectionCard(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Full Name',
                    icon: Icons.badge_outlined,
                    hint: 'Enter guard name',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _idCtrl,
                  decoration: _inputDecoration(
                    label: 'ID Number',
                    icon: Icons.credit_card_outlined,
                    hint: 'e.g. GRD-001',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    hint: '+880 1XXX-XXXXXX',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Job Details ───────────────────────────────
            _sectionCard(
              title: 'Job Details',
              icon: Icons.work_outline,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _joinDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _joinDate = picked);
                  },
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      label: 'Join Date',
                      icon: Icons.calendar_today_outlined,
                    ),
                    child: Text(
                      _joinDate == null
                          ? 'Select a date'
                          : AppDate.date(_joinDate),
                      style: TextStyle(
                        color: _joinDate == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _designation,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Designation',
                    icon: Icons.military_tech_outlined,
                  ),
                  items: GuardDesignation.all
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              GuardDesignation.label(d),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _designation = v ?? GuardDesignation.guard),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Shift Settings ────────────────────────────
            _sectionCard(
              title: 'Shift Settings',
              icon: Icons.schedule_outlined,
              children: [
                // ✅ Custom Row instead of SwitchListTile (fixes overflow)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _shiftChangeAllowed
                        ? theme.primaryColor.withOpacity(0.06)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Rotating Shift',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Off = fixed "General" shift, off day locked to Friday',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _shiftChangeAllowed,
                        activeColor: theme.primaryColor,
                        onChanged: (v) =>
                            setState(() => _shiftChangeAllowed = v),
                      ),
                    ],
                  ),
                ),
                if (_shiftChangeAllowed) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _currentShift,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Current Shift',
                      icon: Icons.access_time_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ShiftCode.a,
                        child: Text(
                          'Shift A (Day / Morning)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: ShiftCode.b,
                        child: Text(
                          'Shift B (Night / Evening)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: ShiftCode.c,
                        child: Text(
                          'Shift C (Night, 3-shift)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _currentShift = v ?? ShiftCode.a),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _offDay,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Weekly Off Day',
                      icon: Icons.weekend_outlined,
                    ),
                    items: AppDate.weekdays
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _offDay = v ?? 'Saturday'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),

      // ── Sticky Save Button ────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                isEditing ? 'Update Guard' : 'Save Guard',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}