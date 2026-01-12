import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apt_apartment/backend/src/phong/services/auth_controller.dart';
import 'package:apt_apartment/frontend/src/hieu/screens/home_page.dart';
import 'package:apt_apartment/frontend/src/phong/screens/auth_screen.dart';
import 'package:apt_apartment/frontend/src/quang/theme/app_theme.dart';
import 'package:apt_apartment/supabase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );

  final authController = AuthController();
  await authController.restoreSession();
  runApp(AptConnectApp(authController: authController));
}

class AptConnectApp extends StatefulWidget {
  const AptConnectApp({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AptConnectApp> createState() => _AptConnectAppState();
}

class _AptConnectAppState extends State<AptConnectApp> {
  @override
  void dispose() {
    widget.authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APT-CONNECT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: AppTheme.appBackground(context),
          child: child,
        );
      },
      home: AuthGate(authController: widget.authController),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAuthState>(
      valueListenable: authController,
      builder: (context, state, _) {
        switch (state.status) {
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            return AuthScreen(controller: authController);
          case AuthStatus.authenticated:
            return AptConnectHomePage(authController: authController);
        }
      },
    );
  }
}
