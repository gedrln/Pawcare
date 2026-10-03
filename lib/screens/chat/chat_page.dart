import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/floating_chat_window.dart';

class ChatPage extends StatelessWidget {
  final Pet? pet;

  final VoidCallback? onClose;

  const ChatPage({
    super.key,
    this.pet,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (pet == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pets_rounded,
                  size: 50,
                ),
                SizedBox(height: 12),
                Text(
                  'No Pet Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please add a pet before using Pawcare AI.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: FloatingChatWindow(
          pet: pet!,
          onClose: onClose ??
              () {
                Navigator.pop(context);
              },
        ),
      ),
    );
  }
}
