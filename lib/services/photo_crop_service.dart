import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../core/constants/app_constants.dart';

class PhotoCropService {
  PhotoCropService._();

  static Future<CroppedFile?> cropSquare({
    required BuildContext context,
    required String sourcePath,
    required String title,
    bool circular = false,
  }) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 88,
      maxWidth: 1400,
      maxHeight: 1400,
      uiSettings: [
        if (!kIsWeb)
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: AppConstants.primaryColor,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppConstants.primaryColor,
            cropFrameColor: AppConstants.primaryColor,
            cropGridColor: Colors.white70,
            cropStyle: circular ? CropStyle.circle : CropStyle.rectangle,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
        if (!kIsWeb)
          IOSUiSettings(
            title: title,
            doneButtonTitle: 'Save Crop',
            cancelButtonTitle: 'Cancel',
            // iPad can otherwise present the cropper without a clearly
            // visible action bar. Show its navigation bar so Save Crop is
            // available as an explicit commit action.
            embedInNavigationController: true,
            hidesNavigationBar: false,
            cropStyle: circular ? CropStyle.circle : CropStyle.rectangle,
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
        if (kIsWeb) WebUiSettings(context: context),
      ],
    );
  }
}
