// lib/utils/responsive_size.dart

import 'package:flutter/material.dart';

double responsiveSize(
  double base,
  BuildContext context, {
  double min = 12,
  double max = 40,
  bool scaleByHeight = false,
}) {
  // On Android, just return base (no scaling), but keep API for consistency
  return base;
}
