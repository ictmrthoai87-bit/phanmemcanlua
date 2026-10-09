import 'package:flutter/material.dart';
import 'screens/farmer_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LuaCanProApp());
}

class LuaCanProApp extends StatelessWidget {
  const LuaCanProApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cân Lúa Pro - Sổ cân cho nhà nông',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F8F4),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF19704B)),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(52, 54), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F9F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD8E4DB)),
          borderRadius: BorderRadius.circular(13)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      ),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17),
              side: const BorderSide(color: Color(0xFFE1E9E1)))),
    ),
    home: const FarmerHomeScreen(),
  );
}
