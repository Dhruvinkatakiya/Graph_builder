import 'package:flutter/material.dart';
import 'package:tree_app/models/tree_node.dart';

class EdgePainter extends CustomPainter {
  final Map<int, TreeNode> nodes;
  final Map<int, Offset> positions;
  final Set<int> deletingIds;
  final Color color;

  EdgePainter({
    required this.nodes,
    required this.positions,
    required this.deletingIds,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final path = Path();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = color;

    for (final node in nodes.values) {
      for (final childId in node.childrenIds) {
        if (!positions.containsKey(node.id) || !positions.containsKey(childId))
          continue;
        final p1 = positions[node.id]!;
        final p2 = positions[childId]!;
        final isFading =
            deletingIds.contains(node.id) || deletingIds.contains(childId);

        final midY = (p1.dy + p2.dy) / 2;
        final c1 = Offset(p1.dx, midY);
        final c2 = Offset(p2.dx, midY);

        path.reset();
        path.moveTo(p1.dx, p1.dy);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);

        final alpha = isFading ? 0.0 : 1.0;
        canvas.drawPath(
          path,
          paint
            ..color = paint.color.withOpacity(0.7 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.positions != positions ||
        oldDelegate.deletingIds != deletingIds ||
        oldDelegate.color != color;
  }
}


