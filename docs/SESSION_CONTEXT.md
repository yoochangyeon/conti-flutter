# Conti - 세션 컨텍스트

> 마지막 업데이트: 2026-02-05

## 프로젝트 상태

```
Phase: 설계 완료 ✅
Next:  개발 워크플로우 수립 또는 구현 시작
```

## 완료된 작업

### 1. 브레인스토밍 & 요구사항 정의 ✅

- 서비스 비전: 대한민국 예배자 커뮤니티 플랫폼
- MVP 목표: 찬양팀 콘티 협업 도구 + 찬양 데이터베이스
- 타겟 사용자: 찬양팀 멤버, 인도자, 목회자
- 수익 모델: 완전 무료 (기부 기반)

### 2. 시장 조사 ✅

**한국 시장 분석:**
- 콘티메이크: 개인용, 팀 협업 없음
- 예배노트: 악보 제공만, 콘티 기능 없음
- 기존 서비스들 한계: 팀 협업 부재, 커뮤니티 없음

**해외 시장 분석:**
- Planning Center Services: 팀 기능 강력, 한국어/한국 찬양 미지원
- OnStage: 실시간 동기화, 한국 시장 미타겟

**차별점:**
- 팀 단위 협업 중심
- 찬양 데이터베이스화 (사용 이력, 키별, 인도자별)
- 한국 찬양팀 타겟
- 커뮤니티 확장 가능 구조

### 3. 기술 스택 결정 ✅

| 구분 | 기술 |
|------|------|
| 프론트엔드 | React Native 또는 Flutter |
| 백엔드 | Spring Boot (Java) |
| ORM | Spring Data JPA + QueryDSL |
| DB | MySQL (FK 제약조건 없이, JPA 레벨 관리) |
| 인프라 | AWS (EC2 + RDS + S3) |
| 인증 | OAuth2 (카카오, 구글) + JWT |

### 4. 시스템 설계 ✅

**ERD (9개 테이블):**
- users, teams, team_members
- songs, song_tags, song_files, song_usages
- setlists, setlist_items

**REST API (~25개 엔드포인트):**
- Auth: 소셜 로그인, 토큰 관리
- User: 프로필, 팀 목록
- Team: CRUD, 멤버 관리, 초대
- Song: CRUD, 검색/필터, 파일, 태그
- Setlist: CRUD, 아이템 관리

**시스템 아키텍처:**
- 레이어드 아키텍처 (Controller → Service → Repository)
- 도메인별 패키지 구조
- AWS 인프라 (~$32/월 예상)

**인증/권한:**
- JWT (Access 1시간, Refresh 14일)
- 팀 역할: ADMIN, VIEWER, GUEST
- 커스텀 어노테이션 기반 권한 검증

## 생성된 문서

```
/docs/DESIGN.md    - 전체 시스템 설계 문서
/docs/SESSION_CONTEXT.md - 이 파일 (세션 컨텍스트)
```

## 다음 단계

1. **`/sc:workflow`** - 개발 스프린트/태스크 분해
   - MVP 기능별 우선순위
   - 스프린트 계획 (2주 단위 권장)
   - 태스크 분해 및 의존성

2. **`/sc:implement`** - 실제 구현 시작
   - Spring Boot 프로젝트 초기화
   - JPA 엔티티 구현
   - API 개발

## 주요 결정 사항 요약

| 결정 사항 | 선택 | 이유 |
|----------|------|------|
| 백엔드 언어 | Java (Spring Boot) | 취업 목표 (삼성, 네이버, 카카오, 토스, 우형) |
| FK 제약조건 | DB 레벨 X, JPA 레벨만 | 유연한 데이터 관리 |
| ORM | JPA + QueryDSL | 동적 검색 쿼리 필요 |
| 인증 | 소셜 로그인만 | 간편한 가입, 이메일 인증 불필요 |
| 수익모델 | 완전 무료 | 커뮤니티 성장 우선 |

## 열린 질문 (미결정)

1. 프론트엔드 최종 선택: React Native vs Flutter
2. 소셜 로그인 추가: 애플 로그인 필요?
3. 앱 이름/브랜딩 확정
4. AWS 상세 구성 (EC2 vs ECS)

---

*이 파일은 세션 간 컨텍스트 유지를 위해 자동 생성되었습니다.*
