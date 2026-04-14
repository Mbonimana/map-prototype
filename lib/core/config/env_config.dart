class EnvConfig {
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static const String mapBoxToken = String.fromEnvironment(
    'MAPBOXTOKEN',
    defaultValue: '',
  );
}
