import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../home/screens/home_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );

      case AuthStatus.authenticated:
        return const HomeScreen();

      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}