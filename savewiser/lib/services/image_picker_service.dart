import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  Future<File?> takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    return picked != null ? File(picked.path) : null;
  }
}
