import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError('Supabase credentials are missing.');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // Perform a real backend request in debug mode.
  if (kDebugMode) {
    try {
      final result = await SupabaseService.checkBackend();

      debugPrint('VOYAGEMATE BACKEND: ${result['status']}');
      debugPrint('DATABASE: ${result['service']}');
      debugPrint('SERVER TIME: ${result['server_time']}');
    } catch (error, stackTrace) {
      debugPrint('VOYAGEMATE BACKEND CHECK FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const VoyageMateApp());
}

class VoyageMateApp extends StatelessWidget {
  const VoyageMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoyageMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
