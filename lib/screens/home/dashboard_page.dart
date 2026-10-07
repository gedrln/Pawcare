import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../models/pet_schedule.dart';
import '../../models/user_profile.dart';
import '../../services/pet_schedule_service.dart';
import '../../widgets/pawcare_header.dart';
import '../../widgets/platform_backdrop_blur.dart';

class DashboardPage extends StatelessWidget {
  final UserProfile profile;
  final List<Pet> pets;
  final Pet? activePet;

  final VoidCallback onProfileTap;
  final VoidCallback onOpenPets;
  final VoidCallback onOpenSchedule;
  final void Function(Pet pet) onOpenPet;
  final VoidCallback onAddPet;
  final ValueChanged<Pet> onActivePetChanged;
  final int todayRefreshTrigger;

  const DashboardPage({
    super.key,
    required this.profile,
    required this.pets,
    required this.activePet,
    required this.onProfileTap,
    required this.onOpenPets,
    required this.onOpenSchedule,
    required this.onOpenPet,
    required this.onAddPet,
    required this.onActivePetChanged,
    this.todayRefreshTrigger = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 220),
      children: [
        PawcareHeader(
          title: 'Good day, ${_firstName(profile.name)}!',
          subtitle: 'Let’s take good care of your furry friend.',
          profile: profile,
          onProfileTap: onProfileTap,
          showNotification: false,
        ),

        const SizedBox(height: 24),

        // ---------------------------------------------------------------
        // ACTIVE PET
        // ---------------------------------------------------------------
        if (pets.isNotEmpty)
          _ActivePetsCarousel(
            pets: pets,
            activePet: activePet,
            onActivePetChanged: onActivePetChanged,
            onOpenPet: onOpenPet,
            onAddPet: onAddPet,
          )
        else
          _NoPetCard(
            onAddPet: onAddPet,
          ),

        const SizedBox(height: 26),

        // ---------------------------------------------------------------
        // QUICK ACCESS
        // ---------------------------------------------------------------
        const _SectionTitle(
          title: 'Quick Access',
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.pets_rounded,
                title: 'Pet Profiles',
                onTap: onOpenPets,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.favorite_border_rounded,
                title: 'Pet Wellness',
                onTap: onOpenPets,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.calendar_month_rounded,
                title: 'Pet Schedule',
                onTap: onOpenSchedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.note_alt_outlined,
                title: 'Pet Notes',
                onTap: onOpenPets,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ---------------------------------------------------------------
        // TODAY
        // ---------------------------------------------------------------
        const _SectionTitle(
          title: 'Today',
        ),

        const SizedBox(height: 12),

        _TodaySchedules(
          refreshTrigger: todayRefreshTrigger,
          onOpenSchedule: onOpenSchedule,
        ),
      ],
    );
  }

  static String _firstName(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'there';
    }

    final parts = trimmed.split(RegExp(r'\s+'));

    return parts.first;
  }
}

// ===========================================================================
// ACTIVE PET CARD
// ===========================================================================

class _ActivePetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onOpenPet;

  const _ActivePetCard({
    required this.pet,
    required this.onOpenPet,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(24);
    final healthNote = pet.healthNote.trim().isEmpty
        ? pet.careNotes.trim()
        : pet.healthNote.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenPet,
        borderRadius: borderRadius,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: PlatformBackdropBlur(
            sigmaX: 18,
            sigmaY: 18,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor.withOpacity(0.46),
                    const Color(0xFFD97A28).withOpacity(0.34),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: borderRadius,
                border: Border.all(
                  color: Colors.white.withOpacity(0.78),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _DashboardPetPhoto(pet: pet, size: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Your active pet',
                              style: TextStyle(
                                color: AppConstants.darkText.withOpacity(0.78),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppConstants.darkText,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (pet.species.trim().isNotEmpty) pet.species,
                                if (pet.breed.trim().isNotEmpty) pet.breed,
                                pet.gender,
                                pet.ageLabel,
                              ]
                                  .where((value) => value.trim().isNotEmpty)
                                  .join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppConstants.darkText.withOpacity(0.78),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CarouselPetNoteLine(
                          icon: Icons.lightbulb_outline_rounded,
                          label: 'Fun fact',
                          value: pet.funFact.trim().isEmpty
                              ? 'Not added yet'
                              : pet.funFact.trim(),
                        ),
                        const SizedBox(height: 5),
                        _CarouselPetNoteLine(
                          icon: Icons.health_and_safety_outlined,
                          label: 'Health',
                          value: healthNote.isEmpty
                              ? 'No health note'
                              : healthNote,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselPetNoteLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CarouselPetNoteLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppConstants.darkText),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppConstants.darkText,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppConstants.darkText.withOpacity(0.9),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivePetsCarousel extends StatefulWidget {
  final List<Pet> pets;
  final Pet? activePet;
  final ValueChanged<Pet> onActivePetChanged;
  final ValueChanged<Pet> onOpenPet;
  final VoidCallback onAddPet;

  const _ActivePetsCarousel({
    required this.pets,
    required this.activePet,
    required this.onActivePetChanged,
    required this.onOpenPet,
    required this.onAddPet,
  });

  @override
  State<_ActivePetsCarousel> createState() => _ActivePetsCarouselState();
}

class _ActivePetsCarouselState extends State<_ActivePetsCarousel> {
  late final PageController _pageController;
  late int _currentIndex;

  int _indexOfActivePet() {
    final activeId = widget.activePet?.id;
    if (activeId == null) return 0;
    final index = widget.pets.indexWhere((pet) => pet.id == activeId);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexOfActivePet();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.91,
    );
  }

  @override
  void didUpdateWidget(covariant _ActivePetsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedIndex = _indexOfActivePet();
    if (selectedIndex != _currentIndex && _pageController.hasClients) {
      _currentIndex = selectedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !_pageController.hasClients ||
            _indexOfActivePet() != selectedIndex) {
          return;
        }

        _pageController.jumpToPage(selectedIndex);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = widget.pets.length + 1;
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              if (index < widget.pets.length) {
                widget.onActivePetChanged(widget.pets[index]);
              }
            },
            itemBuilder: (context, index) {
              if (index == widget.pets.length) {
                return _AddPetCarouselCard(onTap: widget.onAddPet);
              }
              final pet = widget.pets[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ActivePetCard(
                  pet: pet,
                  onOpenPet: () => widget.onOpenPet(pet),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            final selected = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: selected
                    ? AppConstants.primaryColor
                    : AppConstants.lightPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AddPetCarouselCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetCarouselCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppConstants.lightPrimary),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppConstants.lightPrimary,
                  child: Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: AppConstants.darkText,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Add another pet',
                  style: TextStyle(
                    color: AppConstants.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Create a profile for another furry friend.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// NO PET CARD
// ===========================================================================

class _NoPetCard extends StatelessWidget {
  final VoidCallback onAddPet;

  const _NoPetCard({
    required this.onAddPet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppConstants.lightPrimary,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppConstants.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 40,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No pet profile yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Add your pet to start managing their profile, '
            'care schedule, and important care notes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddPet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add My Pet'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// QUICK ACCESS CARD
// ===========================================================================

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.lightPrimary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppConstants.lightPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppConstants.darkText,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION TITLE
// ===========================================================================

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

// ===========================================================================
// PET PHOTO
// ===========================================================================

class _TodaySchedules extends StatefulWidget {
  final int refreshTrigger;
  final VoidCallback onOpenSchedule;

  const _TodaySchedules({
    required this.refreshTrigger,
    required this.onOpenSchedule,
  });

  @override
  State<_TodaySchedules> createState() => _TodaySchedulesState();
}

class _TodaySchedulesState extends State<_TodaySchedules> {
  final PetScheduleService _scheduleService = PetScheduleService();
  late Future<List<PetSchedule>> _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _schedulesFuture = _scheduleService.getTodaySchedules();
  }

  @override
  void didUpdateWidget(covariant _TodaySchedules oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _schedulesFuture = _scheduleService.getTodaySchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PetSchedule>>(
      future: _schedulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _TodaySchedulesMessage(
            message: 'Could not load today\'s schedules.',
            actionLabel: 'Retry',
            onPressed: _reload,
          );
        }

        final schedules = snapshot.data ?? const <PetSchedule>[];
        if (schedules.isEmpty) {
          return _TodaySchedulesMessage(
            message: 'No pet schedules are set for today.',
            actionLabel: 'Add a schedule',
            onPressed: widget.onOpenSchedule,
          );
        }

        return Column(
          children: [
            for (var index = 0; index < schedules.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              _TodayScheduleCard(
                schedule: schedules[index],
                onTap: widget.onOpenSchedule,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TodayScheduleCard extends StatelessWidget {
  final PetSchedule schedule;
  final VoidCallback onTap;

  const _TodayScheduleCard({
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.lightPrimary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppConstants.lightPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: AppConstants.darkText,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppConstants.darkText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${schedule.petName} • ${schedule.type}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  if (schedule.repeat != 'Does not repeat') ...[
                    const SizedBox(height: 3),
                    Text(
                      schedule.repeat,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (schedule.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      schedule.notes.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              TimeOfDay(hour: schedule.hour, minute: schedule.minute)
                  .format(context),
              style: const TextStyle(
                color: AppConstants.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySchedulesMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _TodaySchedulesMessage({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.lightPrimary),
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

class _DashboardPetPhoto extends StatelessWidget {
  final Pet pet;
  final double size;

  const _DashboardPetPhoto({
    required this.pet,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pet.photoUrl != null && pet.photoUrl!.trim().isNotEmpty;

    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          pet.photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _placeholder();
          },
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppConstants.lightPrimary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.48,
        color: AppConstants.darkText,
      ),
    );
  }
}
