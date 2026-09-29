enum AppEnvironment { dev, staging, prod }

class AppEnvironmentConfig {
  final AppEnvironment environment;

  const AppEnvironmentConfig(this.environment);

  String get host {
    switch (environment) {
      case AppEnvironment.dev:
        return '100.76.157.57:8080';
      case AppEnvironment.staging:
        return '100.76.157.57:8080';
      case AppEnvironment.prod:
        return 'api.ridetracking.app';
    }
  }

  String get baseUrl => 'http://$host/api/v1';
  String get wsUrl => 'ws://$host/ws';

  String get name {
    switch (environment) {
      case AppEnvironment.dev:
        return 'dev';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.prod:
        return 'prod';
    }
  }

  static AppEnvironmentConfig fromFlavor(String? flavor) {
    if (flavor == 'staging') {
      return const AppEnvironmentConfig(AppEnvironment.staging);
    }
    if (flavor == 'prod') {
      return const AppEnvironmentConfig(AppEnvironment.prod);
    }
    return const AppEnvironmentConfig(AppEnvironment.dev);
  }

  static AppEnvironmentConfig fromPackageName(String packageName) {
    if (packageName.endsWith('.staging')) {
      return const AppEnvironmentConfig(AppEnvironment.staging);
    }
    if (packageName.endsWith('.dev')) {
      return const AppEnvironmentConfig(AppEnvironment.dev);
    }
    return const AppEnvironmentConfig(AppEnvironment.dev);
  }
}
