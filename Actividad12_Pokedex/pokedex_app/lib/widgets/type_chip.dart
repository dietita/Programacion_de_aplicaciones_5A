import 'package:flutter/material.dart';
import '../utils/type_colors.dart';

class TypeChip extends StatelessWidget {
  final String type;
  final bool light;
  const TypeChip({super.key, required this.type, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.25) : TypeColors.of(type),
        borderRadius: BorderRadius.circular(20),
        border: light ? Border.all(color: Colors.white54) : null,
      ),
      child: Text(
        TypeColors.nameOf(type).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
