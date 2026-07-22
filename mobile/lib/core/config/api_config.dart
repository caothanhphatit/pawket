class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.devUserId,
  });

  factory ApiConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'PAWKET_API_BASE_URL',
      defaultValue: 'https://v2.poeviethoa.net/api/v1',
    );
    const devUserId = String.fromEnvironment('PAWKET_DEV_USER_ID');

    return const ApiConfig(
      baseUrl: baseUrl,
      devUserId: devUserId == '' ? null : devUserId,
    );
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// Development-only identity until managed OIDC is integrated.
  final String? devUserId;
}
