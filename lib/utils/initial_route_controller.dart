import 'package:flutter/material.dart';
import 'package:imgrep/data/image_db.dart';
import 'package:imgrep/pages/get_started.dart';
import 'package:imgrep/pages/main_layout.dart';
import 'package:imgrep/utils/debug_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InitialRouteController extends StatefulWidget {
  const InitialRouteController({super.key});

  @override
  // ignore: library_private_types_in_public_api
  InitialRouteControllerState createState() => InitialRouteControllerState();
}

class InitialRouteControllerState extends State<InitialRouteController> {
  bool _seenGetStarted = false;
  bool _isLoading = true;
  bool _dbReady = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Run both initialization tasks in parallel
    await Future.wait([_checkFirstSeen(), _initializeDatabase()]);
    setState(() => _isLoading = false);
  }

  Future<void> _checkFirstSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenGetStarted') ?? false;
    if (!seen) {
      await prefs.setBool('seenGetStarted', true);
    }

    setState(() {
      _seenGetStarted = seen;
      _isLoading = false;
    });
  }

  Future<void> _initializeDatabase() async {
    try {
      await ImageDB.initialize();
      setState(() => _dbReady = true);
    } catch (e) {
      Dbg.e('Database initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_dbReady) {
      return const Scaffold(
        body: Center(child: Text('Failed to initialize database')),
      );
    }

    return _seenGetStarted ? MainLayout() : Getstarted();
  }
}
