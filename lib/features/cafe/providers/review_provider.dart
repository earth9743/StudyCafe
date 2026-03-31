import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';

/// cafeId 생성 유틸리티: name + lat + lng 조합
String generateCafeId(String name, double lat, double lng) {
  final sanitized = name.replaceAll(RegExp(r'[^\w가-힣]'), '_');
  return '${sanitized}_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
}

/// 특정 카페의 리뷰 목록 Provider
final cafeReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, cafeId) {
  return FirebaseFirestore.instance
      .collection('cafes')
      .doc(cafeId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.id, doc.data()))
          .toList());
});

/// 특정 카페의 리뷰 통계 Provider
final cafeReviewStatsProvider =
    Provider.family<CafeReviewStats, String>((ref, cafeId) {
  final reviewsAsync = ref.watch(cafeReviewsProvider(cafeId));
  return reviewsAsync.when(
    data: (reviews) => CafeReviewStats.fromReviews(reviews),
    loading: () => CafeReviewStats.empty,
    error: (_, _) => CafeReviewStats.empty,
  );
});

/// 리뷰 작성 Provider
final reviewSubmitProvider =
    NotifierProvider<ReviewSubmitNotifier, AsyncValue<void>>(
        ReviewSubmitNotifier.new);

class ReviewSubmitNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> submitReview({
    required String cafeId,
    required int rating,
    required CrowdLevel crowdLevel,
    required OutletLevel outletLevel,
    required NoiseLevel noiseLevel,
    required String content,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = AsyncValue.error('로그인이 필요합니다', StackTrace.current);
        return false;
      }

      final reviewData = ReviewModel(
        id: '',
        cafeId: cafeId,
        userId: user.uid,
        userName: user.displayName ?? '익명',
        rating: rating,
        crowdLevel: crowdLevel,
        outletLevel: outletLevel,
        noiseLevel: noiseLevel,
        content: content,
        createdAt: DateTime.now(),
      );

      // userId를 문서 ID로 사용하여 동일 사용자의 중복 리뷰 방지
      await FirebaseFirestore.instance
          .collection('cafes')
          .doc(cafeId)
          .collection('reviews')
          .doc(user.uid)
          .set(reviewData.toJson());

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('[Review] 리뷰 저장 실패: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
