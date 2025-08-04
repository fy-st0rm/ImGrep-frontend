import 'dart:async';
import 'package:flutter/material.dart';
import 'package:imgrep/services/api/upload_image.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:photo_view/photo_view.dart';
import 'package:imgrep/services/image_service.dart';

class ImageViewerWidget extends StatefulWidget {
  final int initialIndex;
  const ImageViewerWidget({super.key, required this.initialIndex});

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  late final PageController _pageController;
  int currentIndex = 0;
  bool _showMetadata = false;
  String caption = '';
  Future<String> getCaptionById(String id) async {
    caption = (await getCaption(id));
    Dbg.i(caption);
    return caption;
  }

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleMetadata(bool show) {
    setState(() => _showMetadata = show);
  }

  @override
  Widget build(BuildContext context) {
    final total = ImageService.thumbnailCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -200) {
                  _toggleMetadata(true); // Swipe up
                } else if (details.primaryVelocity! > 200) {
                  _toggleMetadata(false); // Swipe down
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                  _showMetadata = false;
                });
              },
              itemBuilder: (context, index) {
                final img = ImageService.getThumbnail(index);
                if (img == null) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 40,
                    ),
                  );
                }
                return PhotoView(
                  imageProvider: MemoryImage(img),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                );
              },
            ),
          ),

          if (!_showMetadata)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 70,
                child: Center(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: total,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, i) {
                      final thumb = ImageService.getThumbnail(i);
                      final isSelected = i == currentIndex;

                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding:
                              isSelected
                                  ? const EdgeInsets.all(2)
                                  : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white30,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child:
                                thumb == null
                                    ? Container(
                                      height: 60,
                                      width: 60,
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.white38,
                                      ),
                                    )
                                    : Image.memory(
                                      thumb,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Metadata Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showMetadata ? 0 : -220,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  ImageService.getMetadata(currentIndex),
                  getCaptionById(
                    ImageService.getImageId(currentIndex),
                  ), // assumes getImageId exists
                ]),

                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final metadata = snapshot.data![0] as Map<String, String>;
                  final caption = snapshot.data![1] as String;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Image Details",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...metadata.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Caption",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
