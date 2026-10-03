import 'package:flutter/material.dart';
import '../models/pet_schedule.dart';

class ScheduleEventCard extends StatelessWidget {
  final PetSchedule schedule;
  final VoidCallback? onDelete;

  const ScheduleEventCard({
    super.key,
    required this.schedule,
    this.onDelete,
  });

  IconData _getIcon() {
    switch (schedule.type) {
      case 'Feeding':
        return Icons.restaurant_rounded;
      case 'Grooming':
        return Icons.content_cut_rounded;
      case 'Vaccination':
        return Icons.vaccines_rounded;
      case 'Vet Visit':
        return Icons.medical_services_rounded;
      case 'Medicine':
        return Icons.medication_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  Color _getColor() {
    switch (schedule.type) {
      case 'Feeding':
        return const Color(0xFFE59B32);
      case 'Grooming':
        return const Color(0xFFB77BE4);
      case 'Vaccination':
        return const Color(0xFF62A8D8);
      case 'Vet Visit':
        return const Color(0xFF65B98A);
      case 'Medicine':
        return const Color(0xFFE27A72);
      default:
        return const Color(0xFFD88B2A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getIcon(),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B3F14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule.petName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      schedule.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (schedule.notes.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    schedule.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.black38,
              ),
            ),
        ],
      ),
    );
  }
}
