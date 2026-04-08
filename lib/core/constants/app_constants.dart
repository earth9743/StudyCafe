import '../config/app_env.dart';

/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  static const String appName = '카공지도';
  static const String appVersion = '1.0.0';

  // 혼잡도 보고 중복 방지 시간 (분)
  static const int reportCooldownMinutes = 30;

  // 혼잡도 집계 시 참조할 최근 시간 (분)
  static const int crowdAggregationMinutes = 60;

  // 리뷰 최대 글자 수
  static const int maxReviewLength = 500;

  // 리뷰 최대 사진 수
  static const int maxReviewPhotos = 3;

  // 카페 검색 기본 반경 (미터)
  static const double defaultSearchRadiusMeters = 1000;

  // 카카오 네이티브 앱 키 (환경별)
  static String get kakaoNativeKey => AppEnv.current.isProd
      ? '43a593f38892f3d61244057cd2f9fe51'
      : '1ef45814fc3792ec33ea0e7368ff1ada';

  // 카카오 REST API 키 (환경별)
  static String get kakaoRestApiKey => AppEnv.current.isProd
      ? '367d91592b095b037345b59c233caa54'
      : '096da5bcbb7eb667d3855607766de216';

  // 카카오 JS 키 (운영용만)
  static const String kakaoJsKey = '3cee1bedc238e8703a08fe521b22f785';

  // 네이버 클라우드 플랫폼 API 키 (지도 SDK용)
  static const String ncpClientId = 'df7ggcsnru';
  static const String ncpClientSecret = 'bCGCLGCfz9uvug7sD1w91JD4au8J6RiJX1blZXaz';

  // 네이버 개발자 센터 API 키 (검색 API용 - 레거시, 카카오로 전환됨)
  static const String naverClientId = '97yJY1Teft5Q98NhkzVk';
  static const String naverClientSecret = 'Tpm6LIoRGs';
}
