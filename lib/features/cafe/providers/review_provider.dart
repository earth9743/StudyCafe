import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  debugPrint('[CafeReviews] Provider 시작 — cafeId: $cafeId');
  debugPrint('[CafeReviews] Firestore 쿼리: cafes/$cafeId/reviews (orderBy createdAt desc)');

  return FirebaseFirestore.instance
      .collection('cafes')
      .doc(cafeId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((Object error, StackTrace stackTrace) {
    debugPrint('[CafeReviews] Firestore 스트림 에러 발생 — cafeId: $cafeId');
    debugPrint('[CafeReviews] 에러: $error');
    debugPrint('[CafeReviews] 에러 타입: ${error.runtimeType}');
    debugPrint('[CafeReviews] 스택트레이스:\n$stackTrace');
  }).map((snapshot) {
    debugPrint('[CafeReviews] 스냅샷 수신 — cafeId: $cafeId, 문서 수: ${snapshot.docs.length}');

    final reviews = <ReviewModel>[];
    for (final doc in snapshot.docs) {
      try {
        final review = ReviewModel.fromJson(doc.id, doc.data());
        reviews.add(review);
      } catch (e, st) {
        debugPrint('[CafeReviews] 문서 파싱 실패: id=${doc.id}');
        debugPrint('[CafeReviews] 파싱 에러: $e');
        debugPrint('[CafeReviews] raw data: ${doc.data()}');
        debugPrint('[CafeReviews] 스택트레이스:\n$st');
      }
    }

    debugPrint('[CafeReviews] 파싱 완료 — 성공: ${reviews.length}/${snapshot.docs.length}');
    return reviews;
  });
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

  /// 선택된 이미지 파일들을 Firebase Storage에 업로드하고 다운로드 URL 목록을 반환한다.
  Future<List<String>> _uploadImages({
    required String cafeId,
    required String userId,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.isEmpty) return const [];

    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < imageFiles.length; i++) {
      final ref = storage
          .ref()
          .child('reviews/$cafeId/$userId/${timestamp}_$i.jpg');

      final uploadTask = await ref.putFile(
        imageFiles[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<bool> submitReview({
    required String cafeId,
    required int rating,
    required CrowdLevel crowdLevel,
    required OutletLevel outletLevel,
    required NoiseLevel noiseLevel,
    required String content,
    List<File> imageFiles = const [],
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('[ReviewSubmit] 리뷰 제출 시작 — cafeId: $cafeId');
      debugPrint('[ReviewSubmit] 현재 사용자: ${user?.uid ?? "null"}');

      if (user == null) {
        debugPrint('[ReviewSubmit] 에러: 로그인된 사용자 없음');
        state = AsyncValue.error('로그인이 필요합니다', StackTrace.current);
        return false;
      }

      // 이미지 업로드
      debugPrint('[ReviewSubmit] 이미지 업로드 시작 — 파일 수: ${imageFiles.length}');
      final photoUrls = await _uploadImages(
        cafeId: cafeId,
        userId: user.uid,
        imageFiles: imageFiles,
      );
      debugPrint('[ReviewSubmit] 이미지 업로드 완료 — URL 수: ${photoUrls.length}');

      // Firestore에서 닉네임 조회
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final nickname = userDoc.data()?['nickname'] as String?;
      final userName = (nickname != null && nickname.isNotEmpty)
          ? nickname
          : (user.displayName ?? '익명');

      final reviewData = ReviewModel(
        id: '',
        cafeId: cafeId,
        userId: user.uid,
        userName: userName,
        rating: rating,
        crowdLevel: crowdLevel,
        outletLevel: outletLevel,
        noiseLevel: noiseLevel,
        content: content,
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
      );

      // 자동 생성 ID로 리뷰를 누적 저장 (동일 사용자도 여러 리뷰 가능)
      debugPrint('[ReviewSubmit] Firestore 저장 시작 — cafes/$cafeId/reviews');
      final docRef = await FirebaseFirestore.instance
          .collection('cafes')
          .doc(cafeId)
          .collection('reviews')
          .add(reviewData.toJson());
      debugPrint('[ReviewSubmit] Firestore 저장 성공 — docId: ${docRef.id}');

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('[ReviewSubmit] 리뷰 저장 실패: $e');
      debugPrint('[ReviewSubmit] 에러 타입: ${e.runtimeType}');
      debugPrint('[ReviewSubmit] 스택트레이스:\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
