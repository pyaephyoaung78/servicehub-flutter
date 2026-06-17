import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/auth/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();

  final apiClient = ApiClient(
    tokenStorage: tokenStorage,
  );

  final authService = AuthService(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  runApp(
    ServiceHubApp(
      authService: authService,
      tokenStorage: tokenStorage,
    ),
  );
}

class ServiceHubApp extends StatelessWidget {
  final AuthService authService;
  final TokenStorage tokenStorage;

  const ServiceHubApp({
    required this.authService,
    required this.tokenStorage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(
        authService: authService,
        tokenStorage: tokenStorage,
      )..initialize(),
      child: MaterialApp(
        title: 'ServiceHub',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}