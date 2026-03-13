# 카공지도 (Kagong Map) — 시스템 아키텍처

> **최종 업데이트:** 2026-03-13

---

## 1. 전체 아키텍처 개요

```
┌─────────────────────────────────────────────────────────────┐
│                     클라이언트 레이어                          │
│              Flutter App (Android / iOS / Web)               │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │  Map     │  │  Cafe    │  │  Crowd   │  │  Review    │  │
│  │  Feature │  │  Feature │  │  Feature │  │  Feature   │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
│       │              │              │               │         │
│  ┌────▼──────────────▼──────────────▼───────────────▼──────┐ │
│  │               Riverpod Provider Layer                    │ │
│  └────────────────────────┬─────────────────────────────────┘ │
│                           │                                  │
│  ┌────────────────────────▼─────────────────────────────────┐ │
│  │               Repository Layer (Abstract)                 │ │
│  └────────────────────────┬─────────────────────────────────┘ │
│                           │                                  │
│  ┌────────────────────────▼─────────────────────────────────┐ │
│  │             Data Source Layer (Implementation)            │ │
│  └────────────────────────┬─────────────────────────────────┘ │
└───────────────────────────┼─────────────────────────────────┘
                            │
                ┌───────────▼───────────┐
                │    Firebase Backend    │
                │                       │
                │  ┌─────────────────┐  │
                │  │   Firestore     │  │
                │  │  (주 데이터베이스) │  │
                │  └─────────────────┘  │
                │  ┌─────────────────┐  │
                │  │  Firebase Auth  │  │
                │  │  (인증)          │  │
                │  └─────────────────┘  │
                │  ┌─────────────────┐  │
                │  │ Firebase Storage│  │
                │  │ (이미지 파일)    │  │
                │  └─────────────────┘  │
                │  ┌─────────────────┐  │
                │  │ Cloud Functions │  │
                │  │ (서버 사이드 로직)│  │
                │  └─────────────────┘  │
                └───────────────────────┘
                            │
                ┌───────────▼───────────┐
                │   Naver Maps SDK       │
                │  (지도 및 위치 서비스)   │
                └───────────────────────┘
```

---

## 2. 레이어 아키텍처 (Clean Architecture 변형)

각 Feature 모듈은 아래 3개 레이어를 따릅니다.

```
presentation/       UI 위젯, Screen, 사용자 인터랙션
     ↓
providers/          Riverpod Provider (비즈니스 로직)
     ↓
domain/             Repository 인터페이스, 데이터 모델 (Freezed)
     ↓
data/               Repository 구현체, Remote/Local DataSource
```

**의존성 방향:** 항상 위에서 아래로 단방향. presentation은 data를 직접 참조하지 않는다.

---

## 3. Firestore 데이터 스키마

### 컬렉션 구조

```
users/
  └── {uid}/                          # 사용자 프로필
        ├── displayName: String
        ├── email: String
        ├── photoUrl: String?
        ├── createdAt: Timestamp
        └── reportCount: int          # 총 보고 횟수 (게이미피케이션)

cafes/
  └── {cafeId}/                       # 카페 기본 정보
        ├── name: String
        ├── address: String
        ├── latitude: double
        ├── longitude: double
        ├── phone: String?
        ├── openingHours: Map<String, String>  # 요일별 영업시간
        ├── photos: List<String>      # Firebase Storage URL
        ├── averageRating: double     # 자동 집계 (Cloud Functions)
        ├── reviewCount: int
        ├── wifiAvailable: bool
        ├── createdAt: Timestamp
        └── updatedAt: Timestamp

      crowd_logs/
        └── {logId}/                  # 혼잡도 보고
              ├── reporterUid: String
              ├── level: int          # 1=여유, 2=보통, 3=혼잡
              ├── reportedAt: Timestamp
              └── expiresAt: Timestamp  # reportedAt + 1시간

      outlet_reports/
        └── {reportId}/               # 콘센트 보고
              ├── reporterUid: String
              ├── status: String      # 'available', 'limited', 'none'
              ├── reportedAt: Timestamp
              └── expiresAt: Timestamp

      noise_reports/
        └── {reportId}/               # 소음 보고
              ├── reporterUid: String
              ├── level: String       # 'quiet', 'moderate', 'loud'
              ├── reportedAt: Timestamp
              └── expiresAt: Timestamp

      reviews/
        └── {reviewId}/               # 사용자 리뷰
              ├── authorUid: String
              ├── authorName: String
              ├── authorPhotoUrl: String?
              ├── rating: int         # 1~5
              ├── text: String
              ├── photos: List<String>
              ├── tags: List<String>  # 'wifi', 'outlet', 'quiet', 'seat'
              ├── createdAt: Timestamp
              └── updatedAt: Timestamp
```

### 주요 쿼리 패턴

```
# 현재 위치 반경 내 카페 조회 (GeoQuery)
cafes
  where latitude between [min, max]
  where longitude between [min, max]
  order by latitude

# 특정 카페의 최근 1시간 혼잡도 보고 조회
cafes/{cafeId}/crowd_logs
  where expiresAt >= now()
  order by reportedAt desc

# 카페 리뷰 최신순 조회
cafes/{cafeId}/reviews
  order by createdAt desc
  limit 20
```

---

## 4. 상태 관리 패턴 (Riverpod)

```dart
// 패턴 예시: cafeDetailProvider
// 위치: lib/features/cafe/providers/cafe_detail_provider.dart

@riverpod
Stream<CafeModel?> cafeDetail(CafeDetailRef ref, String cafeId) {
  final repository = ref.watch(cafeRepositoryProvider);
  return repository.watchCafe(cafeId);
}

@riverpod
class CrowdReporter extends _$CrowdReporter {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> report(String cafeId, CrowdLevel level) async {
    state = const AsyncLoading();
    final repository = ref.read(crowdRepositoryProvider);
    state = await AsyncValue.guard(
      () => repository.report(cafeId: cafeId, level: level),
    );
  }
}
```

**규칙:**
- `StreamProvider` — Firestore 실시간 데이터
- `FutureProvider` — 단발성 비동기 데이터
- `NotifierProvider` / `AsyncNotifierProvider` — 사용자 액션 + 상태 변경

---

## 5. 보안 규칙 (Firestore Security Rules 초안)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 인증된 사용자만 접근 가능
    function isAuthenticated() {
      return request.auth != null;
    }

    // 본인 문서 여부 확인
    function isOwner(uid) {
      return request.auth.uid == uid;
    }

    // 사용자 프로필
    match /users/{uid} {
      allow read: if isAuthenticated();
      allow write: if isOwner(uid);
    }

    // 카페 정보 — 모든 인증 사용자 읽기, 쓰기는 Admin만
    match /cafes/{cafeId} {
      allow read: if isAuthenticated();
      allow write: if false;  // Cloud Functions 또는 Admin SDK로만 수정

      // 혼잡도, 콘센트, 소음 보고 — 인증 사용자 읽기/쓰기
      match /crowd_logs/{logId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated()
                      && request.resource.data.reporterUid == request.auth.uid;
        allow update, delete: if false;
      }

      match /outlet_reports/{reportId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated()
                      && request.resource.data.reporterUid == request.auth.uid;
        allow update, delete: if false;
      }

      match /noise_reports/{reportId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated()
                      && request.resource.data.reporterUid == request.auth.uid;
        allow update, delete: if false;
      }

      // 리뷰 — 본인 리뷰만 수정/삭제 가능
      match /reviews/{reviewId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated()
                      && request.resource.data.authorUid == request.auth.uid;
        allow update, delete: if isOwner(resource.data.authorUid);
      }
    }
  }
}
```

---

## 6. 환경 변수 관리

Naver Maps Client ID 및 민감 정보는 소스 코드에 절대 포함하지 않는다.

```
# Android: android/local.properties (gitignore 대상)
naver_client_id=YOUR_NAVER_CLIENT_ID

# android/app/build.gradle 에서 주입
android {
  defaultConfig {
    manifestPlaceholders = [
      naverClientId: localProperties.getProperty('naver_client_id', '')
    ]
  }
}

# AndroidManifest.xml 에서 참조
<meta-data
  android:name="com.naver.maps.map.CLIENT_ID"
  android:value="${naverClientId}" />

# iOS: 빌드 스크립트를 통해 Info.plist에 주입
# Flutter 빌드 타임: --dart-define-from-file=.env.json
```

---

## 7. 비기능 요구사항 목표

| 항목 | 목표 |
|------|------|
| 앱 초기 로딩 시간 | 콜드 스타트 3초 이하 |
| 지도 마커 렌더링 | 100개 마커 기준 16ms 이하 |
| Firestore 읽기 비용 | 일 10,000 reads 이하 (오프라인 캐싱 활용) |
| 오프라인 지원 | 마지막 조회 데이터 오프라인 표시 |
| 보안 | Naver Client ID 및 Firebase 설정 파일 소스 미포함 |
| 충돌률 목표 | Firebase Crashlytics 기준 0.1% 이하 |
