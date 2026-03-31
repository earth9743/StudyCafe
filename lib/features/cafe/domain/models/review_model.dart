import 'package:cloud_firestore/cloud_firestore.dart';

/// 혼잡도 등급
enum CrowdLevel {
  low,      // 여유 (0~40%)
  moderate, // 보통 (41~75%)
  high;     // 혼잡 (76~100%)

  String get label {
    switch (this) {
      case CrowdLevel.low:
        return '여유';
      case CrowdLevel.moderate:
        return '보통';
      case CrowdLevel.high:
        return '혼잡';
    }
  }

  int get value {
    switch (this) {
      case CrowdLevel.low:
        return 1;
      case CrowdLevel.moderate:
        return 2;
      case CrowdLevel.high:
        return 3;
    }
  }

  static CrowdLevel fromValue(int v) {
    if (v <= 1) return CrowdLevel.low;
    if (v == 2) return CrowdLevel.moderate;
    return CrowdLevel.high;
  }
}

/// 콘센트 등급
enum OutletLevel {
  many,     // 많음 (70% 이상)
  moderate, // 보통 (30~69%)
  few;      // 적음 (30% 미만)

  String get label {
    switch (this) {
      case OutletLevel.many:
        return '많음';
      case OutletLevel.moderate:
        return '보통';
      case OutletLevel.few:
        return '적음';
    }
  }

  int get value {
    switch (this) {
      case OutletLevel.many:
        return 1;
      case OutletLevel.moderate:
        return 2;
      case OutletLevel.few:
        return 3;
    }
  }

  static OutletLevel fromValue(int v) {
    if (v <= 1) return OutletLevel.many;
    if (v == 2) return OutletLevel.moderate;
    return OutletLevel.few;
  }
}

/// 소음 등급
enum NoiseLevel {
  quiet,    // 조용
  moderate, // 보통
  loud;     // 시끄러움

  String get label {
    switch (this) {
      case NoiseLevel.quiet:
        return '조용';
      case NoiseLevel.moderate:
        return '보통';
      case NoiseLevel.loud:
        return '시끄러움';
    }
  }

  int get value {
    switch (this) {
      case NoiseLevel.quiet:
        return 1;
      case NoiseLevel.moderate:
        return 2;
      case NoiseLevel.loud:
        return 3;
    }
  }

  static NoiseLevel fromValue(int v) {
    if (v <= 1) return NoiseLevel.quiet;
    if (v == 2) return NoiseLevel.moderate;
    return NoiseLevel.loud;
  }
}

/// 리뷰 모델
class ReviewModel {
  final String id;
  final String cafeId;
  final String userId;
  final String userName;
  final int rating; // 1~5
  final CrowdLevel crowdLevel;
  final OutletLevel outletLevel;
  final NoiseLevel noiseLevel;
  final String content;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.cafeId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.crowdLevel,
    required this.outletLevel,
    required this.noiseLevel,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'cafeId': cafeId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'crowdLevel': crowdLevel.value,
      'outletLevel': outletLevel.value,
      'noiseLevel': noiseLevel.value,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromJson(String id, Map<String, dynamic> json) {
    return ReviewModel(
      id: id,
      cafeId: json['cafeId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '익명',
      rating: json['rating'] as int? ?? 3,
      crowdLevel: CrowdLevel.fromValue(json['crowdLevel'] as int? ?? 2),
      outletLevel: OutletLevel.fromValue(json['outletLevel'] as int? ?? 2),
      noiseLevel: NoiseLevel.fromValue(json['noiseLevel'] as int? ?? 2),
      content: json['content'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// 카페 리뷰 통계 (평균값)
class CafeReviewStats {
  final int reviewCount;
  final double averageRating;
  final double averageCrowd;  // 1=여유, 2=보통, 3=혼잡
  final double averageOutlet; // 1=많음, 2=보통, 3=적음
  final double averageNoise;  // 1=조용, 2=보통, 3=시끄러움

  const CafeReviewStats({
    required this.reviewCount,
    required this.averageRating,
    required this.averageCrowd,
    required this.averageOutlet,
    required this.averageNoise,
  });

  static const empty = CafeReviewStats(
    reviewCount: 0,
    averageRating: 0,
    averageCrowd: 0,
    averageOutlet: 0,
    averageNoise: 0,
  );

  String get crowdLabel {
    if (reviewCount == 0) return '정보 없음';
    if (averageCrowd <= 1.5) return '여유';
    if (averageCrowd <= 2.5) return '보통';
    return '혼잡';
  }

  String get outletLabel {
    if (reviewCount == 0) return '정보 없음';
    if (averageOutlet <= 1.5) return '많음';
    if (averageOutlet <= 2.5) return '보통';
    return '적음';
  }

  String get noiseLabel {
    if (reviewCount == 0) return '정보 없음';
    if (averageNoise <= 1.5) return '조용';
    if (averageNoise <= 2.5) return '보통';
    return '시끄러움';
  }

  static CafeReviewStats fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return empty;

    final count = reviews.length;
    final avgRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / count;
    final avgCrowd = reviews.map((r) => r.crowdLevel.value).reduce((a, b) => a + b) / count;
    final avgOutlet = reviews.map((r) => r.outletLevel.value).reduce((a, b) => a + b) / count;
    final avgNoise = reviews.map((r) => r.noiseLevel.value).reduce((a, b) => a + b) / count;

    return CafeReviewStats(
      reviewCount: count,
      averageRating: avgRating,
      averageCrowd: avgCrowd,
      averageOutlet: avgOutlet,
      averageNoise: avgNoise,
    );
  }
}
