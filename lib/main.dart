import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/user_provider.dart';
import 'pages/login_page.dart';
import 'web_pages/web_home_page.dart';
import 'web_pages/web_login.dart';

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

      // Web → Web登录页，App → App登录页
      home: kIsWeb ? const WebLoginPage() : const LoginPage(),
    );
  }
}
