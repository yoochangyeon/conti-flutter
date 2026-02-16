# Conti Flutter - 세션 컨텍스트

> 마지막 업데이트: 2026-02-16

## 프로젝트 상태

```
Phase: Phase 2 핵심 확장 거의 완료 🔶
Next:  소셜 로그인 SDK 연동 (Step 1) → FCM 실 연동 (Step 5) → 배포 (Step 8)
```

## 현재 구현 현황

### Flutter 앱 — 핵심 기능 구현 완료

| 영역 | 구현 현황 |
|------|----------|
| **화면 수** | 29개 스크린 |
| **모델** | 9개 모델 클래스 |
| **프로바이더** | 8개 Riverpod 프로바이더 파일 |
| **라우트** | 31개 라우트 (중첩 라우팅) |
| **위젯** | 8개 공통 위젯 |
| **코드량** | ~12,400 LOC (65개 Dart 파일) |

### 구현된 화면

| 기능 | 화면 | 상태 |
|------|------|:----:|
| 인증 | 로그인, 스플래시 | Done |
| 홈 | 팀 목록, 팀 생성/가입 | Done |
| 프로필 | 프로필 편집 | Done |
| 알림 | 알림 목록, 알림 설정 | Done |
| 팀 | 팀 상세, 멤버 목록, 포지션 편집, 공지사항 | Done |
| 찬양 | 목록(검색/필터), 상세(4탭: 정보/곡구조/편곡/통계), 생성/편집, 섹션 에디터, 곡 구조(트랜스포즈), 편곡 CRUD, 통계, 파일 관리, 사용이력, 태그 자동완성 | Done |
| 콘티 | 목록(필터), 상세(복사/색상/서비스구간), 생성/편집, 템플릿(생성/수정/삭제), 노트 | Done |
| 스케줄 | 배정 보드, 배정 화면, 내 스케줄, 불참일 관리, 매트릭스 뷰 | Done |

### 미구현 사항

| 항목 | 상태 |
|------|------|
| Flutter 소셜 로그인 SDK 연동 | 백엔드 완료, Flutter 카카오/구글 SDK 미연동 (Dev Login만) |
| FCM 실제 푸시 발송 | 백엔드 Mock, Flutter firebase_messaging 미연동 |
| 오프라인 모드 | Phase 3 |
| 앱스토어 배포 | 미착수 |

## 최근 작업 이력

### 2026-02-16: Flutter 미연결 API 전체 구현
백엔드에 이미 존재하던 API 중 Flutter에서 미연결된 6개 항목 모두 구현:
1. **편곡 CRUD** — `arrangement_form_screen.dart` 신규, 편곡탭 인터랙션 추가
2. **악보 파일 관리** — 파일 삭제 버튼 + URL 추가 다이얼로그
3. **곡 사용 이력** — 정보 탭 하단 `_UsageHistorySection`
4. **곡 개별 통계** — 4번째 탭 `_StatsTab` (BarChart/PieChart/인도자별)
5. **태그 자동완성** — `_TagSuggestions` 위젯 (ActionChip)
6. **템플릿 수정** — PopupMenuButton (수정/삭제), `_showEditDialog`

### 2026-02-16: 곡 통계 차트 구현
- `song_stats_screen.dart`에 fl_chart 기반 BarChart, PieChart 추가
- 팀 전체 곡 사용 통계 시각화

## 주요 기술 결정 사항

| 결정 | 선택 | 이유 |
|------|------|------|
| 프론트엔드 | Flutter | iOS/Android/Web 크로스플랫폼 |
| 상태관리 | Riverpod | FutureProvider.family 패턴 |
| 라우팅 | GoRouter | 중첩 라우팅, 인증 가드 |
| HTTP | Dio | 자동 토큰 갱신 인터셉터 |
| 차트 | fl_chart | BarChart, PieChart |
| 웹 SecureStorage | localStorage | conditional import |

---

*이 파일은 세션 간 컨텍스트 유지를 위해 작성되었습니다.*
