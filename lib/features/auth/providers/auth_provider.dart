import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/storage/token_storage.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final TokenStorage tokenStorage;

  AuthProvider({required this.authService, required this.tokenStorage});

  AuthStatus _status = AuthStatus.checking;
  AuthUser? _user;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _status = AuthStatus.checking;
    notifyListeners();

    final hasToken = await tokenStorage.hasToken();

    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await authService.me();
      _status = AuthStatus.authenticated;
    } catch (_) {
      await tokenStorage.deleteToken();

      _user = null;
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _startSubmitting();

    try {
      _user = await authService.login(email: email, password: password);

      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    _startSubmitting();

    try {
      _user = await authService.register(
        name: name,
        email: email,
        password: password,
        referralCode: referralCode,
      );

      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> loginWithGoogle() async {
    _startSubmitting();

    try {
      _user = await authService.loginWithGoogle(role: 'customer');

      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<void> logout() async {
    _startSubmitting();

    try {
      await authService.logout();
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _finishSubmitting();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startSubmitting() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishSubmitting() {
    _isSubmitting = false;
    notifyListeners();
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        final errors = responseData['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }

        final message = responseData['message'];

        if (message != null) {
          return message.toString();
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'The server took too long to respond.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to the server.';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
