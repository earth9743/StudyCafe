/// 앱 환경 설정
/// 실행 시 --dart-define=ENV=prod 로 운영 환경 전환
enum AppEnv {
  dev,
  prod;

  static AppEnv get current {
    const envStr = String.fromEnvironment('ENV', defaultValue: 'dev');
    return envStr == 'prod' ? AppEnv.prod : AppEnv.dev;
  }

  bool get isDev => this == AppEnv.dev;
  bool get isProd => this == AppEnv.prod;
}
