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

  static Future<ServiceProvider?> myProvider() async {
    final response = await ApiClient.get('/providers/me');
    final data = response['data'];
    if (data == null) return null;
    if (data is! Map) {
      throw ApiException(
        'The provider profile response was not in the expected format.',
      );
    }
    return ServiceProvider.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  static Future<Map<String, dynamic>> createProviderProfile({
    required String category,
    required double latitude,
    required double longitude,
  }) {
    return ApiClient.post('/providers', {
      'category': category.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'serviceRadiusKm': 25,
      'travelBufferMinutes': 30,
      'meetingModes': ['provider_comes', 'client_goes', 'third_location'],
    });
  }

  static Future<Map<String, dynamic>> createService({
    required String title,
    required String category,
    required String description,
    required int priceMinor,
    required int durationMinutes,
    required List<String> meetingModes,
  }) {
    return ApiClient.post('/providers/me/services', {
      'title': title.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'priceMinor': priceMinor,
      'durationMinutes': durationMinutes,
      'meetingModes': meetingModes,
    });
  }

  static Future<List<ServiceWorkPost>> workFeed() async {
    final response = await ApiClient.get('/work-posts/feed');
    return _list(response, 'work posts').map(ServiceWorkPost.fromJson).toList();
  }

  static Future<List<Map<String, dynamic>>> consentRequests() async {
    final response = await ApiClient.get('/work-posts/consent-requests');
    return _list(response, 'consent requests');
  }

  static Future<Map<String, dynamic>> respondToConsent(
    String postId, {
    required bool allowed,
    List<String> limitations = const [],
  }) {
    return ApiClient.post(
      '/work-posts/${Uri.encodeComponent(postId)}/consent',
      {'allowed': allowed, 'limitations': limitations},
    );
  }

  static Future<List<ServiceBooking>> bookings() async {
    final response = await ApiClient.get('/bookings');
    return _list(response, 'bookings').map(ServiceBooking.fromJson).toList();
  }

  static Future<Map<String, dynamic>> createBooking({
    required String providerId,
    required String serviceId,
    required DateTime scheduledAt,
    required int durationMinutes,
    required String meetingMode,
    required double latitude,
    required double longitude,
  }) {
    return ApiClient.post('/bookings', {
      'providerId': providerId,
      'serviceId': serviceId,
      'startsAt': scheduledAt.toUtc().toIso8601String(),
      'endsAt': scheduledAt
          .add(Duration(minutes: durationMinutes))
          .toUtc()
          .toIso8601String(),
      'mode': meetingMode,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
    String bookingId,
    String status,
  ) {
    return ApiClient.patch(
      '/bookings/${Uri.encodeComponent(bookingId)}/status',
      {'status': status.toUpperCase()},
    );
  }

  static Future<Map<String, dynamic>> createWorkPost({
    required String caption,
    String? area,
    required String photoUrl,
  }) {
    final uri = Uri.tryParse(photoUrl);
    if (uri == null ||
        !uri.hasScheme ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      throw ApiException('Enter a valid public photo URL before posting.');
    }
    return ApiClient.post('/work-posts', {
      'caption': caption.trim(),
      if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
      'media': [
        {'type': 'photo', 'url': uri.toString()},
      ],
    });
  }

  static Future<Map<String, dynamic>> createIssue({
    required String category,
    required String description,
    String? bookingId,
  }) {
    return ApiClient.post('/issues', {
      'type': switch (category.toLowerCase()) {
        'safety' => 'SAFETY',
        'conduct' => 'USER',
        _ => 'PLATFORM',
      },
      'subject': category,
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
