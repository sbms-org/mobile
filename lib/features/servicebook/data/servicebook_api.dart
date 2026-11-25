import '../../../core/services/api_client.dart';
import '../domain/models/servicebook_models.dart';

class ServiceBookApi {
  static Future<List<ServiceProvider>> nearbyProviders({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? category,
    String? meetingMode,
  }) async {
    final response = await ApiClient.get(
      '/providers/nearby',
      queryParams: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        if (category != null && category.isNotEmpty) 'category': category,
        if (meetingMode != null && meetingMode.isNotEmpty)
          'meetingMode': meetingMode,
      },
    );
    return _list(response, 'providers').map(ServiceProvider.fromJson).toList();
  }

  static Future<ServiceProvider> provider(String id) async {
    final response = await ApiClient.get(
      '/providers/${Uri.encodeComponent(id)}',
    );
    final data = response['data'] ?? response['provider'] ?? response;
    if (data is! Map) {
      throw ApiException(
        'The provider response was not in the expected format.',
      );
    }
    return ServiceProvider.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static Future<List<ServiceWorkPost>> workFeed() async {
    final response = await ApiClient.get('/work-posts/feed');
    return _list(response, 'work posts').map(ServiceWorkPost.fromJson).toList();
  }

  static Future<List<ServiceBooking>> bookings() async {
    final response = await ApiClient.get('/bookings');
    return _list(response, 'bookings').map(ServiceBooking.fromJson).toList();
  }

  static Future<Map<String, dynamic>> createBooking({
    required String providerId,
    required String serviceId,
    required DateTime scheduledAt,
    required String meetingMode,
    String? notes,
  }) {
    return ApiClient.post('/bookings', {
      'providerId': providerId,
      'serviceId': serviceId,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'meetingMode': meetingMode,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
  ) {
    return ApiClient.patch(
      '/bookings/${Uri.encodeComponent(bookingId)}/status',
      {'status': status},
    );
  }

  static Future<Map<String, dynamic>> createWorkPost({
    required String title,
    required String description,
    required String category,
    required String meetingMode,
    required bool consentToShare,
    double? latitude,
    double? longitude,
  }) {
    if (!consentToShare) {
      throw ApiException('Consent is required before sharing a work post.');
    }
    return ApiClient.post('/work-posts', {
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'meetingMode': meetingMode,
      'consentToShare': true,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  static Future<Map<String, dynamic>> createIssue({
    required String category,
    required String description,
    String? bookingId,
  }) {
    return ApiClient.post('/issues', {
      'category': category,
      'description': description.trim(),
      if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
    });
  }

  static List<Map<String, dynamic>> _list(
    Map<String, dynamic> response,
    String resourceName,
  ) {
    final camelResource = resourceName.replaceAllMapped(
      RegExp(r'\s([a-z])'),
      (match) => match[1]!.toUpperCase(),
    );
    final underscoredResource = resourceName.replaceAll(' ', '_');
    dynamic value =
        response['data'] ??
        response['items'] ??
        response['results'] ??
        response[resourceName] ??
        response[camelResource] ??
        response[underscoredResource];
    if (value is Map) {
      value =
          value['items'] ??
          value['results'] ??
          value[resourceName] ??
          value[camelResource] ??
          value[underscoredResource] ??
          value['data'];
    }
    if (value is! List) {
      throw ApiException(
        'The $resourceName response was not in the expected format.',
      );
    }
    return value.whereType<Map>().map((item) {
      return item.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }
}
