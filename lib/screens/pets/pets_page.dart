import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../services/pet_service.dart';
import '../../widgets/pawcare_header.dart';
import '../../widgets/pet_card.dart';
import 'add_pet_page.dart';
import 'pet_details_page.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({
    super.key,
  });

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  final PetService _petService = PetService();

  late Future<List<Pet>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  void _loadPets() {
    _petsFuture = _petService.getMyPets();
  }

  Future<void> _addPet() async {
    final pet = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPetPage(),
      ),
    );

    if (pet != null && mounted) {
      setState(_loadPets);
    }
  }

  Future<void> _refresh() async {
    setState(_loadPets);

    await _petsFuture;
  }

  Future<void> _openPet(
    Pet pet,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailsPage(
          pet: pet,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(_loadPets);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return RefreshIndicator(
      color: AppConstants.primaryColor,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          220,
        ),
        children: [
          PawcareHeader(
            title: 'My Pets',
            subtitle: 'Manage your pet profiles in one place.',
            showProfile: false,
            showNotification: false,
          ),
          const SizedBox(height: 22),
          FutureBuilder<List<Pet>>(
            future: _petsFuture,
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 70,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _PetsError(
                  onRetry: () {
                    setState(
                      _loadPets,
                    );
                  },
                );
              }

              final pets = snapshot.data ?? const <Pet>[];

              if (pets.isEmpty) {
                return _EmptyPets(
                  onAddPet: _addPet,
                );
              }

              return Column(
                children: [
                  ...pets.map(
                    (pet) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: PetCard(
                        pet: pet,
                        onTap: () => _openPet(
                          pet,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addPet,
                      icon: const Icon(
                        Icons.add_rounded,
                      ),
                      label: const Text(
                        'Add Another Pet',
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
                          borderRadius: BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================
// EMPTY
// =============================================================

class _EmptyPets extends StatelessWidget {
  final VoidCallback onAddPet;

  const _EmptyPets({
    required this.onAddPet,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        34,
        24,
        30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: AppConstants.lightPrimary,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppConstants.lightPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 48,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'No pets added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkText,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          const Text(
            'Create your first pet profile so Pawcare can keep their information and care needs in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              height: 1.45,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddPet,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Add My Pet',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ERROR
// =============================================================

class _PetsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _PetsError({
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Could not load your pets',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Please check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }
}
