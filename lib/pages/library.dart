import 'package:flutter/material.dart';
import 'package:imgrep/widgets/yearly_higlights.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class Story {
  final String title;
  final List<AssetEntity> assets;

  Story({required this.title, required this.assets});
}

Future<List<Story>> generateStoriesByMonthOnly() async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) {
    PhotoManager.openSetting();
    return [];
  }

  final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    onlyAll: true,
  );

  final AssetPathEntity album = albums.first;
  const int maxAssets = 300; // Optional limit
  final int total = (await album.assetCountAsync).clamp(0, maxAssets);

  List<AssetEntity> allAssets = [];

  const int pageSize = 100;
  for (int i = 0; i < total; i += pageSize) {
    final List<AssetEntity> page = await album.getAssetListPaged(
      page: i ~/ pageSize,
      size: pageSize,
    );
    allAssets.addAll(page);
  }

  final now = DateTime.now();
  Map<String, List<AssetEntity>> storyGroups = {};

  for (AssetEntity asset in allAssets) {
    final date = asset.createDateTime;
    final String monthKey = DateFormat('MMMM yyyy').format(date);

    storyGroups.putIfAbsent(monthKey, () => []);
    storyGroups[monthKey]!.add(asset);
  }

  return storyGroups.entries.map((entry) {
    return Story(title: entry.key, assets: entry.value);
  }).toList();
}

String generateStoryDescription(String title, int count) {
  final List<String> templates = [
    "You ventured through the moments of {title}.",
    "Captured memories from your {title} journey.",
    "A visual journal of {title}.",
    "Your lens tells a story from {title}.",
    "Snippets of life from {title}.",
    "Moments frozen in time — {title}.",
    "Photos that whisper stories of {title}.",
    "A glimpse into your adventures in {title}.",
    "Revisiting your {title} timeline.",
    "{count} snapshots from your {title} days.",
  ];

  final template = (templates..shuffle()).first;
  return template
      .replaceAll('{title}', title)
      .replaceAll('{count}', count.toString());
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Story> stories = [];

  bool isLoading = true;
   AssetPathEntity? album;

  @override
  void initState() {
    super.initState();
    loadStories();
  }

   Future<void> loadStories() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return;

    album = albums.first;

    final loadedStories = await generateStoriesByMonthOnly();
    setState(() {
      stories = loadedStories;
      isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                final cover = story.assets.first;
                final description = generateStoryDescription(
                    story.title, story.assets.length);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child:Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      ),
                      AspectRatio(
                        aspectRatio: 3 / 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AssetEntityImage(
                            cover,
                            isOriginal: false,
                            fit: BoxFit.cover,
                          ),

                        ),
                      ),
                      const SizedBox(height: 8),
                     
                    ],
                  ),
                );
              },
            ),
             if (album != null) YearHighlightsWidget(album: album!),
                  const SizedBox(height: 20),
          ],
        ),
      ),
      
    );
  }
}
