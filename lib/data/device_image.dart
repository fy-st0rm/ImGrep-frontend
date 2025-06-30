import 'package:imgrep/data/image_db.dart';
import 'package:imgrep/data/image_repository.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';
import 'package:photo_manager/photo_manager.dart';

class DeviceImageSource implements ImageSource {
  List<AssetPathEntity>? _cachedAlbums;
  bool _isInitialSyncDone = false;

  @override
  Future<List<AssetEntity>> getImages({int page = 0, int? size}) async {
    try {
      // Initialize database if not done
      if (!ImageDB.isInitialized) {
        await ImageDB.initialize();
      }

      // Perform initial sync if needed
      if (!_isInitialSyncDone) {
        await _syncWithDevice();
        _isInitialSyncDone = true;
      }

      // Get paginated results from database
      final pageSize = size ?? HomeScreenSettings.pageSize;
      final dbImages = await ImageDB.getPaginated(pageSize, page * pageSize);

      // Convert to AssetEntity objects
      final futures = dbImages.map(
        (img) => AssetEntity.fromId(img['id'] as String),
      );
      final list = await Future.wait(futures);
      return list.whereType<AssetEntity>().toList();
    } catch (e) {
      Dbg.e('Error loading images: $e');
      return [];
    }
  }

  @override
  Future<bool> hasImages() async {
    try {
      // Initialize database if not done
      if (!ImageDB.isInitialized) {
        await ImageDB.initialize();
      }
      final count = await ImageDB.getImageCount();
      if (count > 0) return true;

      // Fallback to device check if database is empty
      return await _checkDeviceForImages();
    } catch (e) {
      Dbg.e('Error checking for images: $e');
      return false;
    }
  }

  @override
  @override
  Future<void> clearCache() async {
    _cachedAlbums = null;
    _isInitialSyncDone = false;
    await ImageDB.clearAll(); // Clear database cache
  }

  Future<void> _syncWithDevice() async {
    try {
      final deviceImages = await _fetchAllDeviceImages();
      await _updateDatabase(deviceImages);
    } catch (e) {
      Dbg.e('Error syncing with device: $e');
    }
  }

  Future<List<AssetEntity>> _fetchAllDeviceImages() async {
    final albums = await _getAlbums();
    final List<AssetEntity> allImages = [];

    for (final album in albums) {
      final images = await album.getAssetListRange(
        start: 0,
        end: await album.assetCountAsync,
      );
      allImages.addAll(images);
    }

    return allImages;
  }

  Future<void> _updateDatabase(List<AssetEntity> images) async {
    await ImageDB.clearAll(); // Clear existing data

    // Batch insert with transaction
    await ImageDB.batchInsert(
      images
          .map(
            (img) => {
              'id': img.id,
              'path': img.relativePath ?? img.id,
              'modified': img.modifiedDateTime.millisecondsSinceEpoch,
            },
          )
          .toList(),
    );
  }

  Future<bool> _checkDeviceForImages() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    return albums.isNotEmpty && await albums.first.assetCountAsync > 0;
  }

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
