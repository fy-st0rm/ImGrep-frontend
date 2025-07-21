import 'package:flutter/material.dart';
import 'package:imgrep/services/image_service.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerWidget extends StatefulWidget {
  
  final int initialIndex;

  const ImageViewerWidget({required this.initialIndex, super.key});

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  
  late final PageController _pageController;
  int currentIndex = 0;
  
  @override
  void initState() {
    _pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final total = ImageService.thumbnailCount;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: total,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemBuilder: (context, index) {
                  final fullImage = ImageService.getThumbnail(index);
                  if (fullImage == null) {
                    return const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 40),
                    );
                  }

                  return PhotoView(
                    imageProvider: MemoryImage(fullImage),
                    backgroundDecoration: const BoxDecoration(color: Colors.black),
                  );
              },
            ),
          ),

          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              itemBuilder: (context, index) {
                final thumb = ImageService.getThumbnail(index);
                final  isSelected = index == currentIndex;

                return GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(index);
                    setState(() => currentIndex = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: isSelected ? EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: thumb == null
                      ? const Icon(Icons.image, size: 60, color: Colors.grey)
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.memory(
                          thumb, 
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      )
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
