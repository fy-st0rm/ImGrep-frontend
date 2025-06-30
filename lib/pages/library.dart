import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
class Story {
  final String title;
  final List<AssetEntity> assets;

  Story({required this.title, required this.assets});
}
Future<List<Story>> generateStoriesByMonthAndLocation() async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) {
    PhotoManager.openSetting();
    return [];
  }

  // Get all image assets
  List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    onlyAll: true,
  );
List<AssetEntity> allAssets = [];
final AssetPathEntity album = albums.first;
final int total = await album.assetCountAsync;

const int pageSize = 100;
for (int i = 0; i < total; i += pageSize) {
  final List<AssetEntity> page = await album.getAssetListPaged(
    page: i ~/ pageSize,
    size: pageSize,
  );
  allAssets.addAll(page);
}

  // Map to store grouped stories
  Map<String, List<AssetEntity>> storyGroups = {};

  for (AssetEntity asset in allAssets) {
    final date = asset.createDateTime;
    final month = DateFormat('MMMM yyyy').format(date);

    String locationName = '';
    if (asset.latitude != 0 && asset.longitude != 0) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          asset.latitude ?? 0.0,
          asset.longitude ?? 0.0,
        );
        if (placemarks.isNotEmpty) {
          locationName = placemarks.first.locality ?? placemarks.first.administrativeArea ?? '';
        }
      } catch (e) {
        locationName = '';
      }
    }

    final groupKey = locationName.isNotEmpty ? '$month - $locationName' : month;

    storyGroups.putIfAbsent(groupKey, () => []);
    storyGroups[groupKey]!.add(asset);
  }

  // Convert to Story objects
  List<Story> stories = storyGroups.entries.map((entry) {
    return Story(title: entry.key, assets: entry.value);
  }).toList();

  return stories;
}


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Story> stories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStories();
  }

  Future<void> loadStories() async {
    final result = await generateStoriesByMonthAndLocation();
    setState(() {
      stories = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return ListTile(
                  leading: AssetEntityImage(
                    story.assets.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(story.title),
                  subtitle: Text('${story.assets.length} items'),
                  onTap: () {
                    // Navigate to detail page
                  },
                );
              },
            ),
    );
  }
}