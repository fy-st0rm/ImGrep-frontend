import 'package:imgrep/controllers/image_loader.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';
import 'package:photo_manager/photo_manager.dart';

class DeviceImageSource implements ImageSource {
  List<AssetPathEntity>? _albumsCache;
  final Map<int, List<AssetEntity>> _pageCache = {};

  @override
  Future<List<AssetEntity>> getImages({int page = 0, int? size}) async {
    try {
      // Return cached page if available
      if (_pageCache.containsKey(page)) return _pageCache[page]!;

      final pageSize = size ?? HomeScreenSettings.pageSize;
      final albums = await _getAlbums();
      if (albums.isEmpty) return [];

      // Load images from all albums
      final allImages = <AssetEntity>[];
      for (final album in albums) {
        final albumImages = await album.getAssetListRange(
          start: 0,
          end: await album.assetCountAsync,
        );
        allImages.addAll(albumImages);
      }

      // Sort by newest first
      allImages.sort(
        (a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime),
      );

      // Paginate results
      final start = page * pageSize;
      final end = start + pageSize;
      final pageImages = allImages.sublist(
        start.clamp(0, allImages.length),
        end.clamp(0, allImages.length),
      );

      // Cache this page
      _pageCache[page] = pageImages;
      return pageImages;
    } catch (e) {
      Dbg.e('Error loading images: $e');
      return [];
    }
  }

  @override
  Future<bool> hasImages() async {
    try {
      final albums = await _getAlbums();
      return albums.isNotEmpty;
    } catch (e) {
      Dbg.e('Error checking for images: $e');
      return false;
    }
  }

  @override
  Future<void> clearCache() async {
    _albumsCache = null;
    _pageCache.clear();
  }

  Future<List<AssetPathEntity>> _getAlbums() async {
    if (_albumsCache != null) return _albumsCache!;

    _albumsCache = await PhotoManager.getAssetPathList(type: RequestType.image);
    return _albumsCache!;
  }
}
