class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.name,
    this.company,
    this.category,
    this.description,
    this.location,
    this.rating,
    this.services = const [],
    this.availability,
    this.meetingModes = const [],
  });

  final String id;
  final String name;
  final String? company;
  final String? category;
  final String? description;
  final String? location;
  final double? rating;
  final List<Map<String, dynamic>> services;
  final dynamic availability;
  final List<String> meetingModes;

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    final serviceList = json['services'];
    return ServiceProvider(
      id: _string(json['id'] ?? json['providerId'] ?? json['provider_id']),
      name: _string(
        json['name'] ?? json['fullName'] ?? json['full_name'] ??
            json['businessName'] ?? json['business_name'],
        fallback: 'Service provider',
      ),
      company: _nullableString(json['company'] ?? json['companyName']),
      category: _nullableString(json['category'] ?? json['primaryCategory']),
      description: _nullableString(json['description'] ?? json['bio']),
      location: _nullableString(
        json['location'] ?? json['address'] ?? json['city'],
      ),
      rating: _double(json['rating'] ?? json['averageRating']),
      services: serviceList is List
          ? serviceList.whereType<Map>().map(_toStringMap).toList()
          : const [],
      availability: json['availability'] ?? json['availableHours'],
      meetingModes: (json['meetingModes'] ?? json['meeting_modes']) is List
          ? ((json['meetingModes'] ?? json['meeting_modes']) as List)
              .map((value) => value.toString())
              .toList()
          : const [],
    );
  }
}

class ServiceWorkPost {
  const ServiceWorkPost({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.location,
    this.meetingMode,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String? category;
  final String? location;
  final String? meetingMode;
  final DateTime? createdAt;

  factory ServiceWorkPost.fromJson(Map<String, dynamic> json) =>
      ServiceWorkPost(
        id: _string(json['id']),
        title: _string(json['title'], fallback: 'Service request'),
        description: _string(json['description'] ?? json['details']),
        category: _nullableString(json['category']),
        location: _nullableString(json['location'] ?? json['city']),
        meetingMode: _nullableString(json['meetingMode'] ?? json['meeting_mode']),
        createdAt: DateTime.tryParse(
          (json['createdAt'] ?? json['created_at'] ?? '').toString(),
        ),
      );
}

class ServiceBooking {
  const ServiceBooking({
    required this.id,
    required this.status,
    this.providerName,
    this.clientName,
    this.serviceName,
    this.scheduledAt,
    this.meetingMode,
  });

  final String id;
  final String status;
  final String? providerName;
  final String? clientName;
  final String? serviceName;
  final DateTime? scheduledAt;
  final String? meetingMode;

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'];
    final client = json['client'];
    final service = json['service'];
    return ServiceBooking(
      id: _string(json['id'] ?? json['bookingId'] ?? json['booking_id']),
      status: _string(json['status'], fallback: 'pending'),
      providerName: _nullableString(
        json['providerName'] ??
            (provider is Map ? provider['name'] ?? provider['full_name'] : null),
      ),
      clientName: _nullableString(
        json['clientName'] ??
            (client is Map ? client['name'] ?? client['full_name'] : null),
      ),
      serviceName: _nullableString(
        json['serviceName'] ??
            (service is Map ? service['name'] : null) ??
            json['service_name'],
      ),
      scheduledAt: DateTime.tryParse(
        (json['scheduledAt'] ?? json['scheduled_at'] ?? '').toString(),
      ),
      meetingMode: _nullableString(
        json['meetingMode'] ?? json['meeting_mode'],
      ),
    );
  }
}

String _string(dynamic value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

String? _nullableString(dynamic value) =>
    value?.toString();

double? _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

Map<String, dynamic> _toStringMap(Map value) =>
    value.map((key, value) => MapEntry(key.toString(), value));
