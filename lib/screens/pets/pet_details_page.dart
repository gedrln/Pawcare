import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
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

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
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

  @override
  Widget build(BuildContext context) {
    final pet = _pet;

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
                '${pet.breed} • ${pet.ageLabel}',
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
                  label: 'Age',
                  value: pet.ageLabel,
                  icon: Icons.cake_outlined,
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _SectionTitle(
              title: 'Care Overview',
            ),
            const SizedBox(height: 12),
            _CareCard(
              icon: Icons.vaccines_outlined,
              title: 'Vaccination',
              subtitle: 'Keep vaccination records and reminders here.',
              onTap: () {
                _showComingSoon(
                  'Vaccination schedule',
                );
              },
            ),
            const SizedBox(height: 10),
            _CareCard(
              icon: Icons.local_hospital_outlined,
              title: 'Veterinary Check-up',
              subtitle: 'Keep track of your pet\'s veterinary visits.',
              onTap: () {
                _showComingSoon(
                  'Veterinary check-up schedule',
                );
              },
            ),
            const SizedBox(height: 10),
            _CareCard(
              icon: Icons.content_cut_rounded,
              title: 'Grooming',
              subtitle: 'Keep track of grooming appointments.',
              onTap: () {
                _showComingSoon(
                  'Grooming schedule',
                );
              },
            ),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showComingSoon(
                    'Pawcare AI',
                  );
                },
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
                label: Text(
                  'Ask Pawcare AI about ${pet.name}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.darkText,
                  side: const BorderSide(
                    color: AppConstants.primaryColor,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
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
    );
  }

  String _displayValue(String value) {
    if (value.trim().isEmpty) {
      return 'Not specified';
    }

    return value;
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is ready to be connected to the care schedule.',
        ),
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
