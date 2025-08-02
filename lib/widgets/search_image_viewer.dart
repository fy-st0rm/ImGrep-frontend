import 'package:flutter/material.dart';
import 'package:imgrep/services/image_service.dart';
import 'package:photo_view/photo_view.dart';

class SearchImageViewerWidget extends StatefulWidget {
  final int initialIndex;
  final List<String> imageIds;

  const SearchImageViewerWidget({
    required this.initialIndex,
    required this.imageIds,
    super.key,
  });

  @override
  State<SearchImageViewerWidget> createState() => _SearchImageViewerWidgetState();
}

class _SearchImageViewerWidgetState extends State<SearchImageViewerWidget> {
  late final PageController _pageController;
  late final ScrollController _thumbnailScrollController;
  int currentIndex = 0;

  static const int thumbnailsPerPage = 8;

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailScrollController = ScrollController();
    currentIndex = widget.initialIndex;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  List<int> _getThumbnailIndices() {
    final total = widget.imageIds.length;

    int start = (currentIndex - thumbnailsPerPage ~/ 2).clamp(0, total - 1);
    int end = (start + thumbnailsPerPage).clamp(0, total);

    if (end - start < thumbnailsPerPage && start > 0) {
      start = (end - thumbnailsPerPage).clamp(0, total - 1);
    }

    return List.generate(end - start, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageIds.length;
    final thumbnailIndices = _getThumbnailIndices();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '${currentIndex + 1} of $total',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemBuilder: (context, index) {
                final imageId = widget.imageIds[index];

                return FutureBuilder(
                  future: ImageService.getThumbnailById(imageId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.white, size: 40),
                      );
                    }

                    return PhotoView(
                      imageProvider: MemoryImage(snapshot.data!),
                      backgroundDecoration: const BoxDecoration(color: Colors.black),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            height: 80,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              controller: _thumbnailScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: thumbnailIndices.length,
              itemBuilder: (context, listIndex) {
                final imageIndex = thumbnailIndices[listIndex];
                final imageId = widget.imageIds[imageIndex];
                final isSelected = imageIndex == currentIndex;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      imageIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.grey.withValues(alpha:0.3), width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FutureBuilder(
                      future: ImageService.getThumbnailById(imageId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError || snapshot.data == null) {
                          return Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.image, size: 30, color: Colors.grey),
                          );
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            snapshot.data!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
