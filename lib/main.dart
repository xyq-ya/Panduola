import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'providers/user_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const PandoraApp(),
    ),
  );
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
      home: const LoginPage(),
    );
  }
}