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

  // 카카오 네이티브 앱 키
  static const String kakaoNativeKey = '1ef45814fc3792ec33ea0e7368ff1ada';

  // 네이버 클라우드 플랫폼 API 키 (지도 SDK용)
  static const String ncpClientId = 'df7ggcsnru';
  static const String ncpClientSecret = 'bCGCLGCfz9uvug7sD1w91JD4au8J6RiJX1blZXaz';

  // 네이버 개발자 센터 API 키 (검색 API용 - 레거시, 카카오로 전환됨)
  static const String naverClientId = '97yJY1Teft5Q98NhkzVk';
  static const String naverClientSecret = 'Tpm6LIoRGs';

  // 카카오 REST API 키 (로컬 검색 API용)
  static const String kakaoRestApiKey = '096da5bcbb7eb667d3855607766de216';
}
