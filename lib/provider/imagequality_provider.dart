import 'package:cinemax/models/image_preferences.dart';
import 'package:flutter/material.dart';

class ImagequalityProvider with ChangeNotifier {
  ImagePreferences imagePreferences = ImagePreferences();
  String _imageQuality = "w500/";
  String get imageQuality => _imageQuality;

  set imageQuality(String value) {
    _imageQuality = value;
    imagePreferences.setImageQuality(value);
    notifyListeners();
  }
}
