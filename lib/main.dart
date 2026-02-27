import 'package:flutter/material.dart';
import 'dart:ui';
import 'services/database_service.dart';
import 'screens/search_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (widget build, rendering, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
  };

  // Catch async/platform errors not caught by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== PLATFORM ERROR ===');
    debugPrint(error.toString());
    debugPrint(stack.toString());
    return true; // Handled
  };

  // Check onboarding status
  final prefs = await SharedPreferences.getInstance();
  final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.database;

  runApp(VocabularyMemoryApp(showOnboarding: !onboardingSeen));
}

class VocabularyMemoryApp extends StatelessWidget {
  final bool showOnboarding;

  const VocabularyMemoryApp({
    super.key,
    required this.showOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocabulary Memory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Note: 'SF Pro Display' is not bundled — Flutter uses system font
      ),
      home: showOnboarding ? const OnboardingScreen() : const SearchScreen(),
    );
  }
}
