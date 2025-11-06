import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'pages/home_page.dart';
=======
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'providers/user_provider.dart';
>>>>>>> Stashed changes

void main() {
  runApp(const PandoraApp());
}

class PandoraApp extends StatelessWidget {
  const PandoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '卡通工作管理应用',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        fontFamily: 'Nunito',
      ),
<<<<<<< Updated upstream
      home: const HomePage(),
=======
      home: const LoginPage(),
>>>>>>> Stashed changes
    );
  }
}