import 'dart:convert';
import 'dart:io';
import '../models/api_models.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';
import 'dart:typed_data';

class OwnerApi {
  // Building Management
  static Future<ApiResponse<Building>> createBuilding(
    Map<String, String> data,
    File propertyDeed,
    File certificateOfTitle,
    File businessTin,
  ) async {
    try {
      final response = await ApiClient.multipartRequest(
        '/owner/buildings',
        'POST',
        fields: {'data': jsonEncode(data)},
        files: {
          'property_deed': propertyDeed,
          'certificate_of_title': certificateOfTitle,
          'business_tin_number_url': businessTin,
        },
      );

      return ApiResponse.fromJson(response, (data) => Building.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Create building failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Building>> updateBuilding(
    String buildingId,
    Map<String, String> data,
    File? propertyDeed,
    File? certificateOfTitle,
    File? businessTin,
  ) async {
    try {
      final files = <String, File>{};
      if (propertyDeed != null) files['property_deed'] = propertyDeed;
      if (certificateOfTitle != null)
        files['certificate_of_title'] = certificateOfTitle;
      if (businessTin != null) files['business_tin_number_url'] = businessTin;

      final response = await ApiClient.multipartRequest(
        '/owner/buildings/$buildingId',
        'PUT',
        fields: {'data': jsonEncode(data)},
        files: files,
      );

      return ApiResponse.fromJson(response, (data) => Building.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Update building failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<Building>>> getBuildings(
    String ownerId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/owner/buildings',
        queryParams: {'ownerId': ownerId},
      );

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => Building.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get buildings failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Building>> getBuilding(String buildingId) async {
    try {
      final response = await ApiClient.get('/owner/buildings/$buildingId');

      return ApiResponse.fromJson(response, (data) => Building.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Get building failed', e, s);
      rethrow;
    }
  }

  // Unit Management
  static Future<ApiResponse<List<Unit>>> getBuildingUnits(
    String buildingId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/owner/buildings/$buildingId/units',
      );

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => Unit.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get building units failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Unit>> getUnit(String unitId) async {
    try {
      final response = await ApiClient.get('/owner/units/$unitId');

      return ApiResponse.fromJson(response, (data) => Unit.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Get unit failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Unit>> updateUnit(
    String unitId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiClient.put('/units/$unitId', data);

      return ApiResponse.fromJson(response, (data) => Unit.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Update unit failed', e, s);
      rethrow;
    }
  }

  // Tenant Management
  static Future<ApiResponse<dynamic>> registerTenantForUnit(
    String unitId,
    String mobile,
    String fullname,
  ) async {
    try {
      final response = await ApiClient.post(
        '/owner/units/$unitId/register-tenant',
        {'mobile': mobile, 'fullname': fullname},
      );

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Register tenant failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<dynamic>> verifyTenantOtp(
    String unitId,
    String mobile,
    String otp,
  ) async {
    try {
      final response = await ApiClient.post('/owner/units/$unitId/verify-otp', {
        'mobile': mobile,
        'otp': otp,
      });

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Verify tenant OTP failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Unit>> assignTenant(
    String unitId,
    String tenantId,
  ) async {
    try {
      final response = await ApiClient.post(
        '/owner/units/$unitId/assign-tenant',
        {'tenantId': tenantId},
      );

      return ApiResponse.fromJson(response, (data) => Unit.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Assign tenant failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<dynamic>> notifyTenantDue(String unitId) async {
    try {
      final response = await ApiClient.post('/owner/units/$unitId/notify-due', {});
      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Notify tenant due failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<dynamic>> assignTenantWithDetails(
    String unitId,
    String tenantMobile,
    String tenantName,
    DateTime startDate,
    DateTime endDate,
    int paymentCycleMonths,
    File? leaseDocument,
  ) async {
    try {
      final data = {
        'tenantMobile': tenantMobile,
        'tenantName': tenantName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'paymentCycleMonths': paymentCycleMonths,
      };

      final fields = <String, String>{'data': jsonEncode(data)};
      final files = leaseDocument != null
          ? {'lease_document': leaseDocument}
          : null;

      final response = await ApiClient.multipartRequest(
        '/owner/units/$unitId/assign-tenant',
        'POST',
        fields: fields,
        files: files,
      );

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Assign tenant with details failed', e, s);
      rethrow;
    }
  }

  // Receipt Management
  static Future<ApiResponse<List<Receipt>>> getPendingReceipts() async {
    try {
      final response = await ApiClient.get('/owner/pending-receipts');

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => Receipt.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get pending receipts failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<TenantSummary>>> getTenants() async {
    try {
      final response = await ApiClient.get('/owner/tenants');

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => TenantSummary.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get tenants failed', e, s);
      rethrow;
    }
  }

  /// Fetch summary/stats for a single tenant by id. Returns same shape as
  /// the objects returned in [getTenants]. Useful when opening the detail page
  /// directly or refreshing values.
  static Future<ApiResponse<TenantSummary>> getTenantDetails(String tenantId) async {
    try {
      final response = await ApiClient.get('/owner/tenants/$tenantId');

      return ApiResponse.fromJson(
        response,
        (data) => TenantSummary.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, s) {
      AppLogger.e('Get tenant details failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Receipt>> acceptReceipt(
    String receiptId,
    String? notes,
  ) async {
    try {
      final response = await ApiClient.post(
        '/owner/receipts/$receiptId/accept',
        {'notes': notes ?? ''},
      );

      return ApiResponse.fromJson(response, (data) => Receipt.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Accept receipt failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Receipt>> rejectReceipt(
    String receiptId,
    String reason,
  ) async {
    try {
      final response = await ApiClient.post(
        '/owner/receipts/$receiptId/reject',
        {'reason': reason},
      );

      return ApiResponse.fromJson(response, (data) => Receipt.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Reject receipt failed', e, s);
      rethrow;
    }
  }

  // Dashboard & Analytics
  static Future<ApiResponse<DashboardStats>> getDashboard(
    String ownerId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/owner/dashboard',
        queryParams: {'ownerId': ownerId},
      );

      return ApiResponse.fromJson(
        response,
        (data) => DashboardStats.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, s) {
      AppLogger.e('Get dashboard failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAnalytics({
    int? month,
    int? year,
    String? propertyType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month.toString();
      if (year != null) queryParams['year'] = year.toString();
      if (propertyType != null) queryParams['propertyType'] = propertyType;

      const url = '/owner/analytics';
      final response = await ApiClient.get(url, queryParams: queryParams);

      return ApiResponse.fromJson(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e, s) {
      AppLogger.e('Get analytics failed', e, s);
      rethrow;
    }
  }

  // Payment History
  static Future<ApiResponse<List<PaymentHistory>>> getPaymentHistory(
    String unitId,
  ) async {
    try {
      final response = await ApiClient.get('/tenant/payment-history/$unitId');

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

  static Future<Uint8List> exportReportBytes({
    required String type,
    String format = 'excel',
    Map<String, dynamic>? extraParams,
  }) async {
    try {
      final queryParams = {
        'type': type,
        'format': format,
        if (extraParams != null) ...extraParams,
      };

      return await ApiClient.download(
        '/owner/reports/export',
        queryParams: queryParams,
      );
    } catch (e, s) {
      AppLogger.e('Download report failed', e, s);
      rethrow;
    }
  }

  // Property Manager Management
  static Future<ApiResponse<List<PropertyManager>>>
  getPropertyManagers() async {
    try {
      final response = await ApiClient.get('/owner/property-managers');

      return ApiResponse.fromJson(
        response,
        (data) =>
            (data as List).map((e) => PropertyManager.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get property managers failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<PropertyManager>> getPropertyManagerDetails(
    String pmId,
  ) async {
    try {
      final response = await ApiClient.get('/owner/property-managers/$pmId');

      return ApiResponse.fromJson(
        response,
        (data) => PropertyManager.fromJson(data),
      );
    } catch (e, s) {
      AppLogger.e('Get property manager details failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<dynamic>> assignPropertyManager(
    String mobile,
    String fullname,
  ) async {
    try {
      final response = await ApiClient.post('/owner/property-managers', {
        'mobile': mobile,
        'fullname': fullname,
      });

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Assign property manager failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<PropertyManager>> verifyPropertyManagerOtp(
    String mobile,
    String otp,
  ) async {
    try {
      final response = await ApiClient.post('/owner/property-managers/verify', {
        'mobile': mobile,
        'otp': otp,
      });

      return ApiResponse.fromJson(
        response,
        (data) => PropertyManager.fromJson(data),
      );
    } catch (e, s) {
      AppLogger.e('Verify property manager OTP failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> updatePMAssignments(
    String pmId,
    List<Map<String, dynamic>> assignments,
  ) async {
    try {
      final response = await ApiClient.post(
        '/owner/property-managers/$pmId/assignments',
        {'assignments': assignments},
      );

      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Update PM assignments failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<dynamic>> revokePropertyManager(String pmId) async {
    try {
      final response = await ApiClient.delete('/owner/property-managers/$pmId');

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Revoke property manager failed', e, s);
      rethrow;
    }
  }

  // Notification Settings
  static Future<ApiResponse<List<dynamic>>> getNotifications() async {
    try {
      final response = await ApiClient.get('/owner/notifications');
      return ApiResponse.fromJson(response, (data) => data as List);
    } catch (e, s) {
      AppLogger.e('Get notifications failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> markNotificationRead(String id) async {
    try {
      final response = await ApiClient.post(
        '/owner/notifications/$id/read',
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
      final response = await ApiClient.post(
        '/owner/notifications/read-all',
        {},
      );
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Mark all notifications read failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<dynamic>> getProfile() async {
    try {
      final response = await ApiClient.get('/owner/profile');
      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Get profile failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> updateNotificationEmail(
    String? email,
  ) async {
    try {
      final response = await ApiClient.put('/owner/notification-email', {
        'email': email,
      });
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Update notification email failed', e, s);
      rethrow;
    }
  }
}
