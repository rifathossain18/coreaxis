import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A big, thumb-friendly IN / OUT button with gradient, shadow & animation.
class InOutButton extends StatefulWidget {
  final bool isIn; // true => shows "IN" (green), false => shows "OUT" (red)
  final VoidCallback onPressed;
  final bool compact;

  const InOutButton({
    super.key,
    required this.isIn,
    required this.onPressed,
    this.compact = false,
  });

  @override
  State<InOutButton> createState() => _InOutButtonState();
}

class _InOutButtonState extends State<InOutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isIn ? AppColors.success : AppColors.danger;
    final darkColor = Color.lerp(baseColor, Colors.black, 0.25)!;
    final lightColor = Color.lerp(baseColor, Colors.white, 0.15)!;

    final double vPad = widget.compact ? 10 : 16;
    final double hPad = widget.compact ? 18 : 28;
    final double iconSize = widget.compact ? 18 : 22;
    final double fontSize = widget.compact ? 13 : 16;
    final double radius = widget.compact ? 12 : 16;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lightColor, baseColor, darkColor],
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.45),
                blurRadius: widget.compact ? 10 : 18,
                offset: Offset(0, widget.compact ? 4 : 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: baseColor.withOpacity(0.25),
                blurRadius: widget.compact ? 4 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with circular background
              Container(
                padding: EdgeInsets.all(widget.compact ? 4 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isIn
                      ? Icons.login_rounded
                      : Icons.logout_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: widget.compact ? 8 : 12),
              Text(
                widget.isIn ? 'IN' : 'OUT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a highlighted IN time / OUT time chip pair with modern styling.
class InOutTimeRow extends StatelessWidget {
  final String inTimeText;
  final String? outTimeText;

  const InOutTimeRow({
    super.key,
    required this.inTimeText,
    this.outTimeText,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _TimeChip(
          label: 'IN',
          value: inTimeText,
          color: AppColors.success,
          icon: Icons.login_rounded,
        ),
        if (outTimeText != null)
          _TimeChip(
            label: 'OUT',
            value: outTimeText!,
            color: AppColors.danger,
            icon: Icons.logout_rounded,
          )
        else
          _TimeChip(
            label: 'STATUS',
            value: 'Inside',
            color: AppColors.success,
            icon: Icons.access_time_filled_rounded,
          ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TimeChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label  ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}