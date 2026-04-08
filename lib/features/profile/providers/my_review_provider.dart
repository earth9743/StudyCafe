import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kagong_map/features/auth/providers/auth_provider.dart';
import 'package:kagong_map/features/cafe/domain/models/review_model.dart';

/// 현재 로그인한 사용자가 작성한 모든 리뷰를 가져오는 Provider.
///
/// [authStateProvider]를 watch하여 로그인/로그아웃 시 자동으로 갱신된다.
///
/// 기존 코드는 `collectionGroup('reviews')` 쿼리에
/// `.where('userId')` + `.orderBy('createdAt')` 를 함께 사용했다.
/// 이 조합은 Firestore **복합 인덱스**를 수동으로 생성해야 하며,
/// 인덱스가 없으면 `failed-precondition` 에러가 발생한다.
/// iOS Firestore SDK가 이 에러를 던지면서 "리뷰를 불러오지 못했습니다"
/// 메시지가 표시되었다.
///
/// 수정: `orderBy` 를 제거하고 `where` 만 사용한 뒤 클라이언트에서 정렬한다.
/// 개인 리뷰는 수량이 적으므로 클라이언트 정렬의 성능 영향은 무시할 수 있다.
final myReviewsProvider = StreamProvider<List<ReviewModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  debugPrint('[MyReviews] Provider 시작 — authState: ${authState.runtimeType}');

  if (user == null) {
    debugPrint('[MyReviews] 로그인된 사용자 없음 — 빈 리스트 반환');
    return Stream.value([]);
  }

  final uid = user.uid;
  debugPrint('[MyReviews] 로그인된 userId: $uid');
  debugPrint('[MyReviews] Firestore collectionGroup("reviews") 쿼리 시작 — where userId == $uid');

  // collectionGroup에서 where만 사용 (복합 인덱스 불필요).
  // 정렬은 클라이언트에서 수행한다.
  return FirebaseFirestore.instance
      .collectionGroup('reviews')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .handleError((Object error, StackTrace stackTrace) {
    debugPrint('[MyReviews] Firestore 스트림 에러 발생');
    debugPrint('[MyReviews] 에러: $error');
    debugPrint('[MyReviews] 에러 타입: ${error.runtimeType}');
    debugPrint('[MyReviews] 스택트레이스:\n$stackTrace');
  }).map((snapshot) {
    debugPrint('[MyReviews] Firestore 스냅샷 수신 — 문서 수: ${snapshot.docs.length}');

    final reviews = <ReviewModel>[];
    for (final doc in snapshot.docs) {
      try {
        final review = ReviewModel.fromJson(doc.id, doc.data());
        reviews.add(review);
        debugPrint('[MyReviews]   문서 파싱 성공: id=${doc.id}, cafeId=${review.cafeId}');
      } catch (e, st) {
        debugPrint('[MyReviews]   문서 파싱 실패: id=${doc.id}');
        debugPrint('[MyReviews]   파싱 에러: $e');
        debugPrint('[MyReviews]   raw data: ${doc.data()}');
        debugPrint('[MyReviews]   스택트레이스:\n$st');
      }
    }

    // 최신순 정렬 (클라이언트 사이드)
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    debugPrint('[MyReviews] 최종 반환 리뷰 수: ${reviews.length}');
    return reviews;
  });
});
