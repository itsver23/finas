import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (connected) {
    await Supabase.initialize(url: supaUrl, publishableKey: supaKey);
  }
  runApp(const BurnApp());
}

class BurnApp extends StatelessWidget {
  const BurnApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BURN Clothing',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: red,
        brightness: Brightness.dark,
        surface: const Color(0xFF1B1B1B),
      ),
      scaffoldBackgroundColor: black,
      cardColor: const Color(0xFF202020),
      canvasColor: black,
      chipTheme: const ChipThemeData(backgroundColor: Color(0xFF242424), selectedColor: red, side: BorderSide.none, labelStyle: TextStyle(color: Colors.white)),
      dividerColor: const Color(0xFF343434),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF181818),
        indicatorColor: red.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(color: Colors.white)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? red : const Color(0xFFBDBDBD),
        )),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF242424),
        labelStyle: TextStyle(color: Color(0xFFCCCCCC)),
        hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
        border: OutlineInputBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: red, foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    ),
    home: const LoadingPage(),
  );
}
