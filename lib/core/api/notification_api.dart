import '../services/api_client.dart';
import '../models/notification_preferences.dart';

class NotificationApi {
  static Future<NotificationPreferences> getPreferences() async {
    final response = await ApiClient.get('/notification-preferences');
    return NotificationPreferences.fromJson(response['data']);
  }

  static Future<void> updateGlobalPreferences({
    bool? inAppEnabled,
    bool? pushEnabled,
    bool? emailEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (inAppEnabled != null) body['in_app_enabled'] = inAppEnabled;
    if (pushEnabled != null) body['push_enabled'] = pushEnabled;
    if (emailEnabled != null) body['email_enabled'] = emailEnabled;

    await ApiClient.put('/notification-preferences/global', body);
  }

  static Future<void> updateTypePreference(
    String notificationType,
    String channel,
    bool enabled,
  ) async {
    await ApiClient.put(
      '/notification-preferences/types/$notificationType',
      {'channel': channel, 'enabled': enabled},
    );
  }

  static Future<void> updateNotificationEmail(String? email) async {
    await ApiClient.put('/user/notification-email', {
      'notification_email': email,
    });
  }
}
