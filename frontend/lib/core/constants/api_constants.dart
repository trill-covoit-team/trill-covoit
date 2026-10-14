abstract final class ApiConstants {
  // Adresse du serveur hôte accessible depuis l'émulateur Android.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const requestTimeout = Duration(seconds: 15);
}
