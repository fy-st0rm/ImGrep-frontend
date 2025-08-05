import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:imgrep/pages/get_started.dart';
import 'package:imgrep/pages/loading.dart';
import 'package:imgrep/utils/initial_route_controller.dart';
import 'package:imgrep/services/image_service.dart';
import 'package:imgrep/services/database_service.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  // Initializing our services
  await DatabaseService.init(); 

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "ImGrep",
      theme: ThemeData(
        primaryColor: Color(0xFF141718),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => InitialRouteController(),
        'loading': (context) => Loading(),
        'getStarted': (context) => Getstarted(),
      },
    );
  }
}
