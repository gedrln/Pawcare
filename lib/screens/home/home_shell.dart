import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../models/user_profile.dart';
import '../../services/pet_service.dart';
import '../pets/pets_page.dart';
import '../pets/add_pet_page.dart';
import '../pets/pet_details_page.dart';
import '../schedule/schedule_page.dart';
import '../settings/profile_page.dart';
import '../settings/settings_page.dart';
import '../../widgets/platform_backdrop_blur.dart';
import 'dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedIndex = 0;
  int _todaySchedulesRefreshTrigger = 0;

  Pet? activePet;
  List<Pet> pets = [];

  UserProfile profile = initialUserProfile;

  final PetService _petService = PetService();

  @override
  void initState() {
    super.initState();

    _loadCurrentUser();
    _loadActivePet();
  }

  // =========================================================
  // CURRENT USER
  // =========================================================

  void _loadCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      profile = UserProfile.fromUser(user);
    });
  }

  // =========================================================
  // ACTIVE PET
  // =========================================================

  Future<void> _loadActivePet() async {
    try {
      final loadedPets = await _petService.getMyPets();

      if (!mounted) {
        return;
      }

      final currentId = activePet?.id;
      final selectedPet = loadedPets.cast<Pet?>().firstWhere(
            (pet) => pet?.id == currentId,
            orElse: () => loadedPets.isEmpty ? null : loadedPets.first,
          );

      setState(() {
        pets = loadedPets;
        activePet = selectedPet;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        pets = [];
        activePet = null;
      });
    }
  }

  void _selectActivePet(Pet pet) {
    setState(() => activePet = pet);
  }

  Future<void> _openPetDetails(Pet pet) async {
    await Navigator.push<Pet>(
      context,
      MaterialPageRoute(builder: (_) => PetDetailsPage(pet: pet)),
    );
    await _loadActivePet();
  }

  Future<void> _addPet() async {
    final pet = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetPage()),
    );
    await _loadActivePet();
    if (pet != null && mounted) {
      setState(() => activePet = pet);
    }
  }

  // =========================================================
  // PROFILE
  // =========================================================

  Future<void> _openProfile() async {
    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          profile: profile,
        ),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() {
        profile = updatedProfile;
      });
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _onNavigationChanged(
    int index,
  ) async {
    setState(() {
      selectedIndex = index;
      if (index == 0) {
        _todaySchedulesRefreshTrigger++;
      }
    });

    if (index == 0 || index == 1) {
      await _loadActivePet();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final pages = [
      DashboardPage(
        key: const ValueKey('dashboard'),
        profile: profile,
        pets: pets,
        activePet: activePet,
        onActivePetChanged: _selectActivePet,
        onOpenPet: _openPetDetails,
        onAddPet: _addPet,
        todayRefreshTrigger: _todaySchedulesRefreshTrigger,
        onProfileTap: _openProfile,

        // My Pets tab
        onOpenPets: () {
          _onNavigationChanged(1);
        },

        // Schedule tab
        onOpenSchedule: () {
          _onNavigationChanged(2);
        },
      ),
      const PetsPage(),
      const SchedulePage(),
      SettingsPage(
        profile: profile,
        onProfileTap: _openProfile,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: _FloatingGlassNavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: _onNavigationChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// GLASS NAVIGATION BAR
// =============================================================

class _FloatingGlassNavigationBar extends StatelessWidget {
  final int selectedIndex;

  final ValueChanged<int> onDestinationSelected;

  const _FloatingGlassNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        30,
      ),
      child: PlatformBackdropBlur(
        sigmaX: 18,
        sigmaY: 18,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.72,
            ),
            borderRadius: BorderRadius.circular(
              30,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                0.85,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  0.10,
                ),
                blurRadius: 24,
                offset: const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: _GlassNavItem(
                    index: 0,
                    selectedIndex: selectedIndex,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Home',
                    onTap: onDestinationSelected,
                  ),
                ),
                Flexible(
                  child: _GlassNavItem(
                    index: 1,
                    selectedIndex: selectedIndex,
                    icon: Icons.pets_outlined,
                    selectedIcon: Icons.pets_rounded,
                    label: 'My Pets',
                    onTap: onDestinationSelected,
                  ),
                ),
                Flexible(
                  child: _GlassNavItem(
                    index: 2,
                    selectedIndex: selectedIndex,
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month_rounded,
                    label: 'Schedule',
                    onTap: onDestinationSelected,
                  ),
                ),
                Flexible(
                  child: _GlassNavItem(
                    index: 3,
                    selectedIndex: selectedIndex,
                    icon: Icons.account_circle_outlined,
                    selectedIcon: Icons.account_circle_rounded,
                    label: 'Profile',
                    onTap: onDestinationSelected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// NAV ITEM
// =============================================================

class _GlassNavItem extends StatelessWidget {
  final int index;

  final int selectedIndex;

  final IconData icon;

  final IconData selectedIcon;

  final String label;

  final ValueChanged<int> onTap;

  const _GlassNavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final selected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 220,
          ),
          curve: Curves.easeOut,
          padding: selected
              ? const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 8,
                )
              : const EdgeInsets.all(
                  9,
                ),
          constraints: const BoxConstraints(
            minWidth: 48,
            maxWidth: 105,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.lightPrimary.withOpacity(
                    0.92,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              22,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected
                    ? AppConstants.primaryColor
                    : AppConstants.darkText.withOpacity(
                        0.62,
                      ),
              ),
              if (selected) ...[
                const SizedBox(
                  width: 5,
                ),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppConstants.darkText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
