# 카공지도 관리자 앱 (kagong_map_admin) 구축 플랜

## 개요

기존 카공지도(kagong_map) 앱과 **동일한 Firebase 프로젝트(kagong-map)**를 공유하면서, 별도 Git 레포(`earth9743/kagong_map_admin`)로 관리하는 **Flutter 관리자 앱**을 생성합니다.

- **디자인 시스템**: "Sophisticated Navy" 팔레트 동일 적용
- **아키텍처**: Feature-based Clean Architecture + Riverpod (기존 앱과 동일 패턴)
- **에이전트**: 기존 6개 에이전트 설정 이관 (경로만 변경)

---

## Phase 1: 프로젝트 초기 설정

### 1-1. Flutter 프로젝트 생성
```bash
cd /Users/jeonghyunyoo/Documents/Project
flutter create --org com.yjh.kagong kagong_map_admin
cd kagong_map_admin
```
- 패키지명: `com.yjh.kagong.kagongMapAdmin`
- Android minSdkVersion: 23
- iOS deployment target: 13.0

### 1-2. Git 초기화 및 원격 레포 연결
```bash
git init
git remote add origin git@github.com:earth9743/kagong_map_admin.git
git branch -M main
```

### 1-3. 핵심 의존성 설치 (pubspec.yaml)
기존 앱에서 관리자 앱에 필요한 패키지만 선별:

| 패키지 | 용도 |
|--------|------|
| flutter_riverpod | 상태 관리 |
| go_router | 네비게이션 |
| firebase_core | Firebase 코어 |
| firebase_auth | 인증 (관리자 로그인) |
| cloud_firestore | DB CRUD |
| firebase_storage | 이미지 업로드 (배너/광고) |
| cached_network_image | 이미지 캐싱 |
| image_picker | 배너/광고 이미지 선택 |
| fl_chart | 대시보드 통계 차트 |
| intl | 날짜/숫자 포맷 |
| equatable | 모델 비교 |
| flutter_svg | SVG 아이콘 |

**제외 패키지** (관리자 앱에 불필요):
- flutter_naver_map (지도 불필요)
- geolocator (위치 불필요)
- kakao_flutter_sdk_user (카카오 로그인 불필요)
- google_sign_in (관리자는 이메일/비밀번호 로그인)

### 1-4. Firebase 연동
- 기존 Firebase 프로젝트(`kagong-map`)에 새 앱 등록
- `flutterfire configure`로 `firebase_options.dart` 생성
- Android: `google-services.json` 추가
- iOS: `GoogleService-Info.plist` 추가

---

## Phase 2: 디자인 시스템 & 코어 이관

### 2-1. 디자인 시스템 파일 복사 (동일 팔레트)
기존 앱의 3개 파일을 그대로 이관:
- `lib/core/theme/app_colors.dart` → 동일
- `lib/core/theme/app_text_styles.dart` → 동일
- `lib/core/theme/app_theme.dart` → AppBar 등 관리자용으로 미세 조정

### 2-2. 코어 유틸리티
- `lib/core/constants/app_constants.dart` → 관리자 앱용 상수
- `lib/core/constants/firestore_paths.dart` → 기존과 동일 (같은 Firestore)
- `lib/core/router/app_router.dart` → 관리자 앱 라우트

---

## Phase 3: 관리자 인증 시스템

### 3-1. 이메일/비밀번호 기반 관리자 로그인
- 소셜 로그인 없음 — Firebase Auth 이메일/비밀번호만 사용
- Firestore `users` 컬렉션에서 `role: 'admin'` 필드 확인
- 관리자가 아닌 계정으로 로그인 시 접근 거부

### 3-2. Firestore 보안 규칙 (기존 프로젝트에 추가)
```
// admin 역할 체크 규칙
function isAdmin() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

### 3-3. 라우트 구조
```
/login          → 관리자 로그인
/               → 대시보드 (홈)
/users          → 회원 관리
/users/:id      → 회원 상세
/cafes          → 카페 관리
/cafes/:id      → 카페 상세
/banners        → 배너 관리
/banners/create → 배너 생성
/ads            → 광고 관리
/ads/create     → 광고 생성
/settings       → 관리자 설정
```

---

## Phase 4: 핵심 기능 구현

### 4-1. 대시보드 (홈 화면)
- 총 회원 수, 등록 카페 수, 오늘의 활성 사용자
- 최근 7일 가입자 추이 차트 (fl_chart)
- 최근 신고/리뷰 목록

### 4-2. 회원 관리
- **회원 목록**: 검색, 필터(가입일, 상태), 페이지네이션
- **회원 상세**: 프로필, 리뷰 기록, 북마크 카페
- **회원 추가**: 이메일/비밀번호로 새 계정 생성 (Firebase Admin)
- **회원 삭제**: Firestore 문서 삭제 + 비활성화 처리
- **역할 변경**: 일반 사용자 ↔ 관리자 전환

### 4-3. 카페 관리
- **카페 목록**: 검색, 필터(인증 상태, 지역)
- **카페 상세/수정**: 정보 편집, 사진 관리
- **카페 인증 승인**: `isVerified` 토글
- **카페 삭제**: 비활성화 처리

### 4-4. 배너 관리
- **배너 목록**: 활성/비활성 필터
- **배너 생성**: 이미지 업로드 (Firebase Storage), 링크 URL, 노출 기간 설정
- **배너 수정/삭제**
- Firestore 컬렉션: `banners/{bannerId}`

### 4-5. 광고 관리
- **광고 카페 목록**: 광고 진행 중인 카페
- **광고 생성**: 카페 선택 → 광고 기간/타입 설정 → 이미지 업로드
- **광고 수정/삭제**
- Firestore 컬렉션: `ads/{adId}`

---

## Phase 5: 에이전트 & Claude 설정 이관

### 5-1. .claude/ 디렉토리 구조
```
kagong_map_admin/.claude/
├── CLAUDE.md              → 관리자 앱 전용 지침 (내용 수정)
├── settings.local.json    → Bash 권한 설정 (경로 변경)
└── agents/
    ├── master-planner.md
    ├── ui-design-system-engineer.md
    ├── tpm-task-dispatcher.md
    ├── devops-sre-engineer.md
    ├── android-kotlin-architect.md
    └── ios-swift-architect.md
```

### 5-2. CLAUDE.md 수정사항
- 프로젝트명: "Kagong Map Admin" (카공지도 관리자)
- Naver Maps SDK 관련 지침 제거
- 관리자 앱 전용 기능 목록 추가
- 동일 디자인 시스템 명시

### 5-3. 에이전트 파일 수정사항
- 메모리 경로만 변경: `StudyCafe` → `kagong_map_admin`
- 나머지 역할/지침은 동일 유지

---

## Phase 6: 프로젝트 디렉토리 구조

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── firestore_paths.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_theme.dart
└── features/
    ├── auth/
    │   ├── domain/
    │   │   ├── models/admin_user_model.dart
    │   │   └── repositories/admin_auth_repository.dart
    │   ├── data/
    │   │   └── repositories/admin_auth_repository_impl.dart
    │   ├── presentation/
    │   │   └── screens/admin_login_screen.dart
    │   └── providers/admin_auth_provider.dart
    ├── dashboard/
    │   ├── presentation/
    │   │   ├── screens/dashboard_screen.dart
    │   │   └── widgets/
    │   │       ├── stat_card.dart
    │   │       ├── recent_activity_list.dart
    │   │       └── user_chart.dart
    │   └── providers/dashboard_provider.dart
    ├── users/
    │   ├── domain/
    │   │   ├── models/user_model.dart
    │   │   └── repositories/user_management_repository.dart
    │   ├── data/
    │   │   └── repositories/user_management_repository_impl.dart
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── user_list_screen.dart
    │   │   │   └── user_detail_screen.dart
    │   │   └── widgets/
    │   │       ├── user_list_tile.dart
    │   │       └── user_search_bar.dart
    │   └── providers/user_management_provider.dart
    ├── cafes/
    │   ├── domain/
    │   │   ├── models/cafe_model.dart
    │   │   └── repositories/cafe_management_repository.dart
    │   ├── data/
    │   │   └── repositories/cafe_management_repository_impl.dart
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── cafe_list_screen.dart
    │   │   │   └── cafe_detail_screen.dart
    │   │   └── widgets/
    │   │       └── cafe_list_tile.dart
    │   └── providers/cafe_management_provider.dart
    ├── banners/
    │   ├── domain/
    │   │   ├── models/banner_model.dart
    │   │   └── repositories/banner_repository.dart
    │   ├── data/
    │   │   └── repositories/banner_repository_impl.dart
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── banner_list_screen.dart
    │   │   │   └── banner_create_screen.dart
    │   │   └── widgets/
    │   │       └── banner_card.dart
    │   └── providers/banner_provider.dart
    ├── ads/
    │   ├── domain/
    │   │   ├── models/ad_model.dart
    │   │   └── repositories/ad_repository.dart
    │   ├── data/
    │   │   └── repositories/ad_repository_impl.dart
    │   ├── presentation/
    │   │   ├── screens/
    │   │   │   ├── ad_list_screen.dart
    │   │   │   └── ad_create_screen.dart
    │   │   └── widgets/
    │   │       └── ad_card.dart
    │   └── providers/ad_provider.dart
    └── shared/
        └── widgets/
            ├── admin_drawer.dart
            ├── search_bar.dart
            ├── confirm_dialog.dart
            └── image_upload_widget.dart
```

---

## 실행 순서 요약

| 단계 | 작업 | 예상 산출물 |
|------|------|------------|
| 1 | Flutter 프로젝트 생성 + Git 연결 | 빈 프로젝트 + 원격 레포 |
| 2 | 의존성 설치 + Firebase 연동 | pubspec.yaml + firebase_options.dart |
| 3 | 디자인 시스템 & 코어 이관 | core/ 디렉토리 |
| 4 | 관리자 인증 구현 | 로그인 화면 + 역할 체크 |
| 5 | 대시보드 화면 | 통계 카드 + 차트 |
| 6 | 회원 관리 CRUD | 목록/상세/추가/삭제 |
| 7 | 카페 관리 CRUD | 목록/상세/수정/삭제 |
| 8 | 배너 관리 | 생성/수정/삭제 + 이미지 업로드 |
| 9 | 광고 관리 | 생성/수정/삭제 |
| 10 | 에이전트 설정 이관 | .claude/ 디렉토리 |
| 11 | 초기 커밋 + 푸시 | Git main 브랜치 |
