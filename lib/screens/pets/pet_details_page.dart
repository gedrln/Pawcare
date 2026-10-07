import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../models/pet_schedule.dart';
import '../../services/pet_service.dart';
import '../../services/pet_schedule_service.dart';
import 'edit_pet_page.dart';

class PetDetailsPage extends StatefulWidget {
  final Pet pet;

  const PetDetailsPage({
    super.key,
    required this.pet,
  });

  @override
  State<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  late Pet _pet;
  late Future<List<PetSchedule>> _careSchedulesFuture;
  final PetScheduleService _scheduleService = PetScheduleService();
  final PetService _petService = PetService();
  bool _savingCareNotes = false;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _careSchedulesFuture = _loadCareSchedules();
  }

  Future<List<PetSchedule>> _loadCareSchedules() async {
    final schedules = await _scheduleService.getMySchedules();
    return schedules.where((schedule) => schedule.petId == _pet.id).toList();
  }

  Future<void> _refreshCareSchedules() async {
    setState(() {
      _careSchedulesFuture = _loadCareSchedules();
    });
    try {
      await _careSchedulesFuture;
    } catch (_) {
      // FutureBuilder displays the error and allows the owner to retry.
    }
  }

  Future<void> _editPet() async {
    final updatedPet = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPetPage(
          pet: _pet,
        ),
      ),
    );

    if (updatedPet == null || !mounted) {
      return;
    }

    setState(() {
      _pet = updatedPet;
    });
  }

  Future<void> _editCareNotes() async {
    var funFact = _pet.funFact;
    var healthNote =
        _pet.healthNote.isNotEmpty ? _pet.healthNote : _pet.careNotes;
    final notes = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppConstants.backgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_pet.name}’s notes',
                  style: const TextStyle(
                    color: AppConstants.darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep a fun fact separate from important health information.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: funFact,
                  onChanged: (value) => funFact = value,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: 'Fun fact',
                    hintText: 'For example: loves playing fetch.',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: healthNote,
                  onChanged: (value) => healthNote = value,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    labelText: 'Health note',
                    hintText: 'For example: allergic to chicken.',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        (funFact, healthNote),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                      ),
                      child: const Text('Save notes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (notes == null || !mounted) return;

    setState(() => _savingCareNotes = true);
    try {
      final updatedPet = await _petService.updatePetNotes(
        petId: _pet.id,
        funFact: notes.$1,
        healthNote: notes.$2,
      );
      if (!mounted) return;
      setState(() => _pet = updatedPet);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save pet notes: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingCareNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = _pet;
    final healthNote = pet.healthNote.trim().isEmpty
        ? pet.careNotes.trim()
        : pet.healthNote.trim();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppConstants.darkText,
          ),
        ),
        title: Text(
          pet.name,
          style: const TextStyle(
            color: AppConstants.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _editPet,
            tooltip: 'Edit pet',
            icon: const Icon(
              Icons.edit_rounded,
              color: AppConstants.darkText,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCareSchedules,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              _PetPhoto(
                pet: pet,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  pet.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.darkText,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  [
                    if (pet.breed.trim().isNotEmpty) pet.breed.trim(),
                    pet.ageLabel,
                  ].join(' • '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Pet Information',
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [
                  _InfoBox(
                    label: 'Species',
                    value: _displayValue(
                      pet.species,
                    ),
                    icon: Icons.pets_rounded,
                  ),
                  _InfoBox(
                    label: 'Gender',
                    value: _displayValue(
                      pet.gender,
                    ),
                    icon: Icons.wc_rounded,
                  ),
                  _InfoBox(
                    label: 'Breed',
                    value: _displayValue(
                      pet.breed,
                    ),
                    icon: Icons.badge_outlined,
                  ),
                  _InfoBox(
                    label: 'Birthdate',
                    value: pet.formattedBirthdate,
                    icon: Icons.calendar_today_outlined,
                  ),
                  _InfoBox(
                    label: 'Age',
                    value: pet.ageLabel,
                    icon: Icons.cake_outlined,
                  ),
                  _InfoBox(
                    label: 'Status',
                    value: pet.petStatus,
                    icon: Icons.favorite_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionTitle(title: 'Pet Notes & Health'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppConstants.lightPrimary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PetNoteDisplay(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Fun fact',
                      value: pet.funFact.trim(),
                    ),
                    const SizedBox(height: 14),
                    _PetNoteDisplay(
                      icon: Icons.health_and_safety_outlined,
                      label: 'Health note',
                      value: healthNote,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _savingCareNotes ? null : _editCareNotes,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(
                          pet.funFact.trim().isEmpty && healthNote.isEmpty
                              ? 'Add notes'
                              : 'Edit notes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _SectionTitle(
                title: 'Care Overview',
              ),
              const SizedBox(height: 12),
              _buildCareOverview(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _editPet,
                  icon: const Icon(
                    Icons.edit_rounded,
                  ),
                  label: const Text(
                    'Edit Pet Information',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayValue(String value) {
    if (value.trim().isEmpty) {
      return 'Not specified';
    }

    return value;
  }

  Widget _buildCareOverview() {
    return FutureBuilder<List<PetSchedule>>(
      future: _careSchedulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _CareOverviewMessage(
            message: 'Could not load this pet\'s schedules.',
            actionLabel: 'Retry',
            onPressed: _refreshCareSchedules,
          );
        }

        final schedules = snapshot.data ?? const <PetSchedule>[];
        if (schedules.isEmpty) {
          return _CareOverviewMessage(
            message: 'No care schedules have been added for ${_pet.name} yet.',
          );
        }

        return Column(
          children: [
            for (var i = 0; i < schedules.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _CareCard(
                icon: _iconForScheduleType(schedules[i].type),
                title: schedules[i].title,
                subtitle: _scheduleSummary(schedules[i]),
                onTap: () => _showScheduleDetails(schedules[i]),
              ),
            ],
          ],
        );
      },
    );
  }

  String _scheduleSummary(PetSchedule schedule) {
    final date =
        MaterialLocalizations.of(context).formatMediumDate(schedule.date);
    final time =
        TimeOfDay(hour: schedule.hour, minute: schedule.minute).format(context);
    final repeat =
        schedule.repeat == 'Does not repeat' ? 'One time' : schedule.repeat;
    final details = <String>[
      schedule.type,
      '$date at $time',
      repeat,
      if (schedule.notes.trim().isNotEmpty) schedule.notes.trim(),
    ];
    return details.join(' • ');
  }

  IconData _iconForScheduleType(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Icons.vaccines_outlined;
      case 'vet visit':
      case 'veterinary check-up':
        return Icons.local_hospital_outlined;
      case 'grooming':
        return Icons.content_cut_rounded;
      case 'feeding':
        return Icons.restaurant_outlined;
      case 'medicine':
        return Icons.medication_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  Future<void> _showScheduleDetails(PetSchedule schedule) async {
    final date =
        MaterialLocalizations.of(context).formatMediumDate(schedule.date);
    final time =
        TimeOfDay(hour: schedule.hour, minute: schedule.minute).format(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${schedule.type}'),
            const SizedBox(height: 8),
            Text('Date: $date'),
            Text('Time: $time'),
            Text('Repeat: ${schedule.repeat}'),
            if (schedule.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${schedule.notes.trim()}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}

class _PetPhoto extends StatelessWidget {
  final Pet pet;

  const _PetPhoto({
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pet.photoUrl != null && pet.photoUrl!.trim().isNotEmpty;

    if (hasPhoto) {
      return Center(
        child: ClipOval(
          child: Image.network(
            pet.photoUrl!,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _placeholder();
            },
          ),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return const Center(
      child: CircleAvatar(
        radius: 70,

        // IMPORTANT:
        // Do NOT use pet.color.
        backgroundColor: AppConstants.lightPrimary,

        child: Icon(
          Icons.pets_rounded,
          size: 65,
          color: AppConstants.darkText,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: AppConstants.darkText,
      ),
    );
  }
}

class _PetNoteDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PetNoteDisplay({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppConstants.darkText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppConstants.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'Not added yet.' : value,
                style: const TextStyle(
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppConstants.lightPrimary,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppConstants.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.darkText,
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

class _CareOverviewMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _CareOverviewMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                  icon,
                  color: AppConstants.darkText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
