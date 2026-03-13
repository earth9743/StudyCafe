/// Firestore 컬렉션/문서 경로 상수
class FirestorePaths {
  FirestorePaths._();

  // Top-level collections
  static const String users = 'users';
  static const String cafes = 'cafes';
  static const String cafeRequests = 'cafe_requests';

  // Sub-collections
  static const String crowdLogs = 'crowd_logs';
  static const String outletReports = 'outlet_reports';
  static const String noiseReports = 'noise_reports';
  static const String reviews = 'reviews';

  // Helper methods
  static String userDoc(String uid) => '$users/$uid';
  static String cafeDoc(String cafeId) => '$cafes/$cafeId';
  static String crowdLogsCol(String cafeId) => '$cafes/$cafeId/$crowdLogs';
  static String outletReportsCol(String cafeId) => '$cafes/$cafeId/$outletReports';
  static String noiseReportsCol(String cafeId) => '$cafes/$cafeId/$noiseReports';
  static String reviewsCol(String cafeId) => '$cafes/$cafeId/$reviews';
}
