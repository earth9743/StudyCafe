# 카공지도 (Kagong Map) — 진행 상황 트래커

> **최종 업데이트:** 2026-03-13
> 이 문서는 살아있는 문서(Living Document)입니다. 각 Phase 진행에 따라 지속적으로 업데이트하세요.

---

## 전체 진행 현황

| Phase | 이름 | 상태 | 완료율 |
|-------|------|------|--------|
| Phase 1 | 기반 구축 | 미시작 | 0% |
| Phase 2 | 핵심 UI 및 지도 통합 | 대기 중 | 0% |
| Phase 3 | 실시간 데이터 기능 | 대기 중 | 0% |
| Phase 4 | 리뷰 & 소셜 기능 | 대기 중 | 0% |
| Phase 5 | 출시 준비 및 품질 | 대기 중 | 0% |

---

## Phase 1: 기반 구축 — 진행 상황

**상태:** 미시작
**시작일:** —
**목표 완료일:** —

### 완료된 항목
_없음_

### 진행 중인 항목
_없음_

### 블로커 / 이슈
_없음_

### 미결 결정 사항
- [ ] Firebase 프로젝트 생성 전 앱 Bundle ID / Package Name 확정 필요
- [ ] Naver Maps API 키 발급 (Naver Cloud Console)
- [ ] 카카오 로그인 포함 여부 결정

---

## Phase 2: 핵심 UI 및 지도 통합 — 진행 상황

**상태:** Phase 1 완료 대기 중

---

## Phase 3: 실시간 데이터 기능 — 진행 상황

**상태:** Phase 2 완료 대기 중

---

## Phase 4: 리뷰 & 소셜 기능 — 진행 상황

**상태:** Phase 3 완료 대기 중

---

## Phase 5: 출시 준비 및 품질 — 진행 상황

**상태:** Phase 4 완료 대기 중

---

## 알려진 기술 부채 (Technical Debt)

_현재 없음. Phase 진행에 따라 발견된 항목을 여기에 기록하세요._

---

## 주요 결정 로그 (Decision Log)

| 날짜 | 결정 사항 | 이유 |
|------|-----------|------|
| 2026-03-13 | 상태 관리: Riverpod + @riverpod 코드 생성 | 컴파일 타임 안전성, 표준화 |
| 2026-03-13 | 지도: Naver Maps SDK (flutter_naver_map) | 한국 서비스 특화, 국내 POI 정확도 |
| 2026-03-13 | 데이터베이스: Firebase Firestore | 실시간 스트림, 서버리스 운영 |
| 2026-03-13 | 아키텍처: Feature-based Clean Architecture | 확장성, 팀 협업, 테스트 용이성 |
| 2026-03-13 | 라우팅: go_router | Flutter 공식 권장, 딥링크 지원 |
| 2026-03-13 | 모델: freezed + json_serializable | 불변 모델, copyWith 지원 |
