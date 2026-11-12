import 'package:flutter/material.dart';

class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  final double fontSize;
  final bool isLarge;
  final bool isRare;

  const BloodGroupBadge({
    super.key,
    required this.bloodGroup,
    this.fontSize = 14,
    this.isLarge = false,
    this.isRare = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNegative = bloodGroup.endsWith('-');
    final Color bgColor = isNegative ? const Color(0xFFB71C1C) : const Color(0xFFE53935);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isLarge ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.35),
            blurRadius: isLarge ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.water_drop,
            color: Colors.white,
            size: fontSize * 1.1,
          ),
          const SizedBox(width: 4),
          Text(
            bloodGroup,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
