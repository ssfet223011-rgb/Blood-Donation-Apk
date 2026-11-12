import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend connection with client-safe anonymous key
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initial connection warning: $e');
  }

  runApp(
    const ProviderScope(
      child: BloodBondApp(),
    ),
  );
}
