class EnvConfig {
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static const String mapBoxToken = String.fromEnvironment(
    'MAPBOXTOKEN',
    defaultValue: '',
  );
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
