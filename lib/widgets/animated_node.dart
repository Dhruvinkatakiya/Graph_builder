import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedNode extends StatelessWidget {
  final int id;
  final String label;
  final bool selected;
  final bool isAppearing;
  final bool isDeleting;
  final double radius;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AnimatedNode({
    required this.id,
    required this.label,
    required this.selected,
    required this.radius,
    required this.isAppearing,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color baseColor = selected
        ? cs.primary
        : cs.primaryContainer.withOpacity(0.85);
    final Color textColor = selected ? cs.onPrimary : cs.onPrimaryContainer;
    final double scale = isAppearing ? 0.4 : (isDeleting ? 0.75 : 1.0);
    final double opacity = isDeleting ? 0.0 : 1.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedScale(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            opacity: opacity,
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? cs.onPrimary.withOpacity(0.4)
                        : cs.primary.withOpacity(0.2),
                    width: selected ? 3 : 2,
                  ),
                ),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: selected ? 20 : 18,
                  ),
                  child: Text(label),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
