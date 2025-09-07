import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomBar extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetZoom;
  final int selectedId;

  const BottomBar({
    super.key,
    required this.onAdd,
    required this.onDelete,
    required this.selectedId,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetZoom,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // --- Floating selected node + zoom controls ---
        Positioned(
          left: 16, // add left padding
          right: 16, // add right padding
          bottom: 110,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // push children to ends
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: Selected Node Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface, 
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app, 
                      size: isSmallScreen ? 14 : 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap nodes to select',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 12 : 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT: Same Selected Node Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface, // background like tooltip
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      'Selected Node ID: $selectedId',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 12 : 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 30),

       

        // --- Bottom Bar (Add / Delete) ---
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    icon: Icons.add,
                    label: isSmallScreen ? 'Add' : 'Add Child',
                    color: const Color(0xFF4285F4), // Google Blue
                    onTap: onAdd,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryButton(
                    icon: Icons.delete,
                    label: isSmallScreen ? 'Delete' : 'Delete Node',
                    color: const Color(0xFFEA4335), // Google Red
                    onTap: onDelete,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------- Internal Primary Button -------------------
class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: isSmallScreen ? 44 : 48,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
