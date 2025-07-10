import 'dart:io';

class Settings {
  static final bool useDeviceImages = Platform.isAndroid;
  static const int initialPageSize = 30;         // Amount of images that gets loaded at the startup
  static const int pageSize = 100;               // Amount of images that gets loaded in background during scrolling
  static const int batchSize = 100;              // Amount of images that stored once in database
  static const String assetImagesDir = 'assets/images/';
  static const List<String> supportedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
  ];
}
