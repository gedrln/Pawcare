import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../models/pet_schedule.dart';
import '../../services/notification_service.dart';
import '../../services/pet_schedule_service.dart';
import '../../services/pet_service.dart';
import '../../widgets/schedule_event_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // ============================================================
  // SERVICES
  // ============================================================

  final PetScheduleService _scheduleService = PetScheduleService();

  final PetService _petService = PetService();

  final NotificationService _notificationService = NotificationService.instance;

  // ============================================================
  // DATA
  // ============================================================

  List<PetSchedule> schedules = [];
  List<Pet> pets = [];

  bool _loading = true;
  bool _saving = false;

  // ============================================================
  // CALENDAR STATE
  // ============================================================

  DateTime displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // ============================================================
  // SCHEDULE TYPES
  // ============================================================

  final List<String> scheduleTypes = [
    'Feeding',
    'Grooming',
    'Vaccination',
    'Vet Visit',
    'Medicine',
    'Other',
  ];

  // ============================================================
  // COLORS
  // ============================================================

  static const Color yellow = AppConstants.primaryColor;
  static const Color cream = AppConstants.backgroundColor;
  static const Color scheduleBrown = AppConstants.darkText;

  InputDecoration _scheduleFieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: scheduleBrown),
      prefixIcon: Icon(icon, color: scheduleBrown),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.black, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: scheduleBrown, width: 1.7),
      ),
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final loadedPets = await _petService.getMyPets();
      final loadedSchedules = await _scheduleService.getMySchedules();

      if (!mounted) return;

      setState(() {
        pets = loadedPets;
        schedules = loadedSchedules;
        _loading = false;
      });

      // Schedule future native notifications.
      await _notificationService.scheduleAll(
        loadedSchedules,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load schedules: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _sameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================

  void _previousMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + 1,
      );
    });
  }

  void _goToToday() {
    final today = DateTime.now();

    setState(() {
      displayedMonth = DateTime(
        today.year,
        today.month,
      );

      selectedDate = _dateOnly(today);
    });
  }

  // ============================================================
  // GET SCHEDULES FOR DATE
  // ============================================================

  List<PetSchedule> _schedulesForDate(DateTime date) {
    return schedules
        .where(
          (schedule) => _sameDate(schedule.date, date),
        )
        .toList()
      ..sort(
        (a, b) => a.scheduledDateTime.compareTo(
          b.scheduledDateTime,
        ),
      );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  List<DateTime> _calendarDays() {
    final firstDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final lastDay = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    );

    // Convert Monday = 1 ... Sunday = 7
    final leadingDays = firstDay.weekday - 1;

    final totalDays = leadingDays + lastDay.day;

    final rows = (totalDays / 7).ceil();

    final firstCalendarDay = firstDay.subtract(
      Duration(days: leadingDays),
    );

    return List.generate(
      rows * 7,
      (index) => _dateOnly(
        firstCalendarDay.add(
          Duration(days: index),
        ),
      ),
    );
  }

  // ============================================================
  // ADD SCHEDULE
  // ============================================================

  Future<void> _showScheduleDialog({
    DateTime? initialDate,
    PetSchedule? schedule,
  }) async {
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add a pet profile before creating a schedule.',
          ),
        ),
      );

      return;
    }

    const repeatOptions = [
      'Does not repeat',
      'Everyday',
      'Every week',
      'Every month',
    ];
    Pet selectedPet = schedule == null
        ? pets.first
        : pets.firstWhere(
            (pet) => pet.id == schedule.petId,
            orElse: () => pets.first,
          );
    String selectedType = scheduleTypes.contains(schedule?.type)
        ? schedule!.type
        : scheduleTypes.first;
    String selectedRepeat = repeatOptions.contains(schedule?.repeat)
        ? schedule!.repeat
        : repeatOptions.first;

    DateTime selectedScheduleDate = _dateOnly(
      schedule?.date ?? initialDate ?? selectedDate,
    );

    TimeOfDay selectedTime = schedule == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: schedule.hour, minute: schedule.minute);

    String scheduleTitle = schedule?.title ?? '';
    String scheduleNotes = schedule?.notes ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              title: Text(
                schedule == null ? 'Add Pet Schedule' : 'Edit Pet Schedule',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheduleBrown,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ------------------------------------------------
                    // PET
                    // ------------------------------------------------

                    DropdownButtonFormField<Pet>(
                      initialValue: selectedPet,
                      isExpanded: true,
                      decoration: _scheduleFieldDecoration('Pet', Icons.pets),
                      items: pets.map(
                        (pet) {
                          return DropdownMenuItem<Pet>(
                            value: pet,
                            child: Text(
                              pet.name,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (pet) {
                        if (pet == null) return;

                        setDialogState(() {
                          selectedPet = pet;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // TYPE
                    // ------------------------------------------------

                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      isExpanded: true,
                      decoration: _scheduleFieldDecoration(
                          'Type', Icons.grid_view_rounded),
                      items: scheduleTypes.map(
                        (type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                            ),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: scheduleTitle,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) => scheduleTitle = value,
                      decoration: _scheduleFieldDecoration(
                        'Schedule Title',
                        Icons.edit_note,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // DATE
                    // ------------------------------------------------

                    InkWell(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedScheduleDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(
                              days: 365,
                            ),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(
                              days: 3650,
                            ),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppConstants.primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedScheduleDate = _dateOnly(picked);
                        });
                      },
                      child: InputDecorator(
                        decoration: _scheduleFieldDecoration(
                          'Date',
                          Icons.calendar_month,
                        ),
                        child: Text(
                          _formatDate(
                            selectedScheduleDate,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // TIME
                    // ------------------------------------------------

                    InkWell(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );

                        if (picked == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedTime = picked;
                        });
                      },
                      child: InputDecorator(
                        decoration: _scheduleFieldDecoration(
                          'Time',
                          Icons.access_time,
                        ),
                        child: Text(
                          selectedTime.format(
                            context,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: selectedRepeat,
                      isExpanded: true,
                      decoration:
                          _scheduleFieldDecoration('Repeat', Icons.repeat),
                      items: repeatOptions.map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRepeat = value);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // NOTES
                    // ------------------------------------------------

                    TextFormField(
                      initialValue: scheduleNotes,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      onChanged: (value) => scheduleNotes = value,
                      decoration: _scheduleFieldDecoration(
                        'Notes (optional)',
                        Icons.notes,
                      ).copyWith(
                        hintText: 'Add additional details...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(
                            bottom: 48,
                          ),
                          child: Icon(
                            Icons.notes_outlined,
                            color: scheduleBrown,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: scheduleBrown),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheduleBrown,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving
                      ? null
                      : () async {
                          final title = scheduleTitle.trim();

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a schedule title.',
                                ),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            _saving = true;
                          });

                          try {
                            if (schedule == null) {
                              await _createSchedule(
                                pet: selectedPet,
                                title: title,
                                type: selectedType,
                                date: selectedScheduleDate,
                                time: selectedTime,
                                notes: scheduleNotes.trim(),
                                repeat: selectedRepeat,
                              );
                            } else {
                              await _updateSchedule(
                                schedule: schedule,
                                pet: selectedPet,
                                title: title,
                                type: selectedType,
                                date: selectedScheduleDate,
                                time: selectedTime,
                                notes: scheduleNotes.trim(),
                                repeat: selectedRepeat,
                              );
                            }

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } catch (e) {
                            setDialogState(() {
                              _saving = false;
                            });

                            if (!dialogContext.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Unable to save schedule: $e',
                                ),
                              ),
                            );
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          schedule == null ? 'Save' : 'Update',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted && _saving) {
      setState(() {
        _saving = false;
      });
    }

    if (result == true && mounted) {
      // The schedule was already inserted.
      // Refresh everything so calendar dots and the
      // selected-day list are guaranteed to match Supabase.
      await _loadData();
    }
  }

  // ============================================================
  // CREATE SCHEDULE
  // ============================================================

  Future<void> _createSchedule({
    required Pet pet,
    required String title,
    required String type,
    required DateTime date,
    required TimeOfDay time,
    required String notes,
    required String repeat,
  }) async {
    final schedule = await _scheduleService.createSchedule(
      pet: pet,
      title: title,
      type: type,
      date: date,
      hour: time.hour,
      minute: time.minute,
      notes: notes,
      repeat: repeat,
    );

    // Schedule native notification if the event is
    // in the future.
    await _notificationService.scheduleReminder(
      schedule,
    );
  }

  Future<void> _updateSchedule({
    required PetSchedule schedule,
    required Pet pet,
    required String title,
    required String type,
    required DateTime date,
    required TimeOfDay time,
    required String notes,
    required String repeat,
  }) async {
    final updatedSchedule = await _scheduleService.updateSchedule(
      scheduleId: schedule.id,
      pet: pet,
      title: title,
      type: type,
      date: date,
      hour: time.hour,
      minute: time.minute,
      notes: notes,
      repeat: repeat,
    );

    await _notificationService.cancel(schedule);
    await _notificationService.scheduleReminder(updatedSchedule);
  }

  Future<void> _setScheduleDone(
    PetSchedule schedule,
    bool isDone,
  ) async {
    try {
      await _scheduleService.updateScheduleStatus(
        scheduleId: schedule.id,
        isDone: isDone,
      );

      if (!mounted) return;
      setState(() {
        final index = schedules.indexWhere((item) => item.id == schedule.id);
        if (index >= 0) {
          schedules[index] = schedules[index].copyWith(isDone: isDone);
        }
      });

      try {
        if (isDone) {
          await _notificationService.cancel(schedule);
        } else {
          await _notificationService.scheduleReminder(schedule);
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status saved, but reminder could not be updated: $error',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update schedule status: $error')),
      );
    }
  }

  // ============================================================
  // DELETE SCHEDULE
  // ============================================================

  Future<void> _deleteSchedule(
    PetSchedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Schedule?',
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${schedule.title}" for '
            '${schedule.petName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _scheduleService.deleteSchedule(
        schedule.id,
      );

      // IMPORTANT:
      // This is the corrected method call.
      await _notificationService.cancel(
        schedule,
      );

      if (!mounted) return;

      setState(() {
        schedules.removeWhere(
          (item) => item.id == schedule.id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Schedule deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete schedule: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, '
        '${date.year}';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selectedSchedules = _schedulesForDate(selectedDate);

    return Scaffold(
      backgroundColor: cream,

      // ========================================================
      // BODY
      // ========================================================

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: yellow,
              ),
            )
          : RefreshIndicator(
              color: yellow,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  220,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'Pet Schedule',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.darkText,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Keep track for your furry friend',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // CALENDAR HEADER
                    // ==================================================

                    Row(
                      children: [
                        const Text(
                          'Calendar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkText,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _goToToday,
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: AppConstants.darkText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // CALENDAR
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppConstants.lightPrimary),
                      ),
                      child: Column(
                        children: [
                          // ----------------------------------------------
                          // MONTH NAVIGATION
                          // ----------------------------------------------

                          Row(
                            children: [
                              IconButton(
                                onPressed: _previousMonth,
                                icon: const Icon(
                                  Icons.chevron_left,
                                  color: AppConstants.darkText,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _formatMonth(
                                      displayedMonth,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.darkText,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _nextMonth,
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: AppConstants.darkText,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          // ----------------------------------------------
                          // WEEK DAYS
                          // ----------------------------------------------

                          Row(
                            children: const [
                              _WeekDay(
                                label: 'M',
                              ),
                              _WeekDay(
                                label: 'T',
                              ),
                              _WeekDay(
                                label: 'W',
                              ),
                              _WeekDay(
                                label: 'T',
                              ),
                              _WeekDay(
                                label: 'F',
                              ),
                              _WeekDay(
                                label: 'S',
                              ),
                              _WeekDay(
                                label: 'S',
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          // ----------------------------------------------
                          // DAYS
                          // ----------------------------------------------

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _calendarDays().length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 4,
                            ),
                            itemBuilder: (
                              context,
                              index,
                            ) {
                              final day = _calendarDays()[index];

                              final isCurrentMonth = _sameMonth(
                                day,
                                displayedMonth,
                              );

                              final isSelected = _sameDate(
                                day,
                                selectedDate,
                              );

                              final isToday = _sameDate(
                                day,
                                DateTime.now(),
                              );

                              final hasSchedule = _schedulesForDate(
                                day,
                              ).isNotEmpty;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedDate = day;
                                  });
                                },
                                onLongPress: () {
                                  setState(() {
                                    selectedDate = day;
                                    displayedMonth = DateTime(
                                      day.year,
                                      day.month,
                                    );
                                  });

                                  _showScheduleDialog(
                                    initialDate: day,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppConstants.lightPrimary
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: isToday && !isSelected
                                        ? Border.all(
                                            color: AppConstants.primaryColor,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          color: !isCurrentMonth
                                              ? Colors.grey.shade400
                                              : isSelected
                                                  ? AppConstants.darkText
                                                  : Colors.black87,
                                          fontWeight: isToday || isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (hasSchedule)
                                        Positioned(
                                          bottom: 2,
                                          child: Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppConstants.darkText
                                                  : AppConstants.primaryColor
                                                      .withOpacity(0.76),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // SELECTED DATE HEADER
                    // ==================================================

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Schedules',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.darkText,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                _formatDate(
                                  selectedDate,
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ----------------------------------------------
                        // ADD BUTTON
                        // ----------------------------------------------

                        FilledButton.icon(
                          onPressed: () => _showScheduleDialog(
                            initialDate: selectedDate,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                          label: const Text(
                            'Add',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // SCHEDULE LIST
                    // ==================================================

                    if (selectedSchedules.isEmpty)
                      _EmptyScheduleCard(
                        selectedDate: selectedDate,
                        onAdd: () => _showScheduleDialog(
                          initialDate: selectedDate,
                        ),
                      )
                    else
                      Column(
                        children: selectedSchedules.map(
                          (
                            schedule,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: ScheduleEventCard(
                                schedule: schedule,
                                onEdit: () => _showScheduleDialog(
                                  schedule: schedule,
                                ),
                                onStatusChanged: (isDone) =>
                                    _setScheduleDone(schedule, isDone),
                                onDelete: () => _deleteSchedule(
                                  schedule,
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),

                  ],
                ),
              ),
            ),

    );
  }
}

// ================================================================
// WEEK DAY WIDGET
// ================================================================

class _WeekDay extends StatelessWidget {
  final String label;

  const _WeekDay({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EMPTY SCHEDULE CARD
// ================================================================

class _EmptyScheduleCard extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onAdd;

  const _EmptyScheduleCard({
    required this.selectedDate,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.lightPrimary),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppConstants.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppConstants.darkText,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No schedules for this day',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a pet care activity for '
            '${selectedDate.month}/'
            '${selectedDate.day}/'
            '${selectedDate.year}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.darkText,
              side: const BorderSide(
                color: AppConstants.lightPrimary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'Add Schedule',
            ),
          ),
        ],
      ),
    );
  }
}
