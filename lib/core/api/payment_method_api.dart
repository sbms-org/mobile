import '../models/api_models.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';
import '../../features/owner/domain/models/owner_payment_method.dart';

class PaymentMethodApi {
  // Get available payment methods (admin-configured)
  static Future<ApiResponse<List<AvailablePaymentMethod>>> getAvailablePaymentMethods() async {
    try {
      final response = await ApiClient.get('/owner-payment-methods/available');
      
      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((item) => AvailablePaymentMethod.fromJson(item))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get available payment methods failed', e, s);
      rethrow;
    }
  }

  // Get owner's configured payment methods
  static Future<ApiResponse<List<OwnerPaymentMethod>>> getOwnerPaymentMethods() async {
    try {
      final response = await ApiClient.get('/owner-payment-methods/my-methods');
      
      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map((item) => OwnerPaymentMethod.fromJson(item))
            .toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get owner payment methods failed', e, s);
      rethrow;
    }
  }

  // Add payment method
  static Future<ApiResponse<OwnerPaymentMethod>> addPaymentMethod({
    required String paymentMethodId,
    String? accountNumber,
    String? accountName,
    String? mobileNumber,
    String? additionalInfo,
  }) async {
    try {
      final response = await ApiClient.post(
        '/owner-payment-methods/my-methods',
        {
          'paymentMethodId': paymentMethodId,
          if (accountNumber != null) 'accountNumber': accountNumber,
          if (accountName != null) 'accountName': accountName,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
          if (additionalInfo != null) 'additionalInfo': additionalInfo,
        },
      );

      return ApiResponse.fromJson(
        response,
        (data) => OwnerPaymentMethod.fromJson(data),
      );
    } catch (e, s) {
      AppLogger.e('Add payment method failed', e, s);
      rethrow;
    }
  }

  // Update payment method
  static Future<ApiResponse<OwnerPaymentMethod>> updatePaymentMethod({
    required String id,
    String? accountNumber,
    String? accountName,
    String? mobileNumber,
    String? additionalInfo,
    bool? isActive,
  }) async {
    try {
      final response = await ApiClient.put(
        '/owner-payment-methods/my-methods/$id',
        {
          if (accountNumber != null) 'accountNumber': accountNumber,
          if (accountName != null) 'accountName': accountName,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
          if (additionalInfo != null) 'additionalInfo': additionalInfo,
          if (isActive != null) 'isActive': isActive ? 1 : 0,
        },
      );

      return ApiResponse.fromJson(
        response,
        (data) => OwnerPaymentMethod.fromJson(data),
      );
    } catch (e, s) {
      AppLogger.e('Update payment method failed', e, s);
      rethrow;
    }
  }

  // Delete payment method
  static Future<ApiResponse<void>> deletePaymentMethod(String id) async {
    try {
      final response = await ApiClient.delete('/owner-payment-methods/my-methods/$id');
      
      return ApiResponse.fromJson(response, (_) => null);
    } catch (e, s) {
      AppLogger.e('Delete payment method failed', e, s);
      rethrow;
    }
  }
}
