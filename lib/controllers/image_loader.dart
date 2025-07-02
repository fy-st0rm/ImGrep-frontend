import 'package:flutter/foundation.dart';
import 'package:imgrep/data/asset_image.dart';
import 'package:imgrep/data/device_image.dart';
import 'package:imgrep/utils/settings.dart';
import 'package:imgrep/utils/debug_logger.dart';

abstract class ImageSource {
  Future<List<dynamic>> getImages({int page = 0, int? size});
  Future<bool> hasImages();
  void clearCache();
}

/// Handles all image loading logic and state management
class ImageLoader extends ChangeNotifier {
  final ImageSource _source;
  final List<dynamic> _images = [];
  final Map<String, Uint8List> _thumbnailCache = {};

  bool _isLoading = false;
  bool _hasMoreImages = true;
  int _currentPage = 0;

  ImageLoader()
    : _source =
          HomeScreenSettings.useDeviceImages
              ? DeviceImageSource()
              : AssetImageSource();

  // Getters
  List<dynamic> get images => _images;
  int get imageCount => _images.length;
  bool get isEmpty => _images.isEmpty;
  bool get isLoading => _isLoading;
  bool get hasMoreImages => _hasMoreImages;

  // Thumbnail cache methods
  Uint8List? getCachedThumbnail(String key) => _thumbnailCache[key];
  void cacheThumbnail(String key, Uint8List data) =>
      _thumbnailCache[key] = data;

  /// Initialize image loading
  Future<void> initialize() async {
    if (_isLoading) return;

    try {
      final hasImages = await _source.hasImages();
      if (!hasImages) {
        _hasMoreImages = false;
        return;
      }

      await loadMoreImages();
    } catch (e) {
      Dbg.e('Error initializing images: $e');
    }
  }

  /// Load more images (pagination)
  Future<void> loadMoreImages() async {
    if (_isLoading || !_hasMoreImages) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newImages = await _source.getImages(page: _currentPage);
      if (newImages.isEmpty) {
        _hasMoreImages = false;
      } else {
        _images.addAll(newImages);
        _currentPage++;
      }
    } catch (e) {
      Dbg.e('Error loading images: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all images
  Future<void> refresh() async {
    _reset();
    await initialize();
  }

  /// Reset all state
  void _reset() {
    _images.clear();
    _thumbnailCache.clear();
    _currentPage = 0;
    _hasMoreImages = true;
    _isLoading = false;
    _source.clearCache();
    notifyListeners();
  }

  @override
  void dispose() {
    _thumbnailCache.clear();
    super.dispose();
  }
}
