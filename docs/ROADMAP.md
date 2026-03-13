# 카공지도 (Kagong Map) — 개발 로드맵

> **최종 업데이트:** 2026-03-14
> **현재 상태:** 스캐폴딩 완료 단계 — Firebase, Naver Maps, Kakao, Google Sign-In 의존성 설치 및 네이티브 설정 완료
> **대상 플랫폼:** Android, iOS (Web은 MVP 이후 별도 검토)
> **기술 스택:** Flutter · Firebase (Firestore, Auth, Storage) · Naver Maps SDK · Riverpod + 코드 생성 · Freezed

---

## 현재 완료된 항목 (스캐폴딩)

다음 항목들은 이미 완료되어 있으며 Phase 1 작업 범위에서 제외됩니다.

| 완료 항목 | 세부 내용 |
|-----------|-----------|
| Flutter 프로젝트 생성 | 패키지명 `com.yjh.kagong.kagong_map` |
| Firebase 구성 | `firebase_options.dart` 생성 완료, Auth/Firestore/Storage 활성화 |
| Naver Maps SDK | Android/iOS 네이티브 Client ID 설정 완료 |
| Kakao Login SDK | `kakao_flutter_sdk_user` 설치, Android/iOS Native Key 설정 완료 |
| Google Sign-In | `google_sign_in` 패키지 설치 완료 |
| 핵심 의존성 | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `flutter_naver_map` 설치 완료 |
| Email/Password Auth | Firebase Console에서 활성화 완료 |

---

## 우선순위 레이블 기준표

| 레이블 | 의미 |
|--------|------|
| **P0 — Critical** | MVP 출시 블로커. 반드시 먼저 완료되어야 함 |
| **P1 — High** | 핵심 사용자 경험에 필수적. P0 완료 후 즉시 착수 |
| **P2 — Medium** | 품질 향상 기능. 핵심 흐름 완성 후 진행 |
| **P3 — Low** | 포스트 런치 백로그. 향후 로드맵 고려 항목 |

---

## 전체 페이즈 개요

```
Phase 1 — 아키텍처 확립 & 인증     [3~4주]   의존성: 없음 (스캐폴딩 완료 상태에서 시작)
Phase 2 — 핵심 UI & 지도 통합      [4~5주]   의존성: Phase 1
Phase 3 — 실시간 데이터 기능        [3~4주]   의존성: Phase 2
Phase 4 — 리뷰 & 소셜 기능         [3~4주]   의존성: Phase 3
Phase 5 — 출시 준비 & 품질 관리    [2~3주]   의존성: Phase 4
```

**전체 예상 기간: 15~20주 (3.5~5개월)**

---

## Phase 1: 아키텍처 확립 및 인증 (Foundation & Auth)

**목표:** 피처 기반 Clean Architecture, 코드 생성 파이프라인, 디자인 시스템 토큰, 그리고 완전한 인증 흐름을 구축한다.
**의존성:** 없음 (스캐폴딩 완료 상태에서 시작)
**복잡도:** 높음 (High)
**예상 소요:** 3~4주

---

### 1-1. 추가 의존성 설치

> 현재 `pubspec.yaml`에 없는 패키지를 추가한다. 이미 설치된 패키지는 버전 확인만 진행한다.

- [ ] **[P0]** `pubspec.yaml`에 아래 패키지 추가 후 `flutter pub get` 실행

  ```
  # 상태 관리 (코드 생성 방식)
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x

  # 코드 생성 (dev_dependencies)
  build_runner: ^2.x
  riverpod_generator: ^2.x
  freezed: ^2.x
  freezed_annotation: ^2.x
  json_serializable: ^6.x

  # 라우팅
  go_router: ^14.x

  # 위치
  geolocator: ^13.x
  permission_handler: ^11.x

  # 이미지
  cached_network_image: ^3.x
  image_picker: ^1.x

  # 유틸
  intl: ^0.19.x
  logger: ^2.x
  equatable: ^2.x

  # 차트 (혼잡도 히스토리)
  fl_chart: ^0.69.x

  # 앱 아이콘 & 스플래시 (dev)
  flutter_launcher_icons: ^0.14.x
  flutter_native_splash: ^2.x
  ```

- [ ] **[P0]** `flutter analyze` 실행 — 기존 오류 없음 확인

---

### 1-2. 프로젝트 아키텍처 및 폴더 구조 생성

- [ ] **[P0]** 아래 권장 폴더 구조에 따라 디렉토리 및 빈 파일 생성 (상세 구조는 하단 아키텍처 섹션 참고)
- [ ] **[P0]** `lib/core/theme/app_colors.dart` — Sophisticated Navy 팔레트 색상 상수 정의
  - Primary (Navy): `#19376D`
  - Secondary (Gray): `#EDEDED`
  - Background: `#FFFFFF`
  - Text: `#1A202C`
- [ ] **[P0]** `lib/core/theme/app_text_styles.dart` — 타이포그래피 스케일 정의
- [ ] **[P0]** `lib/core/theme/app_theme.dart` — `ThemeData` 구성 (Material 3 기반)
- [ ] **[P0]** `lib/core/router/app_router.dart` — `go_router` 기반 라우팅 정의
  - 인증 상태에 따른 리다이렉트 guard 포함
- [ ] **[P0]** `lib/core/constants/app_constants.dart` — 앱 전역 상수
- [ ] **[P0]** `lib/core/constants/firestore_paths.dart` — Firestore 경로 상수 (`cafes`, `users`, `crowd_logs` 등)
- [ ] **[P0]** `lib/core/errors/app_exception.dart` — 커스텀 예외 클래스
- [ ] **[P0]** `lib/core/errors/failure.dart` — `sealed class Failure` 정의
- [ ] **[P1]** `lib/core/utils/logger.dart` — 전역 `logger` 인스턴스 설정
- [ ] **[P1]** `lib/main.dart` 리팩토링 — `ProviderScope`, `FirebaseApp`, `go_router` 연결

---

### 1-3. 보안 및 네이티브 환경 설정 검증

> 스캐폴딩 단계에서 설정된 항목들을 검증하고 누락 항목을 보완한다.

- [ ] **[P0]** Android `local.properties` — `naver_client_id` 키 존재 여부 확인 (절대 하드코딩 금지)
- [ ] **[P0]** Android `android/app/build.gradle.kts` 검증
  - `minSdk 23` 이상 확인
  - `multiDexEnabled = true` 활성화 확인
  - `manifestPlaceholders["NAVER_CLIENT_ID"]` 주입 확인
- [ ] **[P0]** iOS `Podfile` — 배포 타겟 `platform :ios, '13.0'` 이상 확인
- [ ] **[P0]** iOS `Info.plist` — 위치 권한 설명 문자열 추가 확인
  - `NSLocationWhenInUseUsageDescription`: "카공지도가 주변 카페를 찾기 위해 위치 정보를 사용합니다."
  - `NSLocationAlwaysAndWhenInUseUsageDescription`: "카공지도가 주변 카페를 찾기 위해 위치 정보를 사용합니다."
- [ ] **[P0]** `.gitignore` 검증 — `local.properties`, `google-services.json`, `GoogleService-Info.plist` 추가 확인
- [ ] **[P1]** `android/app/proguard-rules.pro` — Naver Maps SDK & Firebase 난독화 예외 규칙 추가

---

### 1-4. Firestore 데이터베이스 스키마 확정

> 아래 스키마를 기준으로 Firestore 보안 규칙 및 Freezed 모델을 생성한다.

#### 컬렉션 구조

```
firestore/
├── users/
│   └── {uid}/                          # 사용자 프로필
│       ├── uid: string
│       ├── email: string
│       ├── displayName: string
│       ├── photoUrl: string | null
│       ├── provider: "email" | "google" | "kakao"
│       ├── createdAt: Timestamp
│       ├── updatedAt: Timestamp
│       └── bookmarkedCafeIds: string[]
│
├── cafes/
│   └── {cafeId}/                       # 카페 기본 정보
│       ├── cafeId: string
│       ├── name: string
│       ├── address: string
│       ├── phone: string | null
│       ├── lat: number                 # 위도
│       ├── lng: number                 # 경도
│       ├── businessHours: map          # { mon: "09:00-22:00", ... }
│       ├── photoUrls: string[]
│       ├── currentCrowdLevel: "low" | "moderate" | "high" | "unknown"
│       ├── currentOutletStatus: "available" | "limited" | "unavailable" | "unknown"
│       ├── currentNoiseLevel: "quiet" | "moderate" | "loud" | "unknown"
│       ├── averageRating: number       # 0.0 ~ 5.0
│       ├── reviewCount: number
│       ├── isVerified: boolean
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
│   └── {cafeId}/crowd_logs/
│       └── {logId}/                    # 혼잡도 보고
│           ├── logId: string
│           ├── cafeId: string
│           ├── uid: string
│           ├── level: "low" | "moderate" | "high"
│           └── reportedAt: Timestamp
│
│   └── {cafeId}/outlet_reports/
│       └── {reportId}/                 # 콘센트 가용성 보고
│           ├── reportId: string
│           ├── cafeId: string
│           ├── uid: string
│           ├── status: "available" | "limited" | "unavailable"
│           └── reportedAt: Timestamp
│
│   └── {cafeId}/noise_reports/
│       └── {reportId}/                 # 소음 수준 보고
│           ├── reportId: string
│           ├── cafeId: string
│           ├── uid: string
│           ├── level: "quiet" | "moderate" | "loud"
│           └── reportedAt: Timestamp
│
│   └── {cafeId}/reviews/
│       └── {reviewId}/                 # 사용자 리뷰
│           ├── reviewId: string
│           ├── cafeId: string
│           ├── uid: string
│           ├── authorName: string
│           ├── authorPhotoUrl: string | null
│           ├── rating: number          # 1 ~ 5
│           ├── content: string         # 최대 500자
│           ├── tags: string[]          # ["wifi", "outlet", "quiet", "seat"]
│           ├── photoUrls: string[]     # 최대 3장
│           ├── createdAt: Timestamp
│           └── updatedAt: Timestamp
│
└── cafe_requests/
    └── {requestId}/                    # 카페 등록 신청
        ├── requestId: string
        ├── uid: string
        ├── cafeName: string
        ├── address: string
        ├── status: "pending" | "approved" | "rejected"
        └── createdAt: Timestamp
```

#### Firestore 보안 규칙 정책

| 컬렉션 | 읽기 | 쓰기 | 수정 | 삭제 |
|--------|------|------|------|------|
| `users/{uid}` | 인증된 사용자 | 본인만 | 본인만 | 불가 |
| `cafes` | 모든 인증 사용자 | 관리자만 | 관리자만 | 불가 |
| `cafes/{id}/crowd_logs` | 모든 인증 사용자 | 인증된 사용자 | 불가 | 불가 |
| `cafes/{id}/outlet_reports` | 모든 인증 사용자 | 인증된 사용자 | 불가 | 불가 |
| `cafes/{id}/noise_reports` | 모든 인증 사용자 | 인증된 사용자 | 불가 | 불가 |
| `cafes/{id}/reviews` | 모든 인증 사용자 | 인증된 사용자 | 본인만 | 본인만 |
| `cafe_requests` | 관리자만 | 인증된 사용자 | 불가 | 불가 |

- [ ] **[P0]** 위 스키마에 따라 Firestore 보안 규칙 (`firestore.rules`) 초안 작성
- [ ] **[P0]** Firebase Console에서 보안 규칙 배포 및 검증
- [ ] **[P1]** Firebase Emulator Suite 로컬 개발 환경 설정 (`firebase emulators:start`)

---

### 1-5. 핵심 데이터 모델 (Freezed)

- [ ] **[P0]** `UserModel` — `lib/features/auth/domain/models/user_model.dart`
- [ ] **[P0]** `CafeModel` — `lib/features/cafe/domain/models/cafe_model.dart`
- [ ] **[P0]** `CrowdLogModel` — `lib/features/crowd/domain/models/crowd_log_model.dart`
- [ ] **[P0]** `OutletReportModel` — `lib/features/outlet/domain/models/outlet_report_model.dart`
- [ ] **[P0]** `NoiseReportModel` — `lib/features/noise/domain/models/noise_report_model.dart`
- [ ] **[P0]** `ReviewModel` — `lib/features/review/domain/models/review_model.dart`
- [ ] **[P0]** `build_runner` 실행하여 `*.freezed.dart`, `*.g.dart` 코드 생성 확인

---

### 1-6. 인증 (Authentication)

- [ ] **[P0]** `AuthRepository` 인터페이스 및 `AuthRepositoryImpl` 구현체 작성
  - `signInWithEmailAndPassword()`
  - `createUserWithEmailAndPassword()`
  - `signInWithGoogle()`
  - `signInWithKakao()`
  - `signOut()`
  - `sendPasswordResetEmail()`
  - `authStateChanges()` — `Stream<UserModel?>`
- [ ] **[P0]** `authProvider` (Riverpod `StreamProvider`) — Firebase Auth 상태 스트림
- [ ] **[P0]** `authControllerProvider` (Riverpod `AsyncNotifierProvider`) — 인증 액션 처리
- [ ] **[P0]** 로그인 화면 UI (`LoginScreen`)
  - 이메일 / 비밀번호 입력 폼
  - 유효성 검사 (이메일 형식, 비밀번호 8자 이상)
  - Google 로그인 버튼
  - 카카오 로그인 버튼
  - 회원가입 화면 이동 링크
- [ ] **[P0]** 회원가입 화면 UI (`SignUpScreen`)
  - 이메일 / 비밀번호 / 비밀번호 확인 / 닉네임 입력
  - 가입 시 Firestore `users/{uid}` 문서 자동 생성
- [ ] **[P0]** 비밀번호 재설정 화면 (`ForgotPasswordScreen`)
- [ ] **[P0]** Router Guard — 미인증 사용자 `/login`으로 리다이렉트
- [ ] **[P1]** Google 로그인 E2E 흐름 완성 (Android & iOS 양쪽 테스트)
- [ ] **[P1]** 카카오 로그인 E2E 흐름 완성 (Android & iOS 양쪽 테스트)
- [ ] **[P2]** 소셜 로그인 계정과 이메일 계정 연동 처리

---

### Phase 1 마일스톤 체크리스트

- [ ] `flutter pub get` 및 `flutter analyze` 경고 0건
- [ ] `build_runner` 코드 생성 오류 없음
- [ ] Android 에뮬레이터에서 이메일 회원가입 → 로그인 → 로그아웃 E2E 동작
- [ ] iOS 시뮬레이터에서 이메일 회원가입 → 로그인 → 로그아웃 E2E 동작
- [ ] Google 로그인 Android/iOS 양쪽 동작
- [ ] 카카오 로그인 Android/iOS 양쪽 동작
- [ ] Naver Client ID가 어떠한 소스 파일에도 하드코딩되어 있지 않음
- [ ] Firestore `users/{uid}` 문서 생성 확인 (회원가입 시)

---

## Phase 2: 핵심 UI 및 지도 통합 (Core UI & Map Integration)

**목표:** 네이버 지도와 카페 목록/상세 화면을 통합하여 카페 탐색의 기본 흐름을 완성한다.
**의존성:** Phase 1 완료
**복잡도:** 높음 (High)
**예상 소요:** 4~5주

---

### 2-1. 공통 UI 컴포넌트 (Design System)

- [ ] **[P0]** `PrimaryButton` — Navy 배경, 흰색 텍스트, 로딩 상태 포함
- [ ] **[P0]** `SecondaryButton` — 아웃라인 스타일, Navy 테두리
- [ ] **[P0]** `KagongAppBar` — Navy 배경, 흰색 타이틀/아이콘
- [ ] **[P0]** `CafeCard` — 카페 목록 카드 (카페명, 거리, 혼잡도 배지)
- [ ] **[P0]** `CrowdBadge` — 혼잡도 상태 배지 (`여유` / `보통` / `혼잡` 색상 구분)
- [ ] **[P1]** `OutletStatusBadge` — 콘센트 상태 배지
- [ ] **[P1]** `NoiseBadge` — 소음 수준 배지
- [ ] **[P1]** `LoadingIndicator` — 전역 로딩 인디케이터 (Navy 색상)
- [ ] **[P1]** `ErrorView` — 에러 상태 위젯 (재시도 버튼 포함)
- [ ] **[P1]** `EmptyStateView` — 빈 상태 위젯
- [ ] **[P2]** 커스텀 Naver Maps 마커 위젯 — 혼잡도별 Navy 계열 색상 마커

---

### 2-2. 하단 내비게이션 및 라우팅

- [ ] **[P0]** `BottomNavBar` — 3탭 (지도 / 목록 / 내 정보)
- [ ] **[P0]** `HomeScreen` — `go_router`의 Shell Route로 하단 내비게이션 관리
- [ ] **[P0]** `app_router.dart` 전체 라우트 정의
  - `/` → `HomeScreen` (지도 탭 기본)
  - `/list` → `CafeListScreen`
  - `/cafe/:cafeId` → `CafeDetailScreen`
  - `/profile` → `ProfileScreen`
  - `/login`, `/signup`, `/forgot-password` → Auth 화면들
  - `/cafe/:cafeId/review/write` → `WriteReviewScreen`

---

### 2-3. 네이버 지도 통합

- [ ] **[P0]** `flutter_naver_map` 초기화 (`NaverMapSdk.instance.initialize()`)
- [ ] **[P0]** `MapScreen` — 메인 지도 화면
  - 현재 위치 중심으로 지도 초기 표시
  - 위치 권한 요청 흐름 (`permission_handler`)
- [ ] **[P0]** `mapProvider` — `geolocator` 기반 현재 위치 관리 (Riverpod `FutureProvider`)
- [ ] **[P0]** `nearbyCafesProvider` — 현재 지도 영역 내 카페 목록 Firestore 조회
- [ ] **[P0]** 카페 위치 마커 표시 — `NMarker` 기반, 혼잡도에 따른 색상 구분
- [ ] **[P0]** 마커 탭 시 바텀 시트(`CafeBottomSheet`) 표시 — 카페 요약 정보
- [ ] **[P1]** 현재 위치 버튼 — 탭 시 현재 위치로 카메라 이동
- [ ] **[P1]** 지도 카메라 이동 완료 시 (`onCameraIdle`) 해당 영역 카페 자동 갱신
- [ ] **[P2]** 줌 레벨에 따른 마커 클러스터링
- [ ] **[P2]** 반경 필터 UI (500m / 1km / 2km)

---

### 2-4. 카페 목록 화면

- [ ] **[P0]** `CafeListScreen` — 현재 위치 기준 거리순 카페 목록
- [ ] **[P0]** `CafeRepository` 인터페이스 및 `CafeRepositoryImpl` 구현체
  - `getCafesByBounds()` — 지도 영역 기준 조회
  - `getCafeById()` — 단일 카페 실시간 스트림
  - `getNearestCafes()` — 현재 위치 기준 거리순 조회
- [ ] **[P0]** `cafeListProvider` — 카페 목록 (Riverpod `AsyncNotifierProvider`, 페이지네이션 지원)
- [ ] **[P1]** 필터 바 — 혼잡도 / 콘센트 유무 / 영업 중 필터 칩
- [ ] **[P1]** 정렬 옵션 — 거리순 / 혼잡도순 / 평점순 드롭다운
- [ ] **[P2]** 무한 스크롤 페이지네이션 (`Firestore startAfterDocument`)
- [ ] **[P2]** Pull-to-Refresh

---

### 2-5. 카페 상세 화면

- [ ] **[P0]** `CafeDetailScreen` — 카페 전체 정보 표시
  - 카페 사진 (PageView 갤러리)
  - 카페명, 주소, 전화번호, 영업시간
  - 실시간 혼잡도 배지 (Firestore `snapshots()` 스트림)
  - 콘센트 가용 현황 배지
  - 소음 수준 배지
  - 평균 별점 및 리뷰 수
  - 혼잡도 / 콘센트 / 소음 보고 버튼
- [ ] **[P0]** `cafeDetailProvider` — 특정 카페 실시간 스트림 (`StreamProvider`)
- [ ] **[P1]** 길찾기 버튼 — 네이버 지도 앱 딥링크 (`nmap://`) 연동
- [ ] **[P1]** 사진 전체보기 화면
- [ ] **[P2]** 즐겨찾기 버튼 — `users/{uid}.bookmarkedCafeIds` 배열 업데이트
- [ ] **[P2]** 공유 버튼 — `Share` 패키지로 카페 정보 공유

---

### Phase 2 마일스톤 체크리스트

- [ ] 앱 시작 시 현재 위치 중심 지도 표시 (Android & iOS)
- [ ] 지도에서 주변 카페 마커 표시 (Firestore 데이터 기반)
- [ ] 마커 탭 → 바텀 시트 → 상세 화면 이동 전체 흐름 동작
- [ ] 카페 목록 화면 거리순 정렬 데이터 표시
- [ ] 카페 상세 화면 실시간 혼잡도 배지 표시
- [ ] 위치 권한 거부 시 안내 메시지 표시

---

## Phase 3: 실시간 데이터 기능 (Real-time Data Features)

**목표:** 혼잡도, 콘센트 가용성, 소음 수준 — 카공지도의 3대 핵심 차별화 기능을 완성한다.
**의존성:** Phase 2 완료
**복잡도:** 높음 (High)
**예상 소요:** 3~4주

---

### 3-1. 혼잡도 보고 시스템

- [ ] **[P0]** `CrowdReportSheet` — 바텀 시트 UI (여유 / 보통 / 혼잡 선택)
- [ ] **[P0]** `CrowdLogRepository` 인터페이스 및 구현체
  - `reportCrowdLevel(cafeId, level)` — Firestore `crowd_logs`에 저장
  - `getRecentLogs(cafeId, withinMinutes: 60)` — 최근 1시간 보고 조회
- [ ] **[P0]** `crowdLevelProvider` — 최근 1시간 보고 기반 혼잡도 계산 로직
  - 알고리즘: 최신 보고에 더 높은 가중치 부여 (시간 감쇠 가중 평균)
  - 예) `low=1, moderate=2, high=3` → 가중 평균 → 임계값으로 최종 상태 결정
- [ ] **[P0]** `crowdReportControllerProvider` — 보고 액션 처리 (`AsyncNotifierProvider`)
- [ ] **[P0]** 중복 보고 방지 — 동일 사용자 30분 내 재보고 거부 (Firestore 쿼리 기반)
- [ ] **[P0]** 보고 후 카페 문서 `currentCrowdLevel` 필드 업데이트
  - 클라이언트 사이드 업데이트 (Cloud Functions 미적용 시) 또는 Cloud Function Trigger
- [ ] **[P1]** 혼잡도 히스토리 차트 — 시간대별 평균 혼잡도 (`fl_chart` 라인 차트)
- [ ] **[P1]** 보고 신뢰도 표시 — "최근 N분 전 N명이 보고함"
- [ ] **[P2]** 혼잡도 예측 — 요일/시간대별 과거 통계 기반 예상 혼잡도 표시

---

### 3-2. 콘센트 가용성 보고

- [ ] **[P0]** `OutletReportSheet` — 바텀 시트 UI (있음 / 일부 / 없음 선택)
- [ ] **[P0]** `OutletReportRepository` 인터페이스 및 구현체
  - `reportOutletStatus(cafeId, status)` — Firestore `outlet_reports`에 저장
  - `getRecentReports(cafeId, withinMinutes: 60)` — 최근 1시간 보고 조회
- [ ] **[P0]** `outletStatusProvider` — 최근 보고 기반 현재 상태 계산 (다수결 방식)
- [ ] **[P0]** 보고 후 카페 문서 `currentOutletStatus` 필드 업데이트
- [ ] **[P0]** 중복 보고 방지 — 동일 사용자 30분 내 재보고 거부
- [ ] **[P1]** 보고 신뢰도 표시

---

### 3-3. 소음 수준 보고

- [ ] **[P0]** `NoiseReportSheet` — 바텀 시트 UI (조용함 / 보통 / 시끄러움 선택)
- [ ] **[P0]** `NoiseReportRepository` 인터페이스 및 구현체
  - `reportNoiseLevel(cafeId, level)` — Firestore `noise_reports`에 저장
  - `getRecentReports(cafeId, withinMinutes: 60)` — 최근 1시간 보고 조회
- [ ] **[P0]** `noiseLevelProvider` — 최근 보고 기반 현재 소음 수준 계산 (다수결 방식)
- [ ] **[P0]** 보고 후 카페 문서 `currentNoiseLevel` 필드 업데이트
- [ ] **[P0]** 중복 보고 방지 — 동일 사용자 30분 내 재보고 거부
- [ ] **[P2]** 마이크 기반 실제 dB 측정 후 자동 제안 (선택 옵션)

---

### 3-4. 실시간 업데이트

- [ ] **[P0]** 카페 상세 화면 — Firestore `snapshots()` 기반 혼잡도/콘센트/소음 실시간 반영
- [ ] **[P1]** 지도 마커 색상 — 혼잡도 변경 시 실시간 업데이트
- [ ] **[P1]** 카페 목록 카드 — 혼잡도 배지 실시간 업데이트
- [ ] **[P2]** Firestore 오프라인 캐싱 활성화 (`FirebaseFirestore.instance.settings` 설정)

---

### 3-5. 보고 포인트 / 동기 부여 (선택)

- [ ] **[P2]** 사용자 보고 횟수 집계 (`users/{uid}.reportCount` 필드)
- [ ] **[P2]** 보고 감사 메시지 — 보고 완료 후 스낵바 표시 ("커뮤니티에 기여해 주셨습니다!")

---

### Phase 3 마일스톤 체크리스트

- [ ] 혼잡도 보고 → 카페 상세 화면 즉시 반영 (5초 이내)
- [ ] 콘센트 / 소음 보고 정상 저장 및 상태 업데이트 확인
- [ ] 동일 사용자 30분 내 재보고 거부 로직 동작 확인
- [ ] 여러 사용자 동시 보고 시 집계 정확도 확인 (테스트 계정 2개 사용)
- [ ] 지도 마커 색상 실시간 변경 확인

---

## Phase 4: 리뷰 및 소셜 기능 (Reviews & Social)

**목표:** 사용자 생성 콘텐츠(리뷰, 사진, 평점)로 커뮤니티 신뢰도를 구축하고, 마이 페이지를 완성한다.
**의존성:** Phase 3 완료
**복잡도:** 중간 (Medium)
**예상 소요:** 3~4주

---

### 4-1. 리뷰 작성 및 조회

- [ ] **[P0]** `WriteReviewScreen` — 리뷰 작성 화면
  - 별점 (1~5점, 별 아이콘 탭)
  - 텍스트 리뷰 입력 (최대 500자, 글자 수 카운터)
  - 카테고리 태그 선택 (`와이파이`, `콘센트`, `좌석`, `조용함`)
- [ ] **[P0]** `ReviewRepository` 인터페이스 및 구현체
  - `addReview(cafeId, reviewData)` — 리뷰 저장
  - `getReviews(cafeId)` — 카페별 리뷰 목록 (`Query` 기반 페이지네이션)
  - `updateReview(reviewId, data)` — 리뷰 수정
  - `deleteReview(cafeId, reviewId)` — 리뷰 삭제
- [ ] **[P0]** `reviewListProvider` — 카페별 리뷰 목록 (`AsyncNotifierProvider`)
- [ ] **[P0]** 리뷰 목록 UI — 카페 상세 화면 내 섹션 (작성자, 별점, 태그, 내용)
- [ ] **[P0]** `reviewControllerProvider` — 리뷰 작성/수정/삭제 액션
- [ ] **[P1]** 사진 첨부 — `image_picker`로 최대 3장 선택, Firebase Storage 업로드
  - 이미지 압축 후 업로드 (Firebase Storage `ref.putFile()`)
  - iOS `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` 추가
- [ ] **[P1]** 평점 집계 — 리뷰 저장 시 `cafes/{cafeId}` 문서의 `averageRating`, `reviewCount` 자동 업데이트
  - 구현 방식: Cloud Functions Firestore Trigger (권장) 또는 클라이언트 트랜잭션
- [ ] **[P2]** 리뷰 수정 / 삭제 (본인 리뷰에 한해)
- [ ] **[P2]** 리뷰 신고 기능 (`reports` 서브컬렉션)

---

### 4-2. 마이 페이지

- [ ] **[P0]** `ProfileScreen` — 내 정보 화면
  - 닉네임, 프로필 사진 표시
  - 내가 작성한 리뷰 목록 (최근 5개, "더 보기" 링크)
  - 내 보고 횟수 통계
  - 로그아웃 버튼
- [ ] **[P0]** `profileProvider` — 현재 사용자 프로필 스트림
- [ ] **[P1]** 프로필 편집 화면 — 닉네임 변경, 프로필 사진 변경 (Firebase Storage)
- [ ] **[P1]** 회원 탈퇴 — Firebase Auth 계정 삭제 + Firestore 사용자 데이터 삭제
- [ ] **[P2]** 즐겨찾기 카페 목록 화면 (`bookmarkedCafeIds` 기반)
- [ ] **[P2]** 내 보고 이력 목록 (혼잡도 / 콘센트 / 소음 보고 합산)

---

### 4-3. 카페 등록 요청

- [ ] **[P1]** 카페 등록 요청 화면 — 카페명, 주소, 전화번호 입력 양식
- [ ] **[P1]** `cafe_requests` 컬렉션에 `status: "pending"` 상태로 저장
- [ ] **[P2]** 관리자 검토 후 승인/거절 처리 플로우 (Firebase Console 또는 Admin 전용 화면)

---

### Phase 4 마일스톤 체크리스트

- [ ] 리뷰 작성 → 카페 상세 목록 즉시 반영 확인
- [ ] 사진 첨부 업로드 및 표시 확인 (Android & iOS)
- [ ] 평균 평점 자동 계산 확인
- [ ] 마이 페이지에서 본인 리뷰 목록 표시 확인
- [ ] 본인 리뷰만 수정/삭제 가능 확인 (보안 규칙 포함)

---

## Phase 5: 출시 준비 및 품질 관리 (Launch Readiness)

**목표:** Google Play Store와 Apple App Store 제출이 가능한 수준의 안정성, 성능, UX를 확보한다.
**의존성:** Phase 4 완료
**복잡도:** 중간 (Medium)
**예상 소요:** 2~3주

---

### 5-1. 성능 최적화

- [ ] **[P1]** `cached_network_image` — Firebase Storage 이미지 캐싱 적용
- [ ] **[P1]** Firestore 쿼리 복합 인덱스 최적화 (Firebase Console에서 인덱스 생성)
- [ ] **[P1]** Flutter DevTools Profile 모드로 렌더링 성능 분석, 불필요한 `rebuild` 최소화
- [ ] **[P1]** Riverpod `select()` 활용 — 불필요한 위젯 리빌드 방지
- [ ] **[P2]** 앱 초기 로딩 시간 측정 및 Firebase 초기화 최적화

---

### 5-2. 에러 처리 및 모니터링

- [ ] **[P1]** Firebase Crashlytics 통합 (`firebase_crashlytics` 패키지)
  - `FlutterError.onError` 및 `PlatformDispatcher.instance.onError` 핸들러 등록
- [ ] **[P1]** 네트워크 오류 / Firebase 연결 실패 시 사용자 친화적 메시지 표시
- [ ] **[P1]** 전역 `ProviderObserver` — Riverpod 에러 로깅
- [ ] **[P2]** Firebase Analytics 이벤트 정의
  - `cafe_viewed`, `report_submitted`, `review_written`, `search_performed`

---

### 5-3. 테스트

- [ ] **[P0]** 핵심 Repository 유닛 테스트 작성 (Firebase Emulator 사용)
  - `AuthRepository`, `CafeRepository`, `CrowdLogRepository`
- [ ] **[P1]** Riverpod Provider 유닛 테스트 작성
  - `crowdLevelProvider` 가중 평균 알고리즘 테스트
  - `authProvider` 상태 전환 테스트
- [ ] **[P1]** 주요 화면 Widget 테스트
  - `LoginScreen` 유효성 검사 테스트
  - `CafeCard` 렌더링 테스트
- [ ] **[P2]** 통합 테스트 — 로그인 → 지도 화면 → 카페 상세 → 보고 흐름

---

### 5-4. 접근성 및 다국어

- [ ] **[P1]** 주요 UI 요소에 `Semantics` 라벨 추가 (스크린 리더 지원)
- [ ] **[P2]** 한국어 / 영어 다국어 지원 (`flutter_localizations`, `intl` ARB 파일)

---

### 5-5. 앱 스토어 준비

- [ ] **[P0]** 앱 아이콘 생성 및 적용 (`flutter_launcher_icons`)
- [ ] **[P0]** 스플래시 화면 적용 (`flutter_native_splash`) — Navy 배경
- [ ] **[P0]** Android 릴리즈 서명 설정 (`keystore` 생성, `build.gradle.kts` 서명 설정)
- [ ] **[P0]** iOS 릴리즈 프로비저닝 프로파일 설정 (Xcode)
- [ ] **[P0]** 앱 버전 관리 (`pubspec.yaml` `version` 필드 관리)
- [ ] **[P1]** 개인정보처리방침 페이지 (인앱 또는 외부 URL) — 앱 스토어 제출 필수 항목
- [ ] **[P1]** 이용약관 페이지
- [ ] **[P1]** Google Play Store 스토어 리스팅 준비 (스크린샷 5장 이상, 앱 설명)
- [ ] **[P1]** Apple App Store Connect 리스팅 준비 (스크린샷, 앱 설명, 심사 메모)
- [ ] **[P2]** Android App Bundle (`flutter build appbundle`) 빌드 및 Play Console 업로드
- [ ] **[P2]** iOS IPA (`flutter build ipa`) 빌드 및 TestFlight 업로드

---

### Phase 5 마일스톤 체크리스트

- [ ] `flutter analyze` 경고 0건
- [ ] 유닛 테스트 통과율 80% 이상
- [ ] 릴리즈 빌드 Android APK/AAB 생성 성공 (서명 포함)
- [ ] 릴리즈 빌드 iOS IPA 생성 성공
- [ ] Firebase Crashlytics 대시보드에서 테스트 크래시 수신 확인
- [ ] 두 플랫폼에서 앱 스토어 심사 제출 완료

---

## 권장 폴더 구조 (Feature-based Clean Architecture)

```
lib/
├── main.dart                               # 앱 진입점 (ProviderScope, Firebase init, go_router)
├── firebase_options.dart                   # FlutterFire CLI 생성 파일 (수정 금지)
│
├── core/                                   # 전역 공유 코드
│   ├── constants/
│   │   ├── app_constants.dart              # 앱 전역 상수 (앱명, 버전 등)
│   │   └── firestore_paths.dart            # Firestore 경로 상수
│   ├── errors/
│   │   ├── app_exception.dart              # 커스텀 예외 클래스
│   │   └── failure.dart                    # sealed class Failure
│   ├── router/
│   │   └── app_router.dart                 # go_router 전체 라우트 정의
│   ├── theme/
│   │   ├── app_colors.dart                 # Sophisticated Navy 팔레트 상수
│   │   ├── app_text_styles.dart            # 타이포그래피
│   │   └── app_theme.dart                  # ThemeData 정의
│   └── utils/
│       ├── logger.dart                     # 전역 logger 인스턴스
│       └── location_utils.dart             # 위치 관련 유틸 (거리 계산 등)
│
├── features/                               # 기능별 모듈
│   │
│   ├── auth/                               # 인증
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart         # @freezed
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart    # abstract interface
│   │   ├── providers/
│   │   │   ├── auth_provider.dart          # authProvider (StreamProvider)
│   │   │   └── auth_controller_provider.dart  # @riverpod AsyncNotifier
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── sign_up_screen.dart
│   │       │   └── forgot_password_screen.dart
│   │       └── widgets/
│   │           ├── social_login_button.dart
│   │           └── auth_form_field.dart
│   │
│   ├── map/                                # 지도
│   │   ├── data/
│   │   ├── domain/
│   │   ├── providers/
│   │   │   ├── map_provider.dart           # 현재 위치, 지도 카메라 상태
│   │   │   └── nearby_cafes_provider.dart  # 지도 영역 내 카페 조회
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── map_screen.dart
│   │       └── widgets/
│   │           ├── cafe_bottom_sheet.dart  # 마커 탭 시 표시
│   │           ├── map_controls.dart       # 현재 위치 버튼 등
│   │           └── cafe_marker.dart        # 커스텀 마커
│   │
│   ├── cafe/                               # 카페 목록 & 상세
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── cafe_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── cafe_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── cafe_model.dart         # @freezed
│   │   │   └── repositories/
│   │   │       └── cafe_repository.dart    # abstract interface
│   │   ├── providers/
│   │   │   ├── cafe_list_provider.dart     # @riverpod AsyncNotifier (페이지네이션)
│   │   │   └── cafe_detail_provider.dart   # @riverpod StreamProvider
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── cafe_list_screen.dart
│   │       │   └── cafe_detail_screen.dart
│   │       └── widgets/
│   │           ├── cafe_card.dart
│   │           ├── crowd_badge.dart
│   │           ├── outlet_status_badge.dart
│   │           └── noise_badge.dart
│   │
│   ├── crowd/                              # 혼잡도
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── crowd_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── crowd_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── crowd_log_model.dart    # @freezed
│   │   │   └── repositories/
│   │   │       └── crowd_repository.dart
│   │   ├── providers/
│   │   │   ├── crowd_level_provider.dart   # 실시간 혼잡도 계산
│   │   │   └── crowd_report_controller.dart # @riverpod AsyncNotifier
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── crowd_report_sheet.dart
│   │           └── crowd_history_chart.dart
│   │
│   ├── outlet/                             # 콘센트 가용성
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── outlet_report_model.dart  # @freezed
│   │   ├── providers/
│   │   │   ├── outlet_status_provider.dart
│   │   │   └── outlet_report_controller.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           └── outlet_report_sheet.dart
│   │
│   ├── noise/                              # 소음 수준
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── models/
│   │   │       └── noise_report_model.dart  # @freezed
│   │   ├── providers/
│   │   │   ├── noise_level_provider.dart
│   │   │   └── noise_report_controller.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           └── noise_report_sheet.dart
│   │
│   ├── review/                             # 리뷰
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── review_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── review_model.dart       # @freezed
│   │   │   └── repositories/
│   │   │       └── review_repository.dart
│   │   ├── providers/
│   │   │   ├── review_list_provider.dart
│   │   │   └── review_controller.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── write_review_screen.dart
│   │       └── widgets/
│   │           ├── review_card.dart
│   │           └── star_rating_widget.dart
│   │
│   └── profile/                            # 마이 페이지
│       ├── data/
│       ├── domain/
│       ├── providers/
│       │   └── profile_provider.dart
│       └── presentation/
│           ├── screens/
│           │   ├── profile_screen.dart
│           │   └── edit_profile_screen.dart
│           └── widgets/
│
└── shared/                                 # 피처 간 공유 위젯
    └── widgets/
        ├── primary_button.dart
        ├── secondary_button.dart
        ├── kagong_app_bar.dart
        ├── loading_indicator.dart
        ├── error_view.dart
        └── empty_state_view.dart
```

---

## 기술 결정 사항 요약

| # | 결정 항목 | 선택 | 이유 |
|---|-----------|------|------|
| 1 | 상태 관리 | Riverpod + `@riverpod` 코드 생성 | 컴파일 타임 안전성, 이미 확정 |
| 2 | 라우팅 | `go_router` | 딥링크, Web URL 지원, Flutter 공식 권장 |
| 3 | 데이터 직렬화 | `freezed` + `json_serializable` | 불변 모델, `copyWith`, pattern matching |
| 4 | 이미지 캐싱 | `cached_network_image` | Firebase Storage 이미지 최적화 |
| 5 | 차트 | `fl_chart` | Flutter 네이티브, 가볍고 커스터마이즈 용이 |
| 6 | 혼잡도 집계 알고리즘 | 시간 감쇠 가중 평균 | 최신 보고에 더 높은 신뢰도 부여 |
| 7 | 소셜 로그인 | Google + 카카오 동시 지원 | 한국 사용자 기반 고려, 이미 SDK 설치됨 |
| 8 | 평점 집계 | Cloud Functions Firestore Trigger | 클라이언트 집계 시 보안/동시성 문제 방지 |
| 9 | Firestore 오프라인 | 기본 캐싱 활성화 | `FirebaseFirestore.instance.settings` |
| 10 | 에러 모델 | `sealed class Failure` | 타입 안전 에러 핸들링 |

---

## 미결 질문 (Open Questions)

스테이크홀더 결정이 필요한 항목입니다.

| # | 질문 | 영향 범위 | 결정 필요 시점 |
|---|------|-----------|----------------|
| 1 | **카페 초기 데이터 확보 방법** — 수동 입력 / 카카오맵 API / 크롤링 중 선택 | Phase 2 지도 마커 표시 | Phase 1 완료 전 |
| 2 | **Cloud Functions 사용 범위** — 평점 집계/혼잡도 집계를 Functions으로 처리할 것인지, 클라이언트 트랜잭션으로 대체할 것인지 | Phase 3~4 집계 로직 | Phase 2 완료 전 |
| 3 | **혼잡도 집계 알고리즘 구체화** — 시간 감쇠 파라미터(half-life), 최소 보고 수 기준 결정 | Phase 3 | Phase 3 착수 전 |
| 4 | **Web 플랫폼 대응 시점** — Android/iOS MVP 이후 별도 Phase 6으로 분리 여부 | 전체 일정 | Phase 5 완료 후 |
| 5 | **알림 기능 포함 시점** — 즐겨찾기 카페 혼잡도 변화 FCM 알림 — Phase 4 포함 또는 포스트 런치 | Phase 4 범위 | Phase 3 완료 전 |
| 6 | **관리자 도구** — 카페 등록 승인 / 리뷰 신고 처리를 위한 별도 관리자 화면 필요 여부 | Phase 4 | Phase 4 착수 전 |

---

## 다음 단계 (Next Steps)

**즉시 착수해야 할 작업 (Phase 1 시작):**

1. **Flutter Developer Agent (Flutter):** `pubspec.yaml`에 누락된 의존성 추가 후 `flutter pub get` 실행
2. **Flutter Developer Agent (Flutter):** 위 폴더 구조에 따라 디렉토리 및 빈 파일 일괄 생성
3. **Flutter Developer Agent (Flutter):** `lib/core/theme/` 디자인 시스템 토큰 파일 작성
4. **Flutter Developer Agent (Flutter):** `lib/core/router/app_router.dart` go_router 라우트 정의
5. **Android Specialist Agent:** `android/app/build.gradle.kts` 검증 — minSdk 23, multiDex, manifestPlaceholders
6. **iOS Specialist Agent:** `ios/Podfile` 배포 타겟 및 `ios/Runner/Info.plist` 위치 권한 문자열 추가
7. **Flutter Developer Agent (Flutter):** Freezed 모델 클래스 5종 작성 후 `build_runner` 실행
8. **Flutter Developer Agent (Flutter):** `AuthRepository` 및 로그인/회원가입 화면 UI 구현
9. **PM (Master Planner):** 위 미결 질문 6개에 대한 스테이크홀더 답변 수집 후 본 문서 업데이트
