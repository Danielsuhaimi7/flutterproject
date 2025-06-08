import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reserve_screen.dart';
import 'screens/home_screen.dart';
// You can add other screens like home_screen.dart, prediction_screen.dart etc.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Campus Parking System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/reserve': (context) => const ReserveScreen(),
        '/home': (context) => const HomeScreen(username: 'Daniel Suhaimi'), 
        // Add more routes as you build more screens
      },
    );
  }
}
