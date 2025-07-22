import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:imgrep/services/api/upload_image.dart';
import 'package:imgrep/services/api/user.dart';
import 'package:imgrep/services/database_service.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:imgrep/utils/settings.dart';

class SyncManager extends ChangeNotifier {
  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;

  static void setSyncing(bool value) {
    _isSyncing = value;
    _instance.notifyListeners();
  }

  static final SyncManager _instance = SyncManager._internal();
  SyncManager._internal();
  factory SyncManager() => _instance;
}

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  SyncPageState createState() => SyncPageState();
}

class SyncPageState extends State<SyncPage> {
  @override
  void initState() {
    super.initState();
    SyncManager().addListener(_updateState);
  }

  @override
  void dispose() {
    SyncManager().removeListener(_updateState);
    super.dispose();
  }

  // Refresh UI when SyncManager notifies
  void _updateState() => setState(() {});

  List<XFile> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  static Future<String> _syncImagesInBg(Map<String, dynamic> data) async {
    final imagePaths = data['imagePaths'] as List<String>;
    final userId = data['userId'] as String;
    final serverIp = data['serverIp'] as String;

    Dbg.i('Background sync started: $imagePaths');
    for (int i = 0; i < imagePaths.length; i++) {
      Dbg.i('Processing image ${i + 1}/${imagePaths.length}');
      final Map<String, dynamic>? res = await uploadImage(imagePaths[i], userId, serverIp);
        if (res != null) {
          String faissId = res["index"].toString(); // Convert int to String
          Dbg.i(faissId);
          String id = res["message"];
          Dbg.i(id);
          await DatabaseService.updateFaissIndex(id, faissId);
        }
    }
    return 'Synced ${imagePaths.length} images';
  }

  Future<void> _runSync(List<String> imagePaths) async {
    SyncManager.setSyncing(true);
    try {
      final userId = await UserManager.getUserId();
      if (userId == null) throw Exception('No user ID');
      final result = await _syncImagesInBg({
        'imagePaths': imagePaths,
        'userId': userId,
        'serverIp': Settings.serverIp,
      });

      // NOTE(slok): Removed compute cuz the db didnt worked inside it
      // final result = await compute(_syncImagesInBg, {
      //   'imagePaths': imagePaths,
      //   'userId': userId,
      //   'serverIp': Settings.serverIp,
      // });
      _showSnackBar(result);
    } catch (e) {
      Dbg.e(e);
      _showSnackBar('Error syncing: $e', isError: true);
    } finally {
      SyncManager.setSyncing(false);
    }
  }

  Future<void> _pickAndSyncImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => selectedImages = images);
        await _runSync(images.map((image) => image.path).toList());
      }
    } catch (e) {
      _showSnackBar('Error picking images: $e', isError: true);
    }
  }

  Future<void> _syncAllImages() async {
    // TODO :
    Dbg.todo(
      "poll the db for all image where is_sync == false nwith proper pagination",
    );
    final imagePaths = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
    await _runSync(imagePaths);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Sync'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black87,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Privacy Message
            Text(
              'At imgrep, your privacy matters. We don’t store images, only secure embeddings for fast image search.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            // Sync Buttons and Indicator
            SyncButtons(
              isSyncing: SyncManager.isSyncing,
              onSyncSelected: _pickAndSyncImages,
              onSyncAll: _syncAllImages,
            ),
            // Selected Images Count
            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Selected: ${selectedImages.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SyncButtons extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback onSyncSelected;
  final VoidCallback onSyncAll;

  const SyncButtons({
    super.key,
    required this.isSyncing,
    required this.onSyncSelected,
    required this.onSyncAll,
  });

  static final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isSyncing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
              'Ready to Sync',
              style: TextStyle(color: Colors.white),
            ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isSyncing ? null : onSyncSelected,
          style: _buttonStyle,
          child: const Text('Sync Selected'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isSyncing ? null : onSyncAll,
          style: _buttonStyle,
          child: const Text('Sync All'),
        ),
      ],
    );
  }
}
