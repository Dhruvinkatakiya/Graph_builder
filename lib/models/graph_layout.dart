import 'package:flutter/material.dart';

class GraphLayout {
  final Map<int, Offset> positions;
  final Size size;

  GraphLayout({
    required this.positions, 
    required this.size
  });

  factory GraphLayout.empty() => GraphLayout(
    positions: const {}, 
    size: Size.zero
  );
}
