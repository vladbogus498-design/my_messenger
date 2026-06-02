import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_screen.dart';
import 'screens/main_chat_screen.dart';
import 'screens/improved_splash_screen.dart';
import 'widgets/otp_verification_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'utils/rate_limiter.dart';
import 'services/bot_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Запуск периодической очистки rate limiters
  AppRateLimiters.startCleanup();
  
  // Создаем бота при запуске приложения
  BotService.ensureBotExists();
  
  runApp(
    const ProviderScope(
        child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'DarkKick Messenger',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const ImprovedSplashScreen(), // ✅ МГНОВЕННАЯ НАВИГАЦИЯ БЕЗ ПЕРЕЗАГРУЗКИ
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/main': (context) => MainChatScreen(),
        '/email-verification': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return EmailVerificationScreen(email: args ?? '');
        },
        '/phone-verification': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          return PhoneVerificationScreen(
            phoneNumber: args?['phone'] ?? '',
            verificationId: args?['verificationId'] ?? '',
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
