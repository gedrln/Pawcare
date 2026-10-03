import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class FloatingAiButton extends StatelessWidget {
  final bool open;
  final VoidCallback onPressed;

  const FloatingAiButton({
    super.key,
    required this.open,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 9,
      color: AppConstants.primaryColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(
            open ? Icons.close_rounded : Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
      ),
    );
  }
}
