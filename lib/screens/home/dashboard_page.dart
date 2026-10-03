import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../models/user_profile.dart';
import '../../widgets/pawcare_header.dart';

class DashboardPage extends StatelessWidget {
  final UserProfile profile;
  final Pet? activePet;

  final VoidCallback onProfileTap;
  final VoidCallback onOpenPets;
  final VoidCallback onOpenSchedule;
  final void Function(Pet pet) onOpenChat;

  const DashboardPage({
    super.key,
    required this.profile,
    required this.activePet,
    required this.onProfileTap,
    required this.onOpenPets,
    required this.onOpenSchedule,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        PawcareHeader(
          title: 'Good day, ${_firstName(profile.name)}!',
          subtitle: 'Let’s take good care of your furry friend.',
          profile: profile,
          onProfileTap: onProfileTap,
        ),

        const SizedBox(height: 24),

        // ---------------------------------------------------------------
        // ACTIVE PET
        // ---------------------------------------------------------------
        if (activePet != null)
          _ActivePetCard(
            pet: activePet!,
            onTap: () => onOpenChat(activePet!),
          )
        else
          _NoPetCard(
            onAddPet: onOpenPets,
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
                onTap: activePet == null
                    ? onOpenPets
                    : () => onOpenChat(activePet!),
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
                title: 'Care Schedule',
                onTap: onOpenSchedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Ask Pawcare',
                onTap: activePet == null
                    ? onOpenPets
                    : () => onOpenChat(activePet!),
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

        if (activePet != null)
          _TodayPetCard(
            pet: activePet!,
            onAskPawcare: () => onOpenChat(activePet!),
          )
        else
          _TodayEmptyCard(
            onAddPet: onOpenPets,
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
  final VoidCallback onTap;

  const _ActivePetCard({
    required this.pet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppConstants.primaryColor,
            Color(0xFFD97A28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _DashboardPetPhoto(
            pet: pet,
            size: 78,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your active pet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pet.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.breed} • ${pet.ageLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ask Pawcare AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
            'care schedule, and Pawcare AI conversations.',
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
// TODAY PET CARD
// ===========================================================================

class _TodayPetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onAskPawcare;

  const _TodayPetCard({
    required this.pet,
    required this.onAskPawcare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppConstants.lightPrimary,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _DashboardPetPhoto(
                pet: pet,
                size: 58,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name}\'s profile',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pet.species} • ${pet.gender}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.favorite_rounded,
                color: AppConstants.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${pet.name} is ${pet.ageLabel}. '
                    'Keep their care information updated for better Pawcare assistance.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAskPawcare,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask Pawcare AI'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.darkText,
                side: const BorderSide(
                  color: AppConstants.primaryColor,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
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
// TODAY EMPTY CARD
// ===========================================================================

class _TodayEmptyCard extends StatelessWidget {
  final VoidCallback onAddPet;

  const _TodayEmptyCard({
    required this.onAddPet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppConstants.lightPrimary,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppConstants.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start with your first pet',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppConstants.darkText,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Create a profile to personalize Pawcare.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onAddPet,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// PET PHOTO
// ===========================================================================

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
