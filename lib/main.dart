import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_client.dart';
import 'features/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await supabaseService.initialize();

  runApp(const PitchPremierApp());
}

class PitchPremierApp extends StatelessWidget {
  const PitchPremierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitch Premier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF171717),
      ),
      home: const LoginScreen(),
    );
  }
}
