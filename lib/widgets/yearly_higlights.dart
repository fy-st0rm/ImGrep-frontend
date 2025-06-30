import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class YearHighlightsWidget extends StatefulWidget {
  final AssetPathEntity album;

  const YearHighlightsWidget({super.key, required this.album});

  @override
  State<YearHighlightsWidget> createState() => _YearHighlightsWidgetState();
}

class _YearHighlightsWidgetState extends State<YearHighlightsWidget> {
  List<AssetEntity> highlights = [];

  @override
  void initState() {
    super.initState();
    loadHighlights();
  }

  Future<void> loadHighlights() async {
    final now = DateTime.now();
    final DateTime cutoff = DateTime(now.year - 1, now.month, now.day);

    List<AssetEntity> olderAssets = [];

    const int pageSize = 100;
    final int total = await widget.album.assetCountAsync;

    for (int i = 0; i < total; i += pageSize) {
      final page = await widget.album.getAssetListPaged(
        page: i ~/ pageSize,
        size: pageSize,
      );

      for (var asset in page) {
        if (asset.createDateTime.isBefore(cutoff)) {
          olderAssets.add(asset);
        }
      }

      // Stop early if we have enough
      if (olderAssets.length >= 100) break;
    }

    olderAssets.shuffle();
    setState(() {
      highlights = olderAssets.take(20 ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Highlights from Last Year",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: highlights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final asset = highlights[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AssetEntityImage(
                  asset,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  isOriginal: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
