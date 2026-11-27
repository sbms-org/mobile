import '../models/api_models.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';

// Custom exception classes for better error handling
class PhoneValidationException implements Exception {
  final String message;
  final String code;
  PhoneValidationException(this.message, this.code);

  @override
  String toString() => message;
}

class OtpValidationException implements Exception {
  final String message;
  final String code;
  OtpValidationException(this.message, this.code);

  @override
  String toString() => message;
}

class AccountException implements Exception {
  final String message;
  final String code;
  AccountException(this.message, this.code);

  @override
  String toString() => message;
}

class AuthApi {
  static Future<Map<String, dynamic>> getDemoAccounts() async {
    final response = await ApiClient.get(
      '/auth/demo-users',
      requiresAuth: false,
    );
    final value = response['data'];
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw ApiException('The demo account response was not in the expected format.');
  }

  // Validate Ethiopian phone number format
  static String? validatePhoneNumber(String phone) {
    // Remove spaces and special characters
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Remove country code if present
    if (cleaned.startsWith('+251')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('251')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    // Must be exactly 9 digits
    if (!RegExp(r'^\d{9}$').hasMatch(cleaned)) {
      return 'Phone number must be 9 digits';
    }

    // Must start with 9 or 7
    if (!cleaned.startsWith('9') && !cleaned.startsWith('7')) {
      return 'Phone number must start with 9 or 7';
    }

    return null; // Valid
  }

  // Format phone number to +251XXXXXXXXX
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+251')) {
      return cleaned;
    } else if (cleaned.startsWith('251')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+251${cleaned.substring(1)}';
    } else {
      return '+251$cleaned';
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> sendOtp(
    String mobile,
  ) async {
    try {
      // Validate phone number
      final validationError = validatePhoneNumber(mobile);
      if (validationError != null) {
        AppLogger.e(validationError, 'INVALID_PHONE_FORMAT');
        throw PhoneValidationException(validationError, 'INVALID_PHONE_FORMAT');
      }

      // Format phone number
      final formattedMobile = formatPhoneNumber(mobile);

      AppLogger.d('Sending OTP');

      final response = await ApiClient.post('/auth/send-otp', {
        'mobile': formattedMobile,
      }, requiresAuth: false);

      AppLogger.i('OTP sent successfully to $formattedMobile');
      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Send OTP failed', e, s);

      // Parse API error
      if (e.toString().contains('USER_NOT_FOUND')) {
        throw AccountException(
          'No account found with this phone number',
          'USER_NOT_FOUND',
        );
      } else if (e.toString().contains('ACCOUNT_PENDING')) {
        throw AccountException('Account pending approval', 'ACCOUNT_PENDING');
      } else if (e.toString().contains('ACCOUNT_INACTIVE')) {
        throw AccountException(
          'Account is inactive. Please contact support.',
          'ACCOUNT_INACTIVE',
        );
      } else if (e.toString().contains('INVALID_PHONE_FORMAT')) {
        throw PhoneValidationException(
          'Invalid phone number format',
          'INVALID_PHONE_FORMAT',
        );
      }
      rethrow;
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp(
    String mobile,
    String otp,
  ) async {
    try {
      // Validate phone number
      final validationError = validatePhoneNumber(mobile);
      if (validationError != null) {
        throw PhoneValidationException(validationError, 'INVALID_PHONE_FORMAT');
      }

      // Validate OTP format
      if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
        throw OtpValidationException(
          'OTP must be 6 digits',
          'INVALID_OTP_FORMAT',
        );
      }

      // Format phone number
      final formattedMobile = formatPhoneNumber(mobile);

      AppLogger.d('Verifying OTP for: $formattedMobile');

      final response = await ApiClient.post('/auth/verify-otp', {
        'mobile': formattedMobile,
        'otp': otp,
      }, requiresAuth: false);

      if (response['success'] == true && response['data'] != null) {
        final token = response['data']['token'];
        final user = response['data']['user'];

        AppLogger.d('Token received');
        AppLogger.d('User role: ${user['role']}');

        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUserData(user);

        AppLogger.i('User logged in successfully - Role: ${user['role']}');
      }

      return ApiResponse.fromJson(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } on PhoneValidationException {
      rethrow;
    } on OtpValidationException {
      rethrow;
    } catch (e, s) {
      AppLogger.e('Verify OTP failed', e, s);

      // Parse API error
      if (e.toString().contains('INVALID_OTP')) {
        throw OtpValidationException(
          'Invalid OTP. Please check and try again.',
          'INVALID_OTP',
        );
      } else if (e.toString().contains('OTP_EXPIRED')) {
        throw OtpValidationException(
          'OTP has expired. Please request a new one.',
          'OTP_EXPIRED',
        );
      } else if (e.toString().contains('ACCOUNT_PENDING')) {
        throw AccountException('Account pending approval', 'ACCOUNT_PENDING');
      } else if (e.toString().contains('ACCOUNT_INACTIVE')) {
        throw AccountException('Account is inactive', 'ACCOUNT_INACTIVE');
      }

      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await SecureStorageService.clearAll();
      AppLogger.i('User logged out');
    } catch (e, s) {
      AppLogger.e('Logout failed', e, s);
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      final userData = await SecureStorageService.getUserData();
      return userData != null ? User.fromJson(userData) : null;
    } catch (e, s) {
      AppLogger.e('Get current user failed', e, s);
      return null;
    }
  }
}
