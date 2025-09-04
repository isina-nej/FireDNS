// lib/widgets/semi_transparent_text.dart

import 'package:flutter/material.dart';

class SemiTransparentText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color backgroundColor;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const SemiTransparentText({
    Key? key,
    required this.text,
    required this.style,
    this.backgroundColor = Colors.black,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: style,
      ),
    );
  }
}
