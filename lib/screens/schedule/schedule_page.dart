import 'package:flutter/material.dart';

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

  static const Color yellow = Color.fromARGB(255, 217, 156, 2);
  static const Color darkyelloow = Color.fromARGB(255, 130, 94, 3);
  static const Color cream = Color(0xFFFFFBF5);
  static const Color lightCream = Color(0xFFFFF8ED);

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
  // ENABLE NOTIFICATIONS
  // ============================================================

  Future<void> _enableNotifications() async {
    try {
      final granted = await _notificationService.requestPermission();

      if (!mounted) return;

      if (granted) {
        await _notificationService.scheduleAll(
          schedules,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Schedule notifications have been enabled.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission was not granted.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to enable notifications: $e',
          ),
        ),
      );
    }
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

  Future<void> _showAddScheduleDialog({
    DateTime? initialDate,
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

    Pet selectedPet = pets.first;

    String selectedType = scheduleTypes.first;

    DateTime selectedScheduleDate = _dateOnly(
      initialDate ?? selectedDate,
    );

    TimeOfDay selectedTime = TimeOfDay.now();

    final titleController = TextEditingController();

    final notesController = TextEditingController();

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
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Pet Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 197, 165, 6),
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
                      value: selectedPet,
                      decoration: InputDecoration(
                        labelText: 'Pet',
                        prefixIcon: const Icon(
                          Icons.pets_outlined,
                          color: const Color.fromARGB(255, 197, 165, 6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
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
                    // TITLE
                    // ------------------------------------------------

                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Schedule title',
                        hintText: 'e.g. Give medicine',
                        prefixIcon: const Icon(
                          Icons.event_note_outlined,
                          color: const Color.fromARGB(255, 197, 165, 6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // TYPE
                    // ------------------------------------------------

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: const Color.fromARGB(255, 197, 165, 6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
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
                                  primary:
                                      const Color.fromARGB(255, 197, 165, 6),
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
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color.fromARGB(255, 122, 102, 4),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
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
                        decoration: InputDecoration(
                          labelText: 'Time',
                          prefixIcon: const Icon(
                            Icons.access_time_outlined,
                            color: Color.fromARGB(255, 142, 118, 3),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        child: Text(
                          selectedTime.format(
                            context,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------
                    // NOTES
                    // ------------------------------------------------

                    TextField(
                      controller: notesController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'Add additional details...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(
                            bottom: 48,
                          ),
                          child: Icon(
                            Icons.notes_outlined,
                            color: Color.fromARGB(255, 207, 142, 2),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            12,
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
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 197, 165, 6),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving
                      ? null
                      : () async {
                          final title = titleController.text.trim();

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
                            await _createSchedule(
                              pet: selectedPet,
                              title: title,
                              type: selectedType,
                              date: selectedScheduleDate,
                              time: selectedTime,
                              notes: notesController.text.trim(),
                            );

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
                      : const Text(
                          'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    notesController.dispose();

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
  }) async {
    final schedule = await _scheduleService.createSchedule(
      pet: pet,
      title: title,
      type: type,
      date: date,
      hour: time.hour,
      minute: time.minute,
      notes: notes,
    );

    // Schedule native notification if the event is
    // in the future.
    await _notificationService.scheduleReminder(
      schedule,
    );
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
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Care Schedule',
          style: TextStyle(
            color: Color.fromARGB(255, 106, 79, 11),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // ----------------------------------------------------
          // ENABLE NOTIFICATIONS
          // ----------------------------------------------------

          IconButton(
            tooltip: 'Enable notifications',
            onPressed: _enableNotifications,
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color.fromARGB(255, 128, 100, 0),
            ),
          ),

          // ----------------------------------------------------
          // REFRESH
          // ----------------------------------------------------

          IconButton(
            tooltip: 'Refresh schedules',
            onPressed: _refresh,
            icon: const Icon(
              Icons.refresh,
              color: Color.fromARGB(255, 182, 140, 4),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

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
                  8,
                  16,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER DESCRIPTION
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.04,
                            ),
                            blurRadius: 12,
                            offset: const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 128, 107, 0)
                                  .withOpacity(
                                0.10,
                              ),
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: Color.fromARGB(255, 169, 147, 3),
                              size: 26,
                            ),
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keep track of your pet care',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkyelloow,
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Create reminders for feeding, grooming, medicine, vet visits, and more.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

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
                            color: Color.fromARGB(255, 210, 173, 7),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _goToToday,
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              color: Color.fromARGB(255, 218, 172, 6),
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
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.04,
                            ),
                            blurRadius: 12,
                            offset: const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
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
                                  color: Color.fromARGB(255, 128, 100, 0),
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
                                      color: Color.fromARGB(255, 206, 149, 4),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _nextMonth,
                                icon: const Icon(
                                  Icons.chevron_right,
                                  color: Color.fromARGB(255, 204, 161, 3),
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

                                  _showAddScheduleDialog(
                                    initialDate: day,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? yellow
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: isToday && !isSelected
                                        ? Border.all(
                                            color: yellow,
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
                                                  ? Colors.white
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
                                                  ? Colors.white
                                                  : const Color.fromARGB(
                                                      194, 217, 156, 2),
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
                                  color: Color.fromARGB(255, 213, 171, 1),
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
                          onPressed: () => _showAddScheduleDialog(
                            initialDate: selectedDate,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 202, 166, 3),
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
                        onAdd: () => _showAddScheduleDialog(
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
                                onDelete: () => _deleteSchedule(
                                  schedule,
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),

                    // ==================================================
                    // NOTIFICATION INFO
                    // ==================================================

                    const SizedBox(
                      height: 12,
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        14,
                      ),
                      decoration: BoxDecoration(
                        color: lightCream,
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                        border: Border.all(
                          color: yellow.withOpacity(
                            0.10,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Color.fromARGB(255, 197, 172, 6),
                            size: 22,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'Tap the notification bell above to allow Pawcare to remind you about upcoming pet schedules.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

      // ========================================================
      // FLOATING ADD BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 197, 165, 6),
        foregroundColor: Colors.white,
        onPressed: () => _showAddScheduleDialog(
          initialDate: selectedDate,
        ),
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 128, 100, 3).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: Color.fromARGB(255, 213, 165, 6),
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
              color: Color.fromARGB(255, 213, 165, 6),
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
              foregroundColor: Color.fromARGB(255, 213, 165, 6),
              side: const BorderSide(
                color: Color.fromARGB(255, 213, 165, 6),
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
