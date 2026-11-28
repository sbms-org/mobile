class AppConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'SBMS_API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static String get baseUrl =>
      _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const int requestTimeout = 30;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Temporary development setting. Disable with --dart-define=SBMS_TEST_MODE=false before release.
  static const bool enableTestTools = bool.fromEnvironment(
    'SBMS_TEST_MODE',
    defaultValue: true,
  );
}
