/// Centralized access to compile-time environment variables.
///
/// All values are injected via `--dart-define-from-file` at build time.
/// Usage: `flutter run --dart-define-from-file=.env.dev`
///
/// IMPORTANT: Never add default values containing real secrets here.
/// The `defaultValue` should be empty strings so the app fails loudly
/// if the env file is not provided.
class EnvKeys {
  EnvKeys._();

  // ── Firebase Web ──────────────────────────────────────────────────────
  static const String firebaseWebApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const String firebaseWebAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String firebaseWebMessagingSenderId =
      String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID');
  static const String firebaseWebProjectId =
      String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const String firebaseWebAuthDomain =
      String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const String firebaseWebStorageBucket =
      String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
  static const String firebaseWebMeasurementId =
      String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

  // ── Firebase Android ──────────────────────────────────────────────────
  static const String firebaseAndroidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String firebaseAndroidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String firebaseAndroidMessagingSenderId =
      String.fromEnvironment('FIREBASE_ANDROID_MESSAGING_SENDER_ID');
  static const String firebaseAndroidProjectId =
      String.fromEnvironment('FIREBASE_ANDROID_PROJECT_ID');
  static const String firebaseAndroidStorageBucket =
      String.fromEnvironment('FIREBASE_ANDROID_STORAGE_BUCKET');

  // ── Firebase iOS ──────────────────────────────────────────────────────
  static const String firebaseIosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const String firebaseIosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String firebaseIosMessagingSenderId =
      String.fromEnvironment('FIREBASE_IOS_MESSAGING_SENDER_ID');
  static const String firebaseIosProjectId =
      String.fromEnvironment('FIREBASE_IOS_PROJECT_ID');
  static const String firebaseIosStorageBucket =
      String.fromEnvironment('FIREBASE_IOS_STORAGE_BUCKET');
  static const String firebaseIosAndroidClientId =
      String.fromEnvironment('FIREBASE_IOS_ANDROID_CLIENT_ID');
  static const String firebaseIosIosClientId =
      String.fromEnvironment('FIREBASE_IOS_IOS_CLIENT_ID');
  static const String firebaseIosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  // ── Kakao ─────────────────────────────────────────────────────────────
  static const String kakaoNativeKey =
      String.fromEnvironment('KAKAO_NATIVE_KEY');
  static const String kakaoRestApiKey =
      String.fromEnvironment('KAKAO_REST_API_KEY');
  static const String kakaoJsKey =
      String.fromEnvironment('KAKAO_JS_KEY');

  // ── Naver Cloud Platform (Map SDK) ────────────────────────────────────
  static const String ncpClientId =
      String.fromEnvironment('NCP_CLIENT_ID');
  static const String ncpClientSecret =
      String.fromEnvironment('NCP_CLIENT_SECRET');

  // ── Naver Developers (Search API - legacy) ────────────────────────────
  static const String naverClientId =
      String.fromEnvironment('NAVER_CLIENT_ID');
  static const String naverClientSecret =
      String.fromEnvironment('NAVER_CLIENT_SECRET');
}
