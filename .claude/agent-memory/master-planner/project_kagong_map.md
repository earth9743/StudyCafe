---
name: Kagong Map 프로젝트 핵심 정보
description: 카공지도(Kagong Map) 프로젝트의 플랫폼, 기술 스택, 디자인 시스템, 보안 규칙, 아키텍처 결정 및 현재 진행 상태
type: project
---

## 프로젝트 개요

**앱 이름:** 카공지도 (Kagong Map, kagong_map)
**패키지명:** com.yjh.kagong.kagong_map
**설명:** 카공족(카페에서 공부하는 사람들)을 위한 실시간 카페 정보 공유 플랫폼
**대상 플랫폼:** Android, iOS (Web은 Android/iOS MVP 이후 별도 검토)
**현재 상태 (2026-03-14):** 스캐폴딩 완료 — Firebase, Naver Maps, Kakao, Google Sign-In 설치 및 네이티브 설정 완료. Phase 1 착수 전.

**Why:** 카공족이 카페 방문 전 혼잡도/콘센트/소음 정보를 알 수 없어 헛걸음하는 문제 해결
**How to apply:** 모든 기능 우선순위 결정 시 이 3가지 핵심 데이터(혼잡도, 콘센트, 소음)가 P0임을 기억

## 스캐폴딩 완료 항목 (2026-03-14 기준)

이미 완료된 항목이므로 Phase 1 착수 시 중복 작업 제외:
- Flutter 프로젝트 생성 (com.yjh.kagong.kagong_map)
- Firebase 구성 완료: `firebase_options.dart` 생성, Auth/Firestore/Storage 활성화
- Naver Maps SDK: Android/iOS 네이티브 Client ID 설정
- Kakao Login SDK: `kakao_flutter_sdk_user` 설치, Android/iOS Native Key 설정
- Google Sign-In: `google_sign_in` 패키지 설치
- 핵심 Firebase 패키지: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` 설치
- Email/Password Auth: Firebase Console 활성화

## 기술 스택 (확정)

- **프레임워크:** Flutter (Stable channel)
- **상태 관리:** Riverpod + `@riverpod` 코드 생성 (riverpod_generator) — 추가 설치 필요
- **백엔드:** Firebase — Firestore, Auth, Storage, Cloud Functions (Phase 4에서 검토)
- **지도:** Naver Maps SDK (`flutter_naver_map`)
- **인증:** Email/Password + Google Sign-In + 카카오 로그인
- **데이터 모델:** Freezed + json_serializable — 추가 설치 필요
- **라우팅:** go_router — 추가 설치 필요
- **아키텍처:** Feature-based Clean Architecture

## 디자인 시스템 — Sophisticated Navy

- Primary (Navy): `#19376D` — 앱바, 주요 버튼, 지도 마커
- Secondary (Gray): `#EDEDED` — 디바이더, 카드 배경
- Background: `#FFFFFF`
- Text: `#1A202C`
- 이 팔레트 외 색상은 명시적 승인 없이 추가 불가

## Firestore 컬렉션 구조 (확정)

- `users/{uid}` — 사용자 프로필
- `cafes/{cafeId}` — 카페 기본 정보 (currentCrowdLevel, currentOutletStatus, currentNoiseLevel 필드 포함)
- `cafes/{cafeId}/crowd_logs/{logId}` — 혼잡도 보고
- `cafes/{cafeId}/outlet_reports/{reportId}` — 콘센트 가용성 보고
- `cafes/{cafeId}/noise_reports/{reportId}` — 소음 수준 보고
- `cafes/{cafeId}/reviews/{reviewId}` — 사용자 리뷰
- `cafe_requests/{requestId}` — 카페 등록 신청

## 보안 불변 규칙

- Naver Client ID는 어떠한 소스 파일에도 하드코딩 절대 금지
- Android: `local.properties` → `build.gradle` manifestPlaceholders로 주입
- Firebase 설정 파일 (`google-services.json`, `GoogleService-Info.plist`) .gitignore 관리

## 핵심 아키텍처 결정

- Android minSdkVersion: 23 이상 (Naver Maps SDK 요구사항)
- iOS 배포 타겟: 13.0 이상
- Android multiDexEnabled: true 필수
- Provider 패턴: Stream → StreamProvider, 단발성 → FutureProvider, 액션 → AsyncNotifierProvider
- 혼잡도 집계: 시간 감쇠 가중 평균 (최신 보고에 높은 가중치)
- 중복 보고 방지: 동일 사용자 30분 내 재보고 거부
- 평점 집계: Cloud Functions Firestore Trigger 권장 (Phase 4에서 확정)

## 페이즈 상태

| Phase | 이름 | 상태 | 예상 소요 |
|-------|------|------|-----------|
| Phase 1 | 아키텍처 확립 & 인증 | 미시작 | 3~4주 |
| Phase 2 | 핵심 UI & 지도 통합 | 미시작 | 4~5주 |
| Phase 3 | 실시간 데이터 기능 | 미시작 | 3~4주 |
| Phase 4 | 리뷰 & 소셜 기능 | 미시작 | 3~4주 |
| Phase 5 | 출시 준비 & 품질 관리 | 미시작 | 2~3주 |

## 미결 질문 (스테이크홀더 결정 필요)

1. 카페 초기 데이터 확보 방법 (수동/카카오맵 API/크롤링) — Phase 1 완료 전 결정 필요
2. Cloud Functions 사용 범위 (평점/혼잡도 집계) — Phase 2 완료 전 결정 필요
3. 혼잡도 집계 알고리즘 파라미터 구체화 — Phase 3 착수 전 결정 필요
4. Web 플랫폼 대응 시점 — Phase 5 완료 후 검토
5. FCM 알림 기능 포함 시점 — Phase 3 완료 전 결정 필요
6. 관리자 도구 필요 여부 — Phase 4 착수 전 결정 필요
