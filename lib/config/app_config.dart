class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String apiToken = String.fromEnvironment(
    'API_TOKEN',
    defaultValue: 'dev-hero-token',
  );

  static String get normalizedApiBaseUrl {
    final value = apiBaseUrl.trim();
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
