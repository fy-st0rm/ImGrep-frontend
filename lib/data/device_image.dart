import 'package:imgrep/data/image_repository.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';
import 'package:photo_manager/photo_manager.dart';

class DeviceImageSource implements ImageSource {
  List<AssetPathEntity>? _cachedAlbums;

  @override
  Future<List<AssetEntity>> getImages({int page = 0, int? size}) async {
    try {
      final albums = await _getAlbums();

      final List<AssetEntity> allImages = [];

      for (var album in albums) {
        final images = await album.getAssetListPaged(
          page: page,
          size: size ?? HomeScreenSettings.pageSize,
        );
        allImages.addAll(images);
      }

      return allImages;
    } catch (e) {
      Dbg.e('Error loading all device images: $e');
      return [];
    }
  }

  @override
  Future<bool> hasImages() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );
      if (albums.isEmpty) return false;
      return await albums.first.assetCountAsync > 0;
    } catch (e) {
      Dbg.e('Error checking device images: $e');
      return false;
    }
  }

  @override
  void clearCache() => _cachedAlbums = null;

  Future<List<AssetPathEntity>> _getAlbums() async {
    if (_cachedAlbums != null) return _cachedAlbums!;
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      _cachedAlbums = albums;
      return albums;
    } catch (e) {
      Dbg.e('Error loading albums: $e');
      return [];
    }
  }
}
