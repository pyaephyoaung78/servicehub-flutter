import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final errors = data['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List &&
              firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }

        final message = data['message'];

        if (message != null) {
          return message.toString();
        }
      }

      if (error.type ==
          DioExceptionType.connectionError) {
        return 'Cannot connect to the server.';
      }

      if (error.type ==
              DioExceptionType.connectionTimeout ||
          error.type ==
              DioExceptionType.receiveTimeout) {
        return 'The server took too long to respond.';
      }
    }

    return 'Something went wrong.';
  }
}