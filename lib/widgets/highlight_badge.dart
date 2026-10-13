import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Clean, modern VIP pill badge.
/// Minimal design: soft tinted background, crisp colored border,
/// strong colored text, small leading icon. No shadows, no gradient.
class HighlightBadge extends StatelessWidget {
  final String? category;
  final String? label;
  final Color? color;
  final bool compact;

  const HighlightBadge({
    super.key,
    this.category,
    this.label,
    this.color,
    this.compact = false,
  });

  static Color colorFor(String category) {
    switch (category) {
      case BossCategory.chairman:
        return AppColors.chairman;
      case BossCategory.md:
        return AppColors.md;
      case BossCategory.director:
        return AppColors.director;
      case BossCategory.guest:
        return AppColors.guestBoss;
      default:
        return AppColors.primary;
    }
  }

  static IconData _iconFor(String? category, String label) {
    if (category == BossCategory.chairman) return Icons.workspace_premium_rounded;
    if (category == BossCategory.md) return Icons.military_tech_rounded;
    if (category == BossCategory.director) return Icons.verified_rounded;
    if (category == BossCategory.guest) return Icons.diamond_rounded;

    final l = label.toLowerCase();
    if (l.contains('buyer')) return Icons.shopping_bag_rounded;
    if (l.contains('audit')) return Icons.shield_rounded;
    return Icons.star_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final base = color ??
        (category != null ? colorFor(category!) : AppColors.primary);

    final text = label ??
        (category != null ? BossCategory.label(category!) : '');

    if (text.isEmpty) return const SizedBox.shrink();

    // ---- Sizing ----
    final height   = compact ? 20.0 : 24.0;
    final iconSize = compact ? 11.0 : 13.0;
    final fontSize = compact ? 10.0 : 11.0;
    final padH     = compact ? 8.0  : 10.0;
    final gap      = compact ? 3.0  : 5.0;

    // ---- Soft tinted background + crisp border ----
    final bg     = Color.alphaBlend(base.withOpacity(0.10), Colors.white);
    final border = base.withOpacity(0.35);

    final icon = _iconFor(category, text);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padH),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: base),
          SizedBox(width: gap),
          Text(
            text,
            style: TextStyle(
              color: base,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}