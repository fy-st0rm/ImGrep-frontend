import 'package:flutter/material.dart';
import 'package:imgrep/pages/story_view.dart';
import 'package:imgrep/widgets/yearly_higlights.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:imgrep/utils/debug_logger.dart' show Dbg;

class Story {
  final String title;
  final List<AssetEntity> assets;

  Story({required this.title, required this.assets});
}

Future<List<Story>> generateStoriesByMonthOnly() async {
  final PermissionState ps = await PhotoManager.requestPermissionExtend();
  if (!ps.isAuth) {
    Dbg.e(
      ps.hasAccess ? "Limited photo access granted" : "Photo permission denied",
    );
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: stories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final story = stories[index];
                        final cover = story.assets.first;
                        final description = generateStoryDescription(
                          story.title,
                          story.assets.length,
                        );

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => StoryViewPage(
                                      title: story.title,
                                      assets: story.assets,
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.black,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 3 / 2,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: AssetEntityImage(
                                      cover,
                                      isOriginal: false,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        story.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        maxLines: 3,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
