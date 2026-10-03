import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class CareItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final bool completed;

  const CareItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: AppConstants.lightPrimary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppConstants.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: completed ? Colors.green : AppConstants.primaryColor,
          ),
        ),
      ),
    );
  }
}
