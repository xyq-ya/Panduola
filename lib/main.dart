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
    // 开发开关：若设为 true 则直接跳过登录页面，方便本地调试
    const bool SKIP_LOGIN = true; // 本地开发可切换为 false

    // 如果跳过登录，我们在首帧回调里设置 UserProvider 的 id，然后直接显示 HomePage
    return MaterialApp(
      title: '卡通工作管理应用',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        fontFamily: 'Nunito',
      ),
      home: Builder(builder: (context) {
        if (SKIP_LOGIN) {
          // 设置一个开发用的默认用户 id（根据你的 seed 数据可改为合适的 id）
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<UserProvider>(context, listen: false).setId(1);
          });
          return const HomePage(id: 1);
        }
        return const LoginPage();
      }),
    );
  }
}