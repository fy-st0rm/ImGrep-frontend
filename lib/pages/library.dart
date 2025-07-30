import 'package:flutter/material.dart';
import 'package:imgrep/pages/story_view.dart';
import 'package:imgrep/services/database_service.dart';
import 'package:imgrep/widgets/yearly_higlights.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class Story {
  final String id;
  final String title;
  final List<AssetEntity> assets;

  Story({required this.id, required this.title, required this.assets});
}

Future<List<Story>> loadStoriesFromDB() async {
  final db = await DatabaseService.database;
  final rows = await db.query('stories', orderBy: 'created_at DESC');

  List<Story> stories = [];
  for (final row in rows) {
    final String title = row['title'] as String;
    final String coverId = row['cover_image_id'] as String;

    final AssetEntity? cover = await AssetEntity.fromId(coverId);
    if (cover == null) continue;

    // Load only the cover image, not full list yet
    stories.add(Story(id: row['id'] as String, title: title, assets: [cover]));
  }

  return stories;
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
    "Snapshots from your {title} days.",
  ];

  final template = (templates..shuffle()).first;
  return template
      .replaceAll('{title}', title)
      .replaceAll('{count}', count.toString());
}

class LibraryScreen extends StatefulWidget {

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

  void loadStories() async {
    final loadedStories = await loadStoriesFromDB();
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
                                    (_) => StoryViewPage(storyId: story.id),
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

                    const YearHighlightsWidget(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
