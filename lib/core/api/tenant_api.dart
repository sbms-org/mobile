import 'dart:io';
import 'package:pm/core/services/secure_storage_service.dart';

import '../models/api_models.dart';
import '../../features/owner/domain/models/owner_payment_method.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';

class TenantApi {
  static Future<ApiResponse<List<Unit>>> getMyUnits() async {
    try {
      final response = await ApiClient.get('/tenant/my-units');

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => Unit.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get my units failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<AvailablePaymentMethod>>> getPaymentMethods(
    String assignmentId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/tenant/units/$assignmentId/payment-methods',
      );

      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((item) => AvailablePaymentMethod.fromJson(item))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get owner payment methods failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Receipt>> uploadReceipt({
    required String assignmentId,
    required File receipt,
    required String paymentMethodId,
    String? notes,
  }) async {
    try {
      // final tenantId = await SecureStorageService.getUserId();
      final fields = <String, String>{
        'assignmentId': assignmentId,
        'paymentMethodId': paymentMethodId,
      };
      if (notes != null) fields['notes'] = notes;

      final response = await ApiClient.multipartRequest(
        '/tenant/receipts',
        'POST',
        fields: fields,
        files: {'receipt': receipt},
      );

      return ApiResponse.fromJson(response, (data) => Receipt.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Upload receipt failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<PaymentHistory>>> getPaymentHistory(
    String assignmentId,
  ) async {
    try {
      final response = await ApiClient.get('/unit/$assignmentId/payment-history');

      return ApiResponse.fromJson(
        response,
        (data) =>
            (data as List).map((e) => PaymentHistory.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get payment history failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<dynamic>>> getDuePayments() async {
    try {
      final tenantId = await SecureStorageService.getUserId();
      final response = await ApiClient.get(
        '/tenant/due-payments',
        queryParams: {'tenantId': tenantId},
      );

      return ApiResponse.fromJson(response, (data) => data as List);
    } catch (e, s) {
      AppLogger.e('Get due payments failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await ApiClient.get('/tenant/profile');
      return ApiResponse.fromJson(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e, s) {
      AppLogger.e('Get tenant profile failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<dynamic>>> getNotifications() async {
    try {
      final tenantId = await SecureStorageService.getUserId();
      final response = await ApiClient.get(
        '/tenant/notifications',
        queryParams: {'tenantId': tenantId},
      );

      return ApiResponse.fromJson(response, (data) => data as List);
    } catch (e, s) {
      AppLogger.e('Get notifications failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> markNotificationRead(
    String notificationId,
  ) async {
    try {
      final response = await ApiClient.put(
        '/tenant/notifications/$notificationId/read',
        {},
      );
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Mark notification read failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> markAllNotificationsRead() async {
    try {
      final response = await ApiClient.put(
        '/tenant/notifications/read-all',
        {},
      );
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Mark all notifications read failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getDashboard(
    String tenantId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/tenant/dashboard',
        queryParams: {'tenantId': tenantId},
      );

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Get tenant dashboard failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> updateNotificationEmail(
    String? email,
  ) async {
    try {
      final response = await ApiClient.put('/tenant/notification-email', {
        'email': email,
      });
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Update notification email failed', e, s);
      rethrow;
    }
  }
}
