import 'package:flutter/material.dart';
import '../models/entry_model.dart';

/// A text field that shows matching "frequent / regular" suggestions as
/// the user types. Tapping a suggestion fires [onSuggestionTap] so the
/// caller can do a true one-click check-in/out without opening the full
/// form.
class QuickSuggestionField extends StatefulWidget {
  final String label;
  final List<FrequentTemplate> templates;
  final ValueChanged<String> onChanged;
  final ValueChanged<FrequentTemplate> onSuggestionTap;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final String? hintText;
  final bool enabled;

  const QuickSuggestionField({
    super.key,
    required this.label,
    required this.templates,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.controller,
    this.prefixIcon = Icons.person_outline_rounded,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<QuickSuggestionField> createState() => _QuickSuggestionFieldState();
}

class _QuickSuggestionFieldState extends State<QuickSuggestionField>
    with SingleTickerProviderStateMixin {
  List<FrequentTemplate> _matches = [];
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (!_focusNode.hasFocus) {
      // Delay clearing so a tap on a suggestion still registers.
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _matches = []);
        }
      });
    }
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    final q = value.trim().toLowerCase();
    setState(() {
      _matches = q.isEmpty
          ? []
          : widget.templates
              .where((t) => t.name.toLowerCase().contains(q))
              .take(6)
              .toList();
    });
  }

  void _selectTemplate(FrequentTemplate t, {bool oneTap = false}) {
    widget.controller.text = t.name;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: t.name.length),
    );
    setState(() => _matches = []);
    _focusNode.unfocus();

    if (oneTap) {
      widget.onSuggestionTap(t);
    } else {
      widget.onChanged(t.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------- Input Field --------
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              prefixIcon: Icon(widget.prefixIcon),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged('');
                        setState(() => _matches = []);
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
                borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
              ),
            ),
          ),
        ),

        // -------- Suggestions Dropdown --------
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _matches.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _matches.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 0.6,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, i) {
                        final t = _matches[i];
                        return _SuggestionTile(
                          template: t,
                          onTap: () => _selectTemplate(t),
                          onOneTap: () => _selectTemplate(t, oneTap: true),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual suggestion tile with hover / tap feedback
// ---------------------------------------------------------------------------
class _SuggestionTile extends StatefulWidget {
  final FrequentTemplate template;
  final VoidCallback onTap;
  final VoidCallback onOneTap;

  const _SuggestionTile({
    required this.template,
    required this.onTap,
    required this.onOneTap,
  });

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = widget.template;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered
            ? colorScheme.primary.withOpacity(0.06)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Leading avatar / icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade400,
                        Colors.orange.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (t.subtitle != null && t.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          t.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // One-tap button
                const SizedBox(width: 8),
                _OneTapButton(onPressed: widget.onOneTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OneTapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _OneTapButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 14,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'One-tap',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}