class AppConfig {
  AppConfig._();

  // Android emulator -> host machine. Override with --dart-define for a real phone.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
