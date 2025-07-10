import 'dart:io';
import 'package:flutter/material.dart';
import 'package:imgrep/utils/debug_logger.dart' show Dbg;
import 'package:imgrep/widgets/image_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ImageGrid(),
    );
  }
}
