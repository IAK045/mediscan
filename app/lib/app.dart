import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_page.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
  ],
);

class MediScanApp extends StatelessWidget {
  const MediScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16845B);
    const blue = Color(0xFF2474D2);
    return MaterialApp.router(
      title: 'MediScan AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green).copyWith(
          primary: green,
          secondary: blue,
          surface: const Color(0xFFF7FAF8),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7FAF8),
          foregroundColor: Color(0xFF17231D),
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDE7E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDDE7E1)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE5ECE7)),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}
