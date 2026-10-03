import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../services/pet_service.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({
    super.key,
  });

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _speciesController = TextEditingController();

  final _breedController = TextEditingController();

  final PetService _petService = PetService();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _birthdate;

  String? _gender;

  Uint8List? _photoBytes;

  String? _photoExtension;

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();

    super.dispose();
  }

  // =========================================================
  // PHOTO
  // =========================================================

  Future<void> _choosePhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage(
          'The selected photo could not be read.',
        );
        return;
      }

      if (bytes.length > 8 * 1024 * 1024) {
        _showMessage(
          'Please choose a photo smaller than 8 MB.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      final extension = _extensionFromName(
        image.name,
      );

      setState(() {
        _photoBytes = bytes;
        _photoExtension = extension;
      });
    } catch (error) {
      _showMessage(
        'Could not select the photo.',
      );
    }
  }

  String _extensionFromName(
    String name,
  ) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'png';
    }

    if (lower.endsWith('.webp')) {
      return 'webp';
    }

    if (lower.endsWith('.heic')) {
      return 'heic';
    }

    return 'jpg';
  }

  // =========================================================
  // BIRTHDATE
  // =========================================================

  Future<void> _chooseBirthdate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthdate ??
          DateTime(
            now.year - 1,
            now.month,
            now.day,
          ),
      firstDate: DateTime(
        now.year - 100,
        1,
        1,
      ),
      lastDate: now,
      helpText: 'Select your pet\'s birthdate',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _birthdate = selected;
    });
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_birthdate == null) {
      _showMessage(
        'Please select your pet\'s birthdate.',
      );
      return;
    }

    if (_gender == null) {
      _showMessage(
        'Please select your pet\'s gender.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final pet = await _petService.addPet(
        name: _nameController.text,
        species: _speciesController.text,
        breed: _breedController.text,
        birthdate: _birthdate!,
        gender: _gender!,
        photoBytes: _photoBytes,
        photoExtension: _photoExtension,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop<Pet>(
        context,
        pet,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not save your pet: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Add Pet',
          style: TextStyle(
            color: AppConstants.darkText,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(
                    context,
                  ),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          color: AppConstants.darkText,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          children: [
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _choosePhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    _photoBytes != null
                        ? ClipOval(
                            child: Image.memory(
                              _photoBytes!,
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const CircleAvatar(
                            radius: 65,
                            backgroundColor: AppConstants.lightPrimary,
                            child: Icon(
                              Icons.pets_rounded,
                              size: 58,
                              color: AppConstants.darkText,
                            ),
                          ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _choosePhoto,
                icon: const Icon(
                  Icons.photo_library_rounded,
                ),
                label: const Text(
                  'Choose Pet Photo',
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pet Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppConstants.darkText,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Pet Name',
                hintText: 'e.g. Luna',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your pet\'s name.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _speciesController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Species',
                hintText: 'e.g. Dog, Cat, Bird',
                prefixIcon: Icon(
                  Icons.pets_outlined,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the species.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _breedController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Breed',
                hintText: 'e.g. Shih tzu',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the breed.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _saving ? null : _chooseBirthdate,
              borderRadius: BorderRadius.circular(
                16,
              ),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Birthdate',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                  ),
                ),
                child: Text(
                  _birthdate == null
                      ? 'Select birthdate'
                      : _formatDate(
                          _birthdate!,
                        ),
                  style: TextStyle(
                    color: _birthdate == null
                        ? Colors.black45
                        : AppConstants.darkText,
                    fontWeight: _birthdate == null
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                hintText: 'Select gender',
                prefixIcon: Icon(
                  Icons.wc_outlined,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Male',
                  child: Text('Male'),
                ),
                DropdownMenuItem(
                  value: 'Female',
                  child: Text('Female'),
                ),
                DropdownMenuItem(
                  value: 'Unknown',
                  child: Text(
                    'Unknown / Prefer not to say',
                  ),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _savePet,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.check_rounded,
                      ),
                label: Text(
                  _saving ? 'Saving Pet...' : 'Save Pet',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
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
      ),
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
