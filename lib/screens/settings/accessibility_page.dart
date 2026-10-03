import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class AccessibilityPage extends StatefulWidget {
  const AccessibilityPage({
    super.key,
  });

  @override
  State<AccessibilityPage> createState() => _AccessibilityPageState();
}

class _AccessibilityPageState extends State<AccessibilityPage> {
  bool largeText = false;
  bool highContrast = false;
  bool reduceMotion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accessibility',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          30,
        ),
        children: [
          const Text(
            'Accessibility Preferences',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Adjust Pawcare to make the app more comfortable and accessible to use.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          _PreferenceTile(
            icon: Icons.text_fields_rounded,
            title: 'Larger Text',
            subtitle: 'Use larger text throughout the app.',
            value: largeText,
            onChanged: (value) {
              setState(() {
                largeText = value;
              });
            },
          ),
          _PreferenceTile(
            icon: Icons.contrast_rounded,
            title: 'High Contrast',
            subtitle: 'Increase contrast between text and surfaces.',
            value: highContrast,
            onChanged: (value) {
              setState(() {
                highContrast = value;
              });
            },
          ),
          _PreferenceTile(
            icon: Icons.motion_photos_off_rounded,
            title: 'Reduce Motion',
            subtitle: 'Reduce non-essential animations.',
            value: reduceMotion,
            onChanged: (value) {
              setState(() {
                reduceMotion = value;
              });
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppConstants.lightPrimary,
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppConstants.darkText,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These accessibility controls are currently part of the app design. They can later be connected to saved user preferences.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppConstants.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppConstants.lightPrimary,
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
          child: Icon(
            icon,
            color: AppConstants.darkText,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
          ),
        ),
        activeColor: AppConstants.primaryColor,
      ),
    );
  }
}
