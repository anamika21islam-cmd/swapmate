import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SwapMateApp());
}

class SwapMateApp extends StatelessWidget {
  const SwapMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwapMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {'/login': (context) => const LoginScreen()},
      debugShowCheckedModeBanner: false,
    );
  }
}
