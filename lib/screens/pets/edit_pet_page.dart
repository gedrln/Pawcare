import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../models/pet.dart';
import '../../services/photo_crop_service.dart';
import '../../services/pet_service.dart';

class EditPetPage extends StatefulWidget {
  final Pet pet;

  const EditPetPage({
    super.key,
    required this.pet,
  });

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _speciesController = TextEditingController();

  final _breedController = TextEditingController();

  final PetService _petService = PetService();

  final ImagePicker _imagePicker = ImagePicker();

  DateTime? _birthdate;

  String? _gender;
  String _petStatus = 'Alive';

  Uint8List? _photoBytes;

  String? _photoExtension;

  bool _removePhoto = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.pet.name;

    _speciesController.text = widget.pet.species;

    _breedController.text = widget.pet.breed;

    _birthdate = widget.pet.birthdate;

    _gender = widget.pet.gender;
    _petStatus = Pet.statusOptions.contains(widget.pet.petStatus)
        ? widget.pet.petStatus
        : 'Alive';
  }

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

      if (!mounted) return;
      final croppedImage = await PhotoCropService.cropSquare(
        context: context,
        sourcePath: image.path,
        title: 'Crop pet photo',
      );
      if (croppedImage == null || !mounted) return;

      final bytes = await croppedImage.readAsBytes();

      if (bytes.isEmpty) {
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

      setState(() {
        _photoBytes = bytes;
        _photoExtension = 'jpg';
        _removePhoto = false;
      });
    } catch (error) {
      if (mounted) _showMessage('Could not select the photo.');
    }
  }

  // =========================================================
  // BIRTHDATE
  // =========================================================

  Future<void> _chooseBirthdate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? now,
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
  // REMOVE PHOTO
  // =========================================================

  void _removeCurrentPhoto() {
    setState(() {
      _photoBytes = null;
      _photoExtension = null;
      _removePhoto = true;
    });
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
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
      final updatedPet = await _petService.updatePet(
        petId: widget.pet.id,
        name: _nameController.text,
        species: _speciesController.text,
        breed: _breedController.text,
        birthdate: _birthdate,
        gender: _gender!,
        petStatus: _petStatus,
        photoBytes: _photoBytes,
        photoExtension: _photoExtension,
        removePhoto: _removePhoto,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop<Pet>(
        context,
        updatedPet,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not update your pet: $error',
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
    final hasOldPhoto = widget.pet.photoUrl != null &&
        widget.pet.photoUrl!.isNotEmpty &&
        !_removePhoto;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Pet',
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
                        : hasOldPhoto
                            ? ClipOval(
                                child: Image.network(
                                  widget.pet.photoUrl!,
                                  width: 130,
                                  height: 130,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    _,
                                    __,
                                    ___,
                                  ) {
                                    return _placeholder();
                                  },
                                ),
                              )
                            : _placeholder(),
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
                  'Change Pet Photo',
                ),
              ),
            ),
            if (hasOldPhoto || _photoBytes != null)
              Center(
                child: TextButton.icon(
                  onPressed: _saving ? null : _removeCurrentPhoto,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
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
                labelText: 'Breed (optional)',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                ),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _saving ? null : _chooseBirthdate,
              borderRadius: BorderRadius.circular(
                16,
              ),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Birthdate (optional)',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                  ),
                  suffixIcon: _birthdate == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear birthdate',
                          onPressed: _saving
                              ? null
                              : () => setState(() => _birthdate = null),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                child: Text(
                  _birthdate == null
                      ? 'Select birthdate (optional)'
                      : _formatDate(
                          _birthdate!,
                        ),
                  style: const TextStyle(
                    color: AppConstants.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
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
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _petStatus,
              decoration: const InputDecoration(
                labelText: 'Pet Status',
                prefixIcon: Icon(Icons.favorite_outline_rounded),
              ),
              items: Pet.statusOptions
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _petStatus = value);
                    },
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveChanges,
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
                        Icons.save_rounded,
                      ),
                label: Text(
                  _saving ? 'Saving Changes...' : 'Save Changes',
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

  Widget _placeholder() {
    return const CircleAvatar(
      radius: 65,
      backgroundColor: AppConstants.lightPrimary,
      child: Icon(
        Icons.pets_rounded,
        size: 58,
        color: AppConstants.darkText,
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
