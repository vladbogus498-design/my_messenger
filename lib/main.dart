import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'auth/auth_screen.dart';
import 'auth/auth_credentials_screen.dart';
import 'screens/chats_screen.dart';
import 'widgets/otp_verification_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/rate_limiter.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOptions = AppConfig.firebaseOptions;
  if (firebaseOptions != null) {
    // Подключаем твой Firebase конфиг для браузера на ПК
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    // Обычная инициализация для мобилок
    await Firebase.initializeApp();
  }

  AppRateLimiters.startCleanup();

  runApp(const ProviderScope(child: MyApp()));
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
      // На ПК сразу открываем форму входа, на телефоне — сплеш
      home: const AuthGate(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/auth/sign-in': (context) => const AuthCredentialsScreen(
          initialMode: AuthCredentialsMode.signIn,
        ),
        '/auth/register': (context) => const AuthCredentialsScreen(
          initialMode: AuthCredentialsMode.register,
        ),
        '/main': (context) => const PresenceAwareHome(child: ChatScreen()),
        '/email-verification': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return EmailVerificationScreen(email: args ?? '');
        },
        '/phone-verification': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, String>?;
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

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user == null
          ? const AuthScreen()
          : const PresenceAwareHome(child: ChatScreen()),
      loading: () => const _DarkkickLoadingScreen(),
      error: (_, __) => const AuthScreen(),
    );
  }
}

class PresenceAwareHome extends StatefulWidget {
  const PresenceAwareHome({super.key, required this.child});

  final Widget child;

  @override
  State<PresenceAwareHome> createState() => _PresenceAwareHomeState();
}

class _PresenceAwareHomeState extends State<PresenceAwareHome>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserService.setPresence(isOnline: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UserService.setPresence(isOnline: true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      UserService.setPresence(isOnline: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserService.setPresence(isOnline: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DarkkickLoadingScreen extends StatelessWidget {
  const _DarkkickLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
