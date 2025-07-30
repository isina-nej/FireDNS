import 'package:flutter/material.dart';

class SetDnsButton extends StatelessWidget {
  final VoidCallback onPressed;
  const SetDnsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_ethernet, color: Colors.blue),
      tooltip: 'ست کردن DNS ویندوز',
      onPressed: onPressed,
    );
  }
}
