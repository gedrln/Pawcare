import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/pet.dart';

class PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = pet.photoUrl != null && pet.photoUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppConstants.lightPrimary,
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: hasPhoto
                    ? Image.network(
                        pet.photoUrl!,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return _PetPlaceholder();
                        },
                      )
                    : _PetPlaceholder(),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(text: pet.species),
                        _Tag(text: pet.ageLabel),
                        _Tag(text: pet.gender),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetPlaceholder extends StatelessWidget {
  const _PetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: const BoxDecoration(
        color: AppConstants.lightPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pets_rounded,
        size: 42,
        color: AppConstants.darkText,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppConstants.darkText,
        ),
      ),
    );
  }
}
