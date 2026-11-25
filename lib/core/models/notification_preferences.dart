class NotificationPreferences {
  final String id;
  final bool inAppEnabled;
  final bool pushEnabled;
  final bool emailEnabled;
  final Map<String, NotificationTypePreference> notificationTypes;

  NotificationPreferences({
    required this.id,
    required this.inAppEnabled,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.notificationTypes,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final types = <String, NotificationTypePreference>{};
    if (json['notification_types'] != null) {
      (json['notification_types'] as Map<String, dynamic>).forEach((key, value) {
        types[key] = NotificationTypePreference.fromJson(value as Map<String, dynamic>);
      });
    }
    return NotificationPreferences(
      id: json['id'] ?? '',
      inAppEnabled: json['in_app_enabled'] ?? true,
      pushEnabled: json['push_enabled'] ?? true,
      emailEnabled: json['email_enabled'] ?? false,
      notificationTypes: types,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'in_app_enabled': inAppEnabled,
    'push_enabled': pushEnabled,
    'email_enabled': emailEnabled,
    'notification_types': notificationTypes.map((key, value) => MapEntry(key, value.toJson())),
  };
}

class NotificationTypePreference {
  final bool inApp;
  final bool push;
  final bool email;

  NotificationTypePreference({
    required this.inApp,
    required this.push,
    required this.email,
  });

  factory NotificationTypePreference.fromJson(Map<String, dynamic> json) {
    return NotificationTypePreference(
      inApp: json['in_app'] ?? true,
      push: json['push'] ?? true,
      email: json['email'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'in_app': inApp,
    'push': push,
    'email': email,
  };
}
