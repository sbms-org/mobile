import '../models/api_models.dart';
import '../services/api_client.dart';
import '../utils/logger.dart';

class PropertyManagerApi {
  // Buildings
  static Future<ApiResponse<List<Building>>> getBuildings() async {
    try {
      final response = await ApiClient.get('/pm/buildings');

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => Building.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get buildings failed', e, s);
      rethrow;
    }
  }

  // Receipts
  static Future<ApiResponse<List<Receipt>>> getPendingReceipts() async {
    try {
      final response = await ApiClient.get('/pm/receipts/pending');

      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => Receipt.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get pending receipts failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<Receipt>> acceptReceipt(
    String receiptId,
    String? notes,
  ) async {
    try {
      final response = await ApiClient.post('/pm/receipts/$receiptId/accept', {
        'notes': notes ?? '',
      });

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
      final response = await ApiClient.post('/pm/receipts/$receiptId/reject', {
        'reason': reason,
      });

      return ApiResponse.fromJson(response, (data) => Receipt.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Reject receipt failed', e, s);
      rethrow;
    }
  }

  // Dashboard
  static Future<ApiResponse<DashboardStats>> getDashboard() async {
    try {
      final response = await ApiClient.get('/pm/dashboard');
      return ApiResponse.fromJson(
        response,
        (data) => DashboardStats.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, s) {
      AppLogger.e('Get PM dashboard failed', e, s);
      rethrow;
    }
  }

  // Tenants
  static Future<ApiResponse<List<TenantSummary>>> getTenants() async {
    try {
      final response = await ApiClient.get('/owner/tenants');
      return ApiResponse.fromJson(
        response,
        (data) => (data as List).map((e) => TenantSummary.fromJson(e)).toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get PM tenants failed', e, s);
      rethrow;
    }
  }

  // My Permissions (what the owner has granted this PM)
  static Future<ApiResponse<List<PmBuildingPermission>>>
  getMyPermissions() async {
    try {
      final response = await ApiClient.get('/pm/my-permissions');
      return ApiResponse.fromJson(
        response,
        (data) => (data as List)
            .map(
              (e) => PmBuildingPermission.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
    } catch (e, s) {
      AppLogger.e('Get PM permissions failed', e, s);
      rethrow;
    }
  }

  // Reports
  static Future<ApiResponse<dynamic>> exportReports({
    required String type,
    String format = 'excel',
  }) async {
    try {
      final response = await ApiClient.get(
        '/pm/reports/export',
        queryParams: {'type': type, 'format': format},
      );

      return ApiResponse.fromJson(response, (data) => data);
    } catch (e, s) {
      AppLogger.e('Export reports failed', e, s);
      rethrow;
    }
  }

  // Unit Management
  static Future<ApiResponse<Unit>> updateUnitCycle(
    String unitId,
    int cycleMonths,
  ) async {
    try {
      final response = await ApiClient.post('/pm/units/$unitId/cycle', {
        'cycleMonths': cycleMonths,
      });

      return ApiResponse.fromJson(response, (data) => Unit.fromJson(data));
    } catch (e, s) {
      AppLogger.e('Update unit cycle failed', e, s);
      rethrow;
    }
  }

  // Tenant History
  static Future<ApiResponse<List<dynamic>>> getTenantHistory(
    String tenantId,
  ) async {
    try {
      final response = await ApiClient.get('/pm/tenants/$tenantId/history');

      return ApiResponse.fromJson(response, (data) => data as List);
    } catch (e, s) {
      AppLogger.e('Get tenant history failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<List<dynamic>>> getNotifications() async {
    try {
      final response = await ApiClient.get('/pm/notifications');
      return ApiResponse.fromJson(response, (data) => data as List);
    } catch (e, s) {
      AppLogger.e('Get PM notifications failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> markNotificationRead(String id) async {
    try {
      final response = await ApiClient.post('/pm/notifications/$id/read', {});
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Mark PM notification read failed', e, s);
      rethrow;
    }
  }

  static Future<ApiResponse<void>> markAllNotificationsRead() async {
    try {
      final response = await ApiClient.post('/pm/notifications/read-all', {});
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Mark all PM notifications read failed', e, s);
      rethrow;
    }
  }

  // Analytics
  static Future<ApiResponse<Map<String, dynamic>>> getAnalytics({
    int? month,
    int? year,
    String? propertyType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      if (propertyType != null) queryParams['propertyType'] = propertyType;

      final response = await ApiClient.get(
        '/pm/analytics',
        queryParams: queryParams,
      );
      return ApiResponse.fromJson(
        response,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e, s) {
      AppLogger.e('Get PM analytics failed', e, s);
      rethrow;
    }
  }

  // Notification Settings
  static Future<ApiResponse<dynamic>> getProfile() async {
    try {
      final response = await ApiClient.get('/pm/profile');
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
      final response = await ApiClient.put('/pm/notification-email', {
        'email': email,
      });
      return ApiResponse.fromJson(response, (data) => null);
    } catch (e, s) {
      AppLogger.e('Update notification email failed', e, s);
      rethrow;
    }
  }
}
