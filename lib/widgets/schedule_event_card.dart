import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/pet_schedule.dart';

class ScheduleEventCard extends StatelessWidget {
  final PetSchedule schedule;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onStatusChanged;
  final VoidCallback? onDelete;

  const ScheduleEventCard({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onStatusChanged,
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
    return AppConstants.darkText;
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
        border: Border.all(color: AppConstants.lightPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppConstants.lightPrimary,
              shape: BoxShape.circle,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: schedule.isDone
                        ? AppConstants.darkText.withOpacity(0.55)
                        : AppConstants.darkText,
                    decoration:
                        schedule.isDone ? TextDecoration.lineThrough : null,
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
                const SizedBox(height: 5),
                InkWell(
                  onTap: onStatusChanged == null
                      ? null
                      : () => onStatusChanged!(!schedule.isDone),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          schedule.isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: schedule.isDone
                              ? Colors.green.shade700
                              : AppConstants.darkText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          schedule.isDone ? 'Done' : 'Mark as done',
                          style: TextStyle(
                            fontSize: 12,
                            color: schedule.isDone
                                ? Colors.green.shade700
                                : AppConstants.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          if (onEdit != null || onDelete != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit schedule',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppConstants.darkText,
                      size: 20,
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete schedule',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.black38,
                      size: 20,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
